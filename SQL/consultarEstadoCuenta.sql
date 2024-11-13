CREATE PROCEDURE [dbo].[SP_ConsultarEstadoCuenta]
    @id_tcm INT,  -- ID de la cuenta maestra
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Consultar el estado de cuenta más reciente
        SELECT  
            fecha_corte,
            saldo_actual,
            pago_minimo,
            pago_contado,
            intereses_corrientes,
            intereses_moratorios
        FROM dbo.EstadoCuenta
        WHERE id_tcm = @id_tcm
        ORDER BY fecha_corte DESC;

    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors VALUES (
            SUSER_SNAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );

        SET @OutResulTCode = 50008;
    END CATCH;

    SET NOCOUNT OFF;
END;
GO
