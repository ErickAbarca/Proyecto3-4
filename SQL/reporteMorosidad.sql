CREATE PROCEDURE [dbo].[SP_ReporteMorosidadPorCuenta]
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Reporte de cuentas con intereses moratorios acumulados
        SELECT ctm.id AS CuentaID, th.nombre AS Tarjetahabiente, SUM(im.monto_interes) AS TotalMorosidad
        FROM CuentaTarjetaMaestra ctm
        JOIN Tarjetahabiente th ON ctm.id_th = th.id
        JOIN InteresMoratorio im ON im.id_tcm = ctm.id
        GROUP BY ctm.id, th.nombre
        HAVING SUM(im.monto_interes) > 0;

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
