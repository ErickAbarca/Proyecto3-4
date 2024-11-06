ALTER PROCEDURE CargarDatosDesdeXML
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

        -- Tabla de errores de relación para movimientos
        CREATE TABLE #ErroresMovimiento (
            numero_tarjeta VARCHAR(16),
            tipo_movimiento_nombre VARCHAR(64),
            error_mensaje VARCHAR(256)
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
            GETDATE()
        FROM @xmlData.nodes('/root/fechaOperacion/NTCM/NTCM') AS T(NTCM)
        WHERE NTCM.value('@Codigo', 'VARCHAR(32)') IS NOT NULL;

        INSERT INTO #TempTarjetaFisica (numero_tarjeta, cvv, fecha_vencimiento, id_tcm, id_tca, estado)
        SELECT DISTINCT
            NTF.value('@Codigo', 'VARCHAR(16)'),
            NTF.value('@CCV', 'VARCHAR(4)'),
            ISNULL(TRY_CONVERT(DATE, NTF.value('@FechaVencimiento', 'VARCHAR(10)'), 103), '9999-12-31'),  -- Fecha por defecto
            (SELECT TOP 1 id FROM CuentaTarjetaMaestra WHERE codigo_tcm = NTF.value('@TCAsociada', 'VARCHAR(32)')),
            NULL,
            'Activa'
        FROM @xmlData.nodes('/root/fechaOperacion/NTF/NTF') AS T(NTF)
        WHERE NTF.value('@Codigo', 'VARCHAR(16)') IS NOT NULL;

        -- Insertar movimientos en la tabla temporal y registrar errores
        INSERT INTO #TempMovimiento (id_tf, fecha_movimiento, tipo_movimiento, monto, descripcion, referencia)
        SELECT 
            TF.id AS id_tf,
            ISNULL(TRY_CONVERT(DATETIME, Movimiento.value('@FechaMovimiento', 'VARCHAR(10)'), 103), GETDATE()),
            TM.id AS tipo_movimiento,
            Movimiento.value('@Monto', 'DECIMAL(18,2)'),
            Movimiento.value('@Descripcion', 'VARCHAR(256)'),
            Movimiento.value('@Referencia', 'VARCHAR(64)')
        FROM @xmlData.nodes('/root/fechaOperacion/Movimiento/Movimiento') AS T(Movimiento)
        INNER JOIN TarjetaFisica TF ON TF.numero_tarjeta = Movimiento.value('@TF', 'VARCHAR(16)')
        INNER JOIN TipoMovimiento TM ON TM.nombre_tipo_movimiento = Movimiento.value('@Nombre', 'VARCHAR(64)')
        WHERE Movimiento.value('@TF', 'VARCHAR(16)') IS NOT NULL 
          AND Movimiento.value('@FechaMovimiento', 'VARCHAR(10)') IS NOT NULL;

        -- Registrar errores en movimientos con relaciones inválidas
        INSERT INTO #ErroresMovimiento (numero_tarjeta, tipo_movimiento_nombre, error_mensaje)
        SELECT 
            Movimiento.value('@TF', 'VARCHAR(16)') AS numero_tarjeta,
            Movimiento.value('@Nombre', 'VARCHAR(64)') AS tipo_movimiento_nombre,
            CASE 
                WHEN TF.id IS NULL THEN 'No se encontró TarjetaFisica con el número especificado.'
                WHEN TM.id IS NULL THEN 'No se encontró TipoMovimiento con el nombre especificado.'
            END AS error_mensaje
        FROM @xmlData.nodes('/root/fechaOperacion/Movimiento/Movimiento') AS T(Movimiento)
        LEFT JOIN TarjetaFisica TF ON TF.numero_tarjeta = Movimiento.value('@TF', 'VARCHAR(16)')
        LEFT JOIN TipoMovimiento TM ON TM.nombre_tipo_movimiento = Movimiento.value('@Nombre', 'VARCHAR(64)')
        WHERE TF.id IS NULL OR TM.id IS NULL;

        -- Verificar contenido en #TempMovimiento y #ErroresMovimiento antes de la inserción final
        SELECT * FROM #TempMovimiento;
        SELECT * FROM #ErroresMovimiento;

        -- Insertar datos en Movimiento
        INSERT INTO Movimiento (id_tf, fecha_movimiento, tipo_movimiento, monto, descripcion, referencia)
        SELECT id_tf, fecha_movimiento, tipo_movimiento, monto, descripcion, referencia
        FROM #TempMovimiento;

        -- Limpieza de tablas temporales
        DROP TABLE #TempTarjetahabiente;
        DROP TABLE #TempCuentaTarjetaMaestra;
        DROP TABLE #TempTarjetaFisica;
        DROP TABLE #TempMovimiento;
        DROP TABLE #ErroresMovimiento;

    END TRY
    BEGIN CATCH
        -- Capturar errores en la tabla DBErrors y ajustar la longitud de Message para evitar truncamiento
        DECLARE @ErrorMessage NVARCHAR(128) = LEFT(ERROR_MESSAGE(), 128);
        INSERT INTO DBErrors 
        VALUES (SUSER_NAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), @ErrorMessage, GETDATE());
    END CATCH;
END;
