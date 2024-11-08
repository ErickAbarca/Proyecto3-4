CREATE PROCEDURE [dbo].[SP_InactivarTarjetaFisica]
    @id_tf INT,  -- ID de la tarjeta física
    @motivo_invalidacion INT,  -- Motivo de invalidación (e.g., robo, pérdida)
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Validación: Verificar que la tarjeta física exista y esté activa
        IF NOT EXISTS (SELECT 1 FROM dbo.TarjetaFisica WHERE id = @id_tf AND estado = 'Activa')
        BEGIN
            SET @OutResulTCode = 50017;  -- Código de error para tarjeta inexistente o ya inactiva
            RETURN;
        END

        -- Validación: Verificar que el motivo de invalidación exista
        IF NOT EXISTS (SELECT 1 FROM dbo.MotivoInvalidacionTarjeta WHERE id = @motivo_invalidacion)
        BEGIN
            SET @OutResulTCode = 50018;  -- Código de error para motivo de invalidación no encontrado
            RETURN;
        END

        -- Comienza la transacción
        BEGIN TRANSACTION;

        -- Actualizar el estado de la tarjeta a "Inactiva"
        UPDATE dbo.TarjetaFisica
        SET estado = 'Inactiva'
        WHERE id = @id_tf;

        -- Registrar el motivo de la inactivación (opcional si se tiene una tabla para esto)
        -- INSERT INTO dbo.TarjetaInactivada (id_tf, motivo_invalidacion, fecha)
        -- VALUES (@id_tf, @motivo_invalidacion, GETDATE());

        -- Confirmar la transacción
        COMMIT TRANSACTION;

        -- Código de salida en caso de éxito
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
