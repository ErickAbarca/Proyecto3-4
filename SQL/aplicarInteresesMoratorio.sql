CREATE PROCEDURE [dbo].[SP_AplicarInteresMoratorio]
    @id_tcm INT,
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        DECLARE @monto_interes_mora DECIMAL(18,2);
        SET @monto_interes_mora = 6;  -- Cálculo del interés moratorio

        INSERT INTO dbo.InteresMoratorio (id_tcm, fecha_operacion, monto_interes)
        VALUES (@id_tcm, GETDATE(), @monto_interes_mora);

    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
        SET @OutResulTCode = 50009;
    END CATCH;
    SET NOCOUNT OFF;
END;
GO
