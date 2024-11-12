ALTER PROCEDURE [dbo].[SP_ConsultarTarjetasPorTarjetahabiente]
    @documentoIdentidad NVARCHAR(20),
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @idTarjetahabiente INT;
        SET @idTarjetahabiente = (SELECT id
                              FROM Tarjetahabiente 
                              WHERE documento_identidad = @documentoIdentidad);
        SET @OutResulTCode = 0;

        -- Consulta de tarjetas físicas asociadas al tarjetahabiente
        SELECT tf.numero_tarjeta, tf.estado, tf.fecha_vencimiento, 
               CASE WHEN tf.id_tcm IS NOT NULL THEN 'TCM' ELSE 'TCA' END AS tipo_cuenta
        FROM TarjetaFisica tf
        LEFT JOIN CuentaTarjetaMaestra ctm ON tf.id_tcm = ctm.id
        LEFT JOIN CuentaTarjetaAdicional tca ON tf.id_tca = tca.id
        WHERE (ctm.id_th = @id_th OR tca.id_th = @id_th);

    END TRY
    BEGIN CATCH
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
