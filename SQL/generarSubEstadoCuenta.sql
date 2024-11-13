ALTER PROCEDURE [dbo].[SP_GenerarSubEstadoCuentaAdicional]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Variables de fechas
        DECLARE @fecha_corte DATE = GETDATE();

        -- Insertar sub-estados de cuenta para cada cuenta adicional en la tabla SubEstadoCuenta
        INSERT INTO SubEstadoCuenta (id_tcm, id_tca, fecha_corte, saldo_actual, pago_minimo, pago_contado, intereses_corrientes, intereses_moratorios)
        SELECT
            CTM.id AS id_tcm,
            TCA.id AS id_tca,
            @fecha_corte AS fecha_corte,
            CTM.saldo_actual AS saldo_actual,  -- Usa el saldo de la cuenta maestra
            CASE WHEN CTM.saldo_actual > 0 THEN CTM.saldo_actual * 0.05 ELSE 0 END AS pago_minimo,  -- Pago mínimo calculado sobre el saldo de la cuenta maestra
            CASE WHEN CTM.saldo_actual > 0 THEN CTM.saldo_actual ELSE 0 END AS pago_contado,  -- Pago total de la cuenta maestra
            ISNULL((SELECT SUM(monto_interes) 
                    FROM InteresCorriente IC
                    WHERE IC.id_tcm = CTM.id
                      AND IC.fecha_operacion <= @fecha_corte), 0) AS intereses_corrientes,
            ISNULL((SELECT SUM(monto_interes) 
                    FROM InteresMoratorio IM
                    WHERE IM.id_tcm = CTM.id
                      AND IM.fecha_operacion <= @fecha_corte), 0) AS intereses_moratorios
        FROM CuentaTarjetaAdicional TCA
        INNER JOIN CuentaTarjetaMaestra CTM ON TCA.id_tcm = CTM.id;
        
    END TRY
    BEGIN CATCH
        -- Manejo de errores y registro en DBErrors
        DECLARE @ErrorMessage NVARCHAR(4000) = LEFT(ERROR_MESSAGE(), 4000);
        INSERT INTO dbo.DBErrors
        VALUES (
            SUSER_SNAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            @ErrorMessage,
            GETDATE()
        );
    END CATCH;
END;
GO
