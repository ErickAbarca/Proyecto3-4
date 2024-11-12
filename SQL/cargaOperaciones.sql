ALTER PROCEDURE [dbo].[CargarDatosDesdeXML]
    @xmlData XML
AS
BEGIN
    BEGIN TRY
        -- Crear tablas temporales
        CREATE TABLE #TempTarjetahabiente (
            nombre VARCHAR(128),
            id_tipo_documento INT,
            documento_identidad VARCHAR(32) NOT NULL,
            nombre_usuario VARCHAR(64),
            password VARCHAR(128)
        );

        CREATE TABLE #TempCuentaTarjetaMaestra (
            codigo_tcm VARCHAR(32) NOT NULL,
            tipo_tcm INT,
            limite_credito DECIMAL(18,2),
            saldo_actual DECIMAL(18,2),
            id_th INT,
            fecha_creacion DATE
        );

        CREATE TABLE #TempCuentaTarjetaAdicional (
            codigo_tca VARCHAR(32) NOT NULL,
            id_tcm INT,
            id_th INT
        );

        CREATE TABLE #TempTarjetaFisica (
            numero_tarjeta VARCHAR(16) NOT NULL,
            cvv VARCHAR(4),
            fecha_vencimiento DATE,
            id_tcm INT,
            id_tca INT,
            estado VARCHAR(16)
        );

        CREATE TABLE #TempMovimiento (
            id_tf INT NOT NULL,
            fecha_movimiento DATETIME,
            tipo_movimiento INT,
            monto DECIMAL(18,2),
            descripcion VARCHAR(256),
            referencia VARCHAR(64)
        );

        -- Cargar datos en tablas temporales
        INSERT INTO #TempTarjetahabiente (nombre, id_tipo_documento, documento_identidad, nombre_usuario, password)
        SELECT DISTINCT 
            NTH.value('@Nombre', 'VARCHAR(128)'),  
            NULL,
            NTH.value('@ValorDocIdentidad', 'VARCHAR(32)'),
            NTH.value('@NombreUsuario', 'VARCHAR(64)'),
            NTH.value('@Password', 'VARCHAR(128)')
        FROM @xmlData.nodes('/root/fechaOperacion/NTH/NTH') AS T(NTH)
        WHERE NTH.value('@ValorDocIdentidad', 'VARCHAR(32)') IS NOT NULL;

        INSERT INTO #TempCuentaTarjetaMaestra (codigo_tcm, tipo_tcm, limite_credito, saldo_actual, id_th, fecha_creacion)
SELECT DISTINCT 
    NTCM.value('@Codigo', 'VARCHAR(32)'),
    CASE 
        WHEN NTCM.value('@TipoTCM', 'VARCHAR(16)') = 'Oro' THEN 1
        WHEN NTCM.value('@TipoTCM', 'VARCHAR(16)') = 'Platino' THEN 2
        WHEN NTCM.value('@TipoTCM', 'VARCHAR(16)') = 'Corporativo' THEN 3
    END,
    NTCM.value('@LimiteCredito', 'DECIMAL(18,2)'),
    0,
    (SELECT id FROM Tarjetahabiente WHERE documento_identidad = NTCM.value('@TH', 'VARCHAR(32)')),
    ISNULL(NTCM.value('(../@Fecha)[1]', 'DATE'), GETDATE())  -- Usar GETDATE() si falta la fecha
FROM @xmlData.nodes('/root/fechaOperacion/NTCM/NTCM') AS T(NTCM)
WHERE NTCM.value('@Codigo', 'VARCHAR(32)') IS NOT NULL
  AND (SELECT id FROM Tarjetahabiente WHERE documento_identidad = NTCM.value('@TH', 'VARCHAR(32)')) IS NOT NULL;


        -- Cargar datos en la tabla temporal de cuentas adicionales
        INSERT INTO #TempCuentaTarjetaAdicional (codigo_tca, id_tcm, id_th)
        SELECT DISTINCT
            NTCA.value('@CodigoTCA', 'VARCHAR(32)'),
            (SELECT id FROM CuentaTarjetaMaestra WHERE codigo_tcm = NTCA.value('@CodigoTCM', 'VARCHAR(32)')),
            (SELECT id FROM Tarjetahabiente WHERE documento_identidad = NTCA.value('@TH', 'VARCHAR(32)'))
        FROM @xmlData.nodes('/root/fechaOperacion/NTCA/NTCA') AS T(NTCA)
        WHERE NTCA.value('@CodigoTCA', 'VARCHAR(32)') IS NOT NULL;

        INSERT INTO #TempTarjetaFisica (numero_tarjeta, cvv, fecha_vencimiento, id_tcm, id_tca, estado)
SELECT DISTINCT
    NTF.value('@Codigo', 'VARCHAR(16)'),
    NTF.value('@CCV', 'VARCHAR(4)'),
    ISNULL(TRY_CONVERT(DATE, NTF.value('@FechaVencimiento', 'VARCHAR(10)'), 103), '9999-12-31'),  -- Usar fecha por defecto si es NULL
    (SELECT TOP 1 id FROM CuentaTarjetaMaestra WHERE codigo_tcm = NTF.value('@TCAsociada', 'VARCHAR(32)')),
    (SELECT TOP 1 id FROM CuentaTarjetaAdicional WHERE codigo_tca = NTF.value('@TCAsociada', 'VARCHAR(32)')),
    'Activa'
FROM @xmlData.nodes('/root/fechaOperacion/NTF/NTF') AS T(NTF)
WHERE NTF.value('@Codigo', 'VARCHAR(16)') IS NOT NULL;


        INSERT INTO #TempMovimiento (id_tf, fecha_movimiento, tipo_movimiento, monto, descripcion, referencia)
SELECT 
    TF.id AS id_tf,
    CASE 
        WHEN Movimiento.value('@FechaMovimiento', 'VARCHAR(10)') IS NOT NULL 
             AND TRY_CONVERT(DATETIME, Movimiento.value('@FechaMovimiento', 'VARCHAR(10)'), 103) IS NOT NULL
        THEN TRY_CONVERT(DATETIME, Movimiento.value('@FechaMovimiento', 'VARCHAR(10)'), 103)
        ELSE GETDATE()  -- Usar la fecha actual si la fecha no es válida o está ausente
    END AS fecha_movimiento,
    TM.id AS tipo_movimiento,
    Movimiento.value('@Monto', 'DECIMAL(18,2)'),
    Movimiento.value('@Descripcion', 'VARCHAR(256)'),
    Movimiento.value('@Referencia', 'VARCHAR(64)')
FROM @xmlData.nodes('/root/fechaOperacion/Movimiento/Movimiento') AS T(Movimiento)
INNER JOIN TarjetaFisica TF ON TF.numero_tarjeta = Movimiento.value('@TF', 'VARCHAR(16)')
INNER JOIN TipoMovimiento TM ON TM.nombre_tipo_movimiento = Movimiento.value('@Nombre', 'VARCHAR(64)')
WHERE Movimiento.value('@TF', 'VARCHAR(16)') IS NOT NULL 
  AND Movimiento.value('@FechaMovimiento', 'VARCHAR(10)') IS NOT NULL;
  -- Actualizar el saldo de la cuenta maestra
UPDATE CTM
SET saldo_actual = saldo_actual + M.monto  -- Ajustar el saldo de la cuenta maestra según el movimiento
FROM CuentaTarjetaMaestra CTM
INNER JOIN CuentaTarjetaAdicional CTA ON CTA.id_tcm = CTM.id
INNER JOIN Movimiento M ON M.id_tf = CTA.id
WHERE M.tipo_movimiento = 1  -- O el tipo de movimiento que sea adecuado, por ejemplo, un depósito
  AND M.fecha_movimiento BETWEEN '2024-01-01' AND '2024-12-31';  -- Rango de fechas según necesites


-- Cargar renovaciones por robo o pérdida
UPDATE TF
SET estado = CASE 
                WHEN RRP.value('@Razon', 'VARCHAR(16)') = 'Robo' THEN 'Robo'
                WHEN RRP.value('@Razon', 'VARCHAR(16)') = 'Perdida' THEN 'Perdida'
                ELSE TF.estado
             END
FROM TarjetaFisica TF
INNER JOIN @xmlData.nodes('/root/fechaOperacion/RenovacionRoboPerdida/RRP') AS T(RRP)
    ON TF.numero_tarjeta = RRP.value('@TF', 'VARCHAR(16)')
WHERE RRP.value('@TF', 'VARCHAR(16)') IS NOT NULL
  AND (RRP.value('@Razon', 'VARCHAR(16)') = 'Robo' OR RRP.value('@Razon', 'VARCHAR(16)') = 'Perdida');



        -- Insertar datos en las tablas finales
        --INSERT INTO Tarjetahabiente (nombre, id_tipo_documento, documento_identidad, nombre_usuario, password)
        --SELECT nombre, id_tipo_documento, documento_identidad, nombre_usuario, password FROM #TempTarjetahabiente;

        --INSERT INTO CuentaTarjetaMaestra (codigo_tcm, tipo_tcm, limite_credito, saldo_actual, id_th, fecha_creacion)
        --SELECT codigo_tcm, tipo_tcm, limite_credito, saldo_actual, id_th, fecha_creacion FROM #TempCuentaTarjetaMaestra;

        --INSERT INTO CuentaTarjetaAdicional (codigo_tca, id_tcm, id_th)
        --SELECT codigo_tca, id_tcm, id_th FROM #TempCuentaTarjetaAdicional;

        --INSERT INTO TarjetaFisica (numero_tarjeta, cvv, fecha_vencimiento, id_tcm, id_tca, estado)
        --SELECT numero_tarjeta, cvv, fecha_vencimiento, id_tcm, id_tca, estado FROM #TempTarjetaFisica;

        --INSERT INTO Movimiento (id_tf, fecha_movimiento, tipo_movimiento, monto, descripcion, referencia)
        --SELECT id_tf, fecha_movimiento, tipo_movimiento, monto, descripcion, referencia FROM #TempMovimiento;

        -- Limpiar tablas temporales
        DROP TABLE #TempTarjetahabiente;
        DROP TABLE #TempCuentaTarjetaMaestra;
        DROP TABLE #TempCuentaTarjetaAdicional;
        DROP TABLE #TempTarjetaFisica;
        DROP TABLE #TempMovimiento;

    END TRY
    BEGIN CATCH
        -- Registrar errores en DBErrors con tamaño ajustado de Message
        DECLARE @ErrorMessage NVARCHAR(128) = LEFT(ERROR_MESSAGE(), 128);
        INSERT INTO DBErrors 
        VALUES (SUSER_NAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), @ErrorMessage, GETDATE());
    END CATCH;
END;
