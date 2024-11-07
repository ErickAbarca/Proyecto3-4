ALTER PROCEDURE [dbo].[SP_GenerarMultaExcesoOperaciones]
    @id_tcm INT,
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        DECLARE @multa DECIMAL(18,2);
        SET @multa = 3000;  -- Definir monto de la multa

        UPDATE dbo.CuentaTarjetaMaestra
        SET saldo_actual = saldo_actual + @multa
        WHERE id = @id_tcm;

    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
        SET @OutResulTCode = 50010;
    END CATCH;
    SET NOCOUNT OFF;
END;
GO
