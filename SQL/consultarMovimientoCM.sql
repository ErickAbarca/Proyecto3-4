ALTER PROCEDURE [dbo].[SP_ConsultarMovimientosPorCuentaMaestra]
    @id_tcm INT,
    @fecha_inicio DATETIME,
    @fecha_fin DATETIME,
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        SELECT m.*
        FROM dbo.Movimiento m
        INNER JOIN dbo.TarjetaFisica tf ON m.id_tf = tf.id
        WHERE tf.id_tcm = @id_tcm
          AND m.fecha_movimiento BETWEEN @fecha_inicio AND @fecha_fin;

    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
        SET @OutResulTCode = 50006;
    END CATCH;
    SET NOCOUNT OFF;
END;
GO
    