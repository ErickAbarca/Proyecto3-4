CREATE PROCEDURE [dbo].[SP_CrearCuentaTarjetaMaestra]
    @codigo_tcm VARCHAR(32),
    @tipo_tcm INT,  -- Referencia a TipoCuentaMaestra
    @limite_credito DECIMAL(18,2),
    @id_th INT,  -- Tarjetahabiente al que se asocia la cuenta
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Validación: Verificar si el código de la cuenta maestra ya existe
        IF EXISTS (SELECT 1 FROM dbo.CuentaTarjetaMaestra WHERE codigo_tcm = @codigo_tcm)
        BEGIN
            SET @OutResulTCode = 50007;  -- Código de error para código de cuenta duplicado
            RETURN;
        END

        -- Validación: Verificar que el tarjetahabiente exista
        IF NOT EXISTS (SELECT 1 FROM dbo.Tarjetahabiente WHERE id = @id_th)
        BEGIN
            SET @OutResulTCode = 50009;  -- Código de error para tarjetahabiente no encontrado
            RETURN;
        END

        -- Validación: Verificar que el tipo de cuenta maestra exista
        IF NOT EXISTS (SELECT 1 FROM dbo.TipoCuentaMaestra WHERE id = @tipo_tcm)
        BEGIN
            SET @OutResulTCode = 50010;  -- Código de error para tipo de cuenta maestra no encontrado
            RETURN;
        END

        -- Comienza la transacción
        BEGIN TRANSACTION;

        -- Inserción de la nueva cuenta de tarjeta maestra
        INSERT INTO dbo.CuentaTarjetaMaestra (
            codigo_tcm,
            tipo_tcm,
            limite_credito,
            saldo_actual,
            id_th,
            fecha_creacion
        ) VALUES (
            @codigo_tcm,
            @tipo_tcm,
            @limite_credito,
            0,  -- Saldo inicial en cero
            @id_th,
            GETDATE()
        );

        -- Confirmar la transacción
        COMMIT TRANSACTION;

        -- Código de salida en caso de éxito
        SET @OutResulTCode = 0;

    END TRY
    BEGIN CATCH
        -- Manejo de errores
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        -- Registrar error en tabla de errores
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

        -- Código de error estándar
        SET @OutResulTCode = 50008;
    END CATCH;

    SET NOCOUNT OFF;
END;
GO
