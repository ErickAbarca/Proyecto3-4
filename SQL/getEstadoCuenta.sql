CREATE PROCEDURE SP_ObtenerEstadoCuenta
    @id_cuenta INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
            id_tcm,
            fecha_corte,
            saldo_actual,
            pago_minimo,
            pago_contado,
            intereses_corrientes,
            intereses_moratorios
        FROM dbo.EstadoCuenta
        WHERE id_tcm = @id_cuenta;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(128) = LEFT(ERROR_MESSAGE(), 128);
        INSERT INTO DBErrors 
        VALUES (SUSER_NAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), @ErrorMessage, GETDATE());

        THROW;
    END CATCH;

    SET NOCOUNT OFF;
END;
GO
