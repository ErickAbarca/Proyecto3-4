CREATE PROCEDURE [dbo].[SP_CrearCuentaTarjetaAdicional]
    @codigo_tca VARCHAR(32),
    @id_tcm INT,  -- ID de la cuenta maestra asociada
    @id_th INT,   -- ID del tarjetahabiente que usará la cuenta adicional
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Validación: Verificar si el código de la cuenta adicional ya existe
        IF EXISTS (SELECT 1 FROM dbo.CuentaTarjetaAdicional WHERE codigo_tca = @codigo_tca)
        BEGIN
            SET @OutResulTCode = 50012;  -- Código de error para código de cuenta adicional duplicado
            RETURN;
        END

        -- Validación: Verificar que la cuenta maestra exista
        IF NOT EXISTS (SELECT 1 FROM dbo.CuentaTarjetaMaestra WHERE id = @id_tcm)
        BEGIN
            SET @OutResulTCode = 50013;  -- Código de error para cuenta maestra no encontrada
            RETURN;
        END

        -- Validación: Verificar que el tarjetahabiente exista
        IF NOT EXISTS (SELECT 1 FROM dbo.Tarjetahabiente WHERE id = @id_th)
        BEGIN
            SET @OutResulTCode = 50009;  -- Código de error para tarjetahabiente no encontrado
            RETURN;
        END

        -- Comienza la transacción
        BEGIN TRANSACTION;

        -- Inserción de la nueva cuenta de tarjeta adicional
        INSERT INTO dbo.CuentaTarjetaAdicional (
            codigo_tca,
            id_tcm,
            id_th
        ) VALUES (
            @codigo_tca,
            @id_tcm,
            @id_th
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
