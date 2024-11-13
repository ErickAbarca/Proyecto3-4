ALTER PROCEDURE [dbo].[SP_ProcesoRenovacionTarjetasFisicas]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @fecha_actual DATE = GETDATE();
        DECLARE @fecha_renovacion DATE = DATEADD(YEAR, -3, @fecha_actual);  -- Tarjetas que no se han renovado en 3 años

        -- Marcar como "Por renovar" las tarjetas que no se han renovado en los últimos 3 años
        UPDATE TarjetaFisica
        SET estado = 'Por renovar'
        WHERE fecha_vencimiento = '9999-12-31'
          AND estado = 'Activa'
          AND id NOT IN (SELECT id_tf FROM Movimiento WHERE descripcion = 'Costo de renovación de tarjeta' AND fecha_movimiento > @fecha_renovacion);

        -- Generar la renovación de tarjetas
        INSERT INTO TarjetaFisica (numero_tarjeta, cvv, fecha_vencimiento, id_tcm, id_tca, estado)
        SELECT 
            NEWID(),  -- Puedes usar un generador de tarjetas único según tus reglas
            RIGHT(CAST(ABS(CHECKSUM(NEWID())) AS VARCHAR), 4) AS cvv,
            DATEADD(YEAR, 3, @fecha_actual) AS nueva_fecha_vencimiento,  -- Nueva fecha de vencimiento en 3 años
            id_tcm,
            id_tca,
            'Activa'
        FROM TarjetaFisica
        WHERE estado = 'Por renovar';

        -- Insertar costo de renovación en la tabla de movimientos
        INSERT INTO Movimiento (id_tf, fecha_movimiento, tipo_movimiento, monto, descripcion, referencia)
        SELECT 
            TF.id AS id_tf,
            @fecha_actual AS fecha_movimiento,
            TM.id AS tipo_movimiento,
            CASE 
                WHEN TF.id_tcm IS NOT NULL THEN 
                    CASE 
                        WHEN TCM.tipo_tcm = 1 THEN 4000  -- Costo renovación para TCM Oro
                        WHEN TCM.tipo_tcm = 2 THEN 4500  -- Costo renovación para TCM Platino
                        WHEN TCM.tipo_tcm = 3 THEN 5000  -- Costo renovación para TCM Corporativo
                        ELSE 0
                    END
                WHEN TF.id_tca IS NOT NULL THEN 
                    CASE 
                        WHEN TCM.tipo_tcm = 1 THEN 3000  -- Costo renovación para TCA Oro
                        WHEN TCM.tipo_tcm = 2 THEN 3500  -- Costo renovación para TCA Platino
                        WHEN TCM.tipo_tcm = 3 THEN 4000  -- Costo renovación para TCA Corporativo
                        ELSE 0
                    END
            END AS monto,
            'Costo de renovación de tarjeta' AS descripcion,
            'Renovación' AS referencia
        FROM TarjetaFisica TF
        LEFT JOIN CuentaTarjetaMaestra TCM ON TF.id_tcm = TCM.id
        LEFT JOIN TipoMovimiento TM ON TM.nombre_tipo_movimiento = 'Costo de Renovación'
        WHERE TF.estado = 'Por renovar';

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
