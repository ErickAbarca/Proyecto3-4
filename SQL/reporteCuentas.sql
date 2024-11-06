ALTER PROCEDURE [dbo].[SP_ReporteCuentasActivasPorTipo]
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Reporte de cuentas activas por tipo de cuenta maestra
        SELECT tc.nombre_tipo_tcm AS TipoCuenta, COUNT(ctm.id) AS TotalActivas
        FROM CuentaTarjetaMaestra ctm
        JOIN TipoCuentaMaestra tc ON ctm.tipo_tcm = tc.id
        WHERE ctm.saldo_actual > 0
        GROUP BY tc.nombre_tipo_tcm;

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
