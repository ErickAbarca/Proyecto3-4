ALTER PROCEDURE [dbo].[SP_ConsultarSubEstadoCuenta]
    @num_cuenta INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @id_tca INT
        SET @id_tca = (SELECT id
                            FROM CuentaTarjetaAdicional 
                            WHERE codigo_tca = @num_cuenta);


        SELECT 
            tcm.codigo_tcm,
            SEC.fecha_corte,
            SEC.saldo_actual,
            SEC.pago_minimo,
            SEC.pago_contado,
            SEC.intereses_corrientes,
            SEC.intereses_moratorios
        FROM dbo.SubEstadoCuenta SEC
        INNER JOIN dbo.CuentaTarjetaMaestra tcm ON SEC.id_tcm = tcm.id
        WHERE id_tca = @id_tca
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

    END CATCH;

    SET NOCOUNT OFF;
END;
GO
