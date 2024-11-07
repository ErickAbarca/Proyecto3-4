ALTER PROCEDURE [dbo].[SP_ConsultaTarjetahabientes]
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        SELECT * FROM dbo.Tarjetahabiente;

    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
        SET @OutResulTCode = 50013;
    END CATCH;
    SET NOCOUNT OFF;
END;
GO
