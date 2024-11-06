ALTER PROCEDURE [dbo].[SP_ConsultarSaldosTarjetas]
    @id_th INT,
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Consulta de saldos de cuentas maestras y adicionales asociadas al tarjetahabiente
        SELECT tf.numero_tarjeta, ctm.saldo_actual, 
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
            SGETDATE());

        SET @OutResulTCode = 50008;
    END CATCH;
END;
GO
