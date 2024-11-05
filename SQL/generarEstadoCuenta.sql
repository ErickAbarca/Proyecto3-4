ALTER PROCEDURE [dbo].[SP_GenerarEstadoCuenta]
    @id_tcm INT,  -- ID de la cuenta maestra
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @saldo_actual DECIMAL(18,2);
    DECLARE @intereses_corrientes DECIMAL(18,2) = 0;
    DECLARE @intereses_moratorios DECIMAL(18,2) = 0;
    DECLARE @pago_minimo DECIMAL(18,2);
    DECLARE @pago_contado DECIMAL(18,2);

    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Obtener saldo actual de la cuenta
        SELECT @saldo_actual = saldo_actual
        FROM dbo.CuentaTarjetaMaestra
        WHERE id = @id_tcm;

        -- Validación: Verificar si la cuenta existe
        IF @saldo_actual IS NULL
        BEGIN
            SET @OutResulTCode = 50013;  -- Error: Cuenta maestra no encontrada
            RETURN;
        END

        -- Calcular intereses corrientes y moratorios acumulados (asume cálculos previos)
        SELECT @intereses_corrientes = ISNULL(SUM(monto_interes), 0)
        FROM dbo.InteresCorriente
        WHERE id_tcm = @id_tcm;

        SELECT @intereses_moratorios = ISNULL(SUM(monto_interes), 0)
        FROM dbo.InteresMoratorio
        WHERE id_tcm = @id_tcm;

        -- Calcular pago mínimo (e.g., 5% del saldo actual + intereses acumulados)
        SET @pago_minimo = @saldo_actual * 0.05 + @intereses_corrientes + @intereses_moratorios;
        SET @pago_contado = @saldo_actual + @intereses_corrientes + @intereses_moratorios;

        -- Comienza la transacción
        BEGIN TRANSACTION;

        -- Insertar el estado de cuenta
        INSERT INTO dbo.EstadoCuenta (
            id_tcm,
            fecha_corte,
            saldo_actual,
            pago_minimo,
            pago_contado,
            intereses_corrientes,
            intereses_moratorios
        ) VALUES (
            @id_tcm,
            GETDATE(),
            @saldo_actual,
            @pago_minimo,
            @pago_contado,
            @intereses_corrientes,
            @intereses_moratorios
        );

        -- Confirmar la transacción
        COMMIT TRANSACTION;

        SET @OutResulTCode = 0;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        INSERT INTO dbo.DBErrors VALUES (
            SUSER_SNAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );

        SET @OutResulTCode = 50008;
    END CATCH;

    SET NOCOUNT OFF;
END;
GO
