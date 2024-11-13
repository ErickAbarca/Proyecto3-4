ALTER PROCEDURE [dbo].[SP_ProcesarInteresesMasivos]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Calcular e insertar los intereses corrientes para todas las cuentas con saldo positivo
        INSERT INTO InteresCorriente (id_tcm, fecha_operacion, monto_interes)
        SELECT 
            id AS id_tcm,
            GETDATE() AS fecha_operacion,
            dbo.FN_CalcularInteresCorriente(tipo_tcm, saldo_actual) AS monto_interes
        FROM 
            CuentaTarjetaMaestra
        WHERE 
            saldo_actual > 0;  -- Solo calcular para cuentas con saldo positivo

        -- Calcular e insertar los intereses moratorios para cuentas con saldo mayor al pago mínimo
        INSERT INTO InteresMoratorio (id_tcm, fecha_operacion, monto_interes)
        SELECT 
            id AS id_tcm,
            GETDATE() AS fecha_operacion,
            dbo.FN_CalcularInteresMoratorio(tipo_tcm, saldo_actual) AS monto_interes
        FROM 
            CuentaTarjetaMaestra
        WHERE 
            saldo_actual > (saldo_actual * 0.05);  -- Solo aplicar moratorios si el saldo es mayor al 5% del total

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
