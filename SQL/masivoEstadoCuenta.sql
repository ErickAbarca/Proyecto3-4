ALTER PROCEDURE [dbo].[SP_ProcesoMasivoCierreDiario]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Variables para la fecha de corte
        DECLARE @fecha_corte DATE = GETDATE();

        -- Generar los estados de cuenta para todas las cuentas con saldo positivo
        INSERT INTO EstadoCuenta (id_tcm, fecha_corte, saldo_actual, pago_minimo, pago_contado, intereses_corrientes, intereses_moratorios)
        SELECT 
            id AS id_tcm,
            @fecha_corte AS fecha_corte,
            saldo_actual,
            CASE WHEN saldo_actual > 0 THEN saldo_actual * 0.05 ELSE 0 END AS pago_minimo,
            CASE WHEN saldo_actual > 0 THEN saldo_actual ELSE 0 END AS pago_contado,
            ISNULL((SELECT SUM(monto_interes) 
                    FROM InteresCorriente 
                    WHERE InteresCorriente.id_tcm = CuentaTarjetaMaestra.id 
                      AND fecha_operacion <= @fecha_corte), 0) AS intereses_corrientes,
            ISNULL((SELECT SUM(monto_interes) 
                    FROM InteresMoratorio 
                    WHERE InteresMoratorio.id_tcm = CuentaTarjetaMaestra.id 
                      AND fecha_operacion <= @fecha_corte), 0) AS intereses_moratorios
        FROM 
            CuentaTarjetaMaestra;

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
