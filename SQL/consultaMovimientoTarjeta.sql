ALTER PROCEDURE [dbo].[SP_ConsultaMovimientosPorTarjeta]
    @id_tf INT,
    @fecha_inicio DATETIME,
    @fecha_fin DATETIME,
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        SELECT * FROM dbo.Movimiento
        WHERE id_tf = @id_tf
          AND fecha_movimiento BETWEEN @fecha_inicio AND @fecha_fin;

    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors VALUES (
            SUSER_SNAME(), 
            ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
        SET @OutResulTCode = 50005;
    END CATCH;
    SET NOCOUNT OFF;
END;
GO
