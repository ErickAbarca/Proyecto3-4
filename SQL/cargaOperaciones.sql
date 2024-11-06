ALTER PROCEDURE CargarDatosDesdeXML
    @xmlData XML
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Iniciar la transacción
        BEGIN TRANSACTION;
        -- Insertar en la tabla Tarjetahabiente
        INSERT INTO dbo.Tarjetahabiente (nombre, id_tipo_documento, documento_identidad, nombre_usuario, password)
        SELECT 
            NTH.value('@Nombre', 'VARCHAR(128)') AS nombre,
            1 AS id_tipo_documento,  -- Valor predeterminado para el tipo de documento
            NTH.value('@ValorDocIdentidad', 'VARCHAR(32)') AS documento_identidad,
            NTH.value('@NombreUsuario', 'VARCHAR(64)') AS nombre_usuario,
            HASHBYTES('SHA2_256', NTH.value('@Password', 'VARCHAR(128)')) AS password
        FROM @xmlData.nodes('/root/fechaOperacion/NTH/NTH') AS T(NTH);

        -- Insertar en la tabla CuentaTarjetaMaestra
        INSERT INTO dbo.CuentaTarjetaMaestra (codigo_tcm, tipo_tcm, limite_credito, saldo_actual, id_th, fecha_creacion)
        SELECT 
            NTCM.value('@Codigo', 'VARCHAR(32)') AS codigo_tcm,
            CASE NTCM.value('@TipoTCM', 'VARCHAR(16)')
                WHEN 'Corporativo' THEN 1
                WHEN 'Oro' THEN 2
                WHEN 'Platino' THEN 3
                ELSE NULL END AS tipo_tcm,
            NTCM.value('@LimiteCredito', 'DECIMAL(18,2)') AS limite_credito,
            0 AS saldo_actual,  -- Saldo inicial en cero
            th.id AS id_th,
            GETDATE() AS fecha_creacion
        FROM @xmlData.nodes('/root/fechaOperacion/NTCM/NTCM') AS T(NTCM)
        JOIN Tarjetahabiente th ON th.documento_identidad = NTCM.value('@TH', 'VARCHAR(32)');

        -- Insertar en la tabla CuentaTarjetaAdicional
        INSERT INTO dbo.CuentaTarjetaAdicional (codigo_tca, id_tcm, id_th)
        SELECT 
            NTCA.value('@CodigoTCA', 'VARCHAR(32)') AS codigo_tca,
            ctm.id AS id_tcm,
            th.id AS id_th
        FROM @xmlData.nodes('/root/fechaOperacion/NTCA/NTCA') AS T(NTCA)
        JOIN CuentaTarjetaMaestra ctm ON ctm.codigo_tcm = NTCA.value('@CodigoTCM', 'VARCHAR(32)')
        JOIN Tarjetahabiente th ON th.documento_identidad = NTCA.value('@TH', 'VARCHAR(32)');

        -- Insertar en la tabla TarjetaFisica
        INSERT INTO dbo.TarjetaFisica (numero_tarjeta, cvv, fecha_vencimiento, id_tcm, id_tca, estado)
        SELECT 
            NTF.value('@Codigo', 'VARCHAR(16)') AS numero_tarjeta,
            NTF.value('@CCV', 'VARCHAR(4)') AS cvv,
            CONVERT(DATE, '01/' + NTF.value('@FechaVencimiento', 'VARCHAR(7)'), 103) AS fecha_vencimiento,
            ctm.id AS id_tcm,
            NULLIF(cta.id, 0) AS id_tca,
            'Activa' AS estado
        FROM @xmlData.nodes('/root/fechaOperacion/NTF/NTF') AS T(NTF)
        LEFT JOIN CuentaTarjetaMaestra ctm ON ctm.codigo_tcm = NTF.value('@TCAsociada', 'VARCHAR(32)')
        LEFT JOIN CuentaTarjetaAdicional cta ON cta.codigo_tca = NTF.value('@TCAsociada', 'VARCHAR(32)');

        -- Insertar en la tabla Movimiento
        INSERT INTO dbo.Movimiento (id_tf, fecha_movimiento, tipo_movimiento, monto, descripcion, referencia)
        SELECT 
            tf.id AS id_tf,
            CONVERT(DATETIME, M.value('@FechaMovimiento', 'VARCHAR(10)'), 120) AS fecha_movimiento,
            1 AS tipo_movimiento,  -- Ajuste según el tipo de movimiento específico
            M.value('@Monto', 'DECIMAL(18,2)') AS monto,
            M.value('@Descripcion', 'VARCHAR(256)') AS descripcion,
            M.value('@Referencia', 'VARCHAR(64)') AS referencia
        FROM @xmlData.nodes('/root/fechaOperacion/Movimiento/Movimiento') AS M(Movimiento)
        JOIN TarjetaFisica tf ON tf.numero_tarjeta = M.value('@TF', 'VARCHAR(16)');

        -- Confirmar la transacción
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Deshacer la transacción en caso de error
        ROLLBACK TRANSACTION;

        -- Registrar el error en la tabla DBErrors
        INSERT INTO dbo.DBErrors
        VALUES (
            SYSTEM_USER,
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );

        -- Código de error estándar
        THROW;
    END CATCH;
    SET NOCOUNT OFF;
END;
GO