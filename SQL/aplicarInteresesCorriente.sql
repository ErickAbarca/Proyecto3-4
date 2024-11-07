ALTER PROCEDURE [dbo].[SP_AplicarInteresCorriente]
    @id_tcm INT,
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        DECLARE @monto_interes DECIMAL(18,2);

        SET @monto_interes = 4;  -- Cálculo de interés

        INSERT INTO dbo.InteresCorriente (id_tcm, fecha_operacion, monto_interes)
        VALUES (@id_tcm, GETDATE(), @monto_interes);

    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
        SET @OutResulTCode = 50008;
    END CATCH;
    SET NOCOUNT OFF;
END;
GO
