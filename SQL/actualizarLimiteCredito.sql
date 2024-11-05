ALTER PROCEDURE [dbo].[SP_ActualizarLimiteCredito]
    @id_tcm INT,
    @nuevo_limite DECIMAL(18,2),
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Validación: Verificar que la cuenta maestra exista
        IF NOT EXISTS (SELECT 1 FROM CuentaTarjetaMaestra WHERE id = @id_tcm)
        BEGIN
            SET @OutResulTCode = 50013;  -- Código de error para cuenta no encontrada
            RETURN;
        END

        -- Comienza la transacción
        BEGIN TRANSACTION;

        -- Actualización del límite de crédito
        UPDATE CuentaTarjetaMaestra
        SET limite_credito = @nuevo_limite
        WHERE id = @id_tcm;

        -- Confirmar la transacción
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Manejo de errores
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        INSERT INTO DBErrors VALUES (
            SUSER_SNAME(), 
            ERROR_NUMBER(), 
            ERROR_STATE(), 
            ERROR_SEVERITY(), 
            ERROR_LINE(), 
            ERROR_PROCEDURE(), 
            ERROR_MESSAGE(), 
            GETDATE());

        SET @OutResulTCode = 50008;
    END CATCH;
END;
GO
