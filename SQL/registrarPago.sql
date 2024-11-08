CREATE PROCEDURE [dbo].[SP_RegistrarPago]
    @id_tcm INT,  -- ID de la cuenta maestra
    @monto DECIMAL(18,2),
    @descripcion VARCHAR(256),
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @saldo_actual DECIMAL(18,2);

    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Obtener el saldo actual de la cuenta maestra
        SELECT @saldo_actual = saldo_actual
        FROM dbo.CuentaTarjetaMaestra
        WHERE id = @id_tcm;

        -- Validación: Verificar que la cuenta maestra existe
        IF @saldo_actual IS NULL
        BEGIN
            SET @OutResulTCode = 50013;  -- Código de error para cuenta no encontrada
            RETURN;
        END

        -- Comienza la transacción
        BEGIN TRANSACTION;

        -- Actualizar saldo de la cuenta maestra
        UPDATE dbo.CuentaTarjetaMaestra
        SET saldo_actual = saldo_actual - @monto
        WHERE id = @id_tcm;

        -- Registrar el pago como movimiento
        INSERT INTO dbo.Movimiento (
            id_tf,
            fecha_movimiento,
            tipo_movimiento,
            monto,
            descripcion,
            referencia
        ) VALUES (
            NULL,  -- Se asume que es pago directo a la cuenta maestra
            GETDATE(),
            1,  -- Supone que "1" es el tipo de movimiento para "Pago"
            @monto,
            @descripcion,
            NULL
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
