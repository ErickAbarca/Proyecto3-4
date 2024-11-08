CREATE PROCEDURE CargarCatalogosDesdeXML
    @xmlData XML
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Iniciar la transacción
        BEGIN TRANSACTION;

        -- Insertar en la tabla TipoCuentaMaestra
        INSERT INTO dbo.TipoCuentaMaestra (nombre_tipo_tcm)
        SELECT 
            TTCM.value('@Nombre', 'VARCHAR(16)')
        FROM @xmlData.nodes('/root/TTCM/TTCM') AS T(TTCM)
        WHERE TTCM.value('@Nombre', 'VARCHAR(16)') IS NOT NULL;

        -- Insertar en la tabla TipoReglasNegocio
        INSERT INTO dbo.TipoReglasNegocio (nombre, tipo)
        SELECT 
            TRN.value('@Nombre', 'VARCHAR(64)'),
            TRN.value('@tipo', 'VARCHAR(16)')
        FROM @xmlData.nodes('/root/TRN/TRN') AS T(TRN)
        WHERE TRN.value('@Nombre', 'VARCHAR(64)') IS NOT NULL
        AND TRN.value('@tipo', 'VARCHAR(16)') IS NOT NULL;

        -- Insertar en la tabla ReglaNegocio asegurando que los valores no sean NULL
        INSERT INTO dbo.ReglaNegocio (
            tipo_regla, 
            tipo_tcm, 
            limite_credito_max, 
            tasa_interes_mensual, 
            tasa_interes_mora, 
            cargo_servicio_tcm, 
            cargo_servicio_tca, 
            plazo_meses
        )
        SELECT 
            (SELECT id FROM dbo.TipoReglasNegocio WHERE nombre = RN.value('@TipoRN', 'VARCHAR(64)')),
            (SELECT id FROM dbo.TipoCuentaMaestra WHERE nombre_tipo_tcm = RN.value('@TTCM', 'VARCHAR(16)')),
            ISNULL(RN.value('@LimiteCreditoMax', 'DECIMAL(18,2)'), 0),  -- Asignar 0 si es NULL
            ISNULL(RN.value('@TasaInteresMensual', 'DECIMAL(5,2)'), 0),  -- Asignar 0 si es NULL
            ISNULL(RN.value('@TasaInteresMora', 'DECIMAL(5,2)'), 0),  -- Asignar 0 si es NULL
            ISNULL(RN.value('@CargoServicioTCM', 'DECIMAL(10,2)'), 0),  -- Asignar 0 si es NULL
            ISNULL(RN.value('@CargoServicioTCA', 'DECIMAL(10,2)'), 0),  -- Asignar 0 si es NULL
            ISNULL(RN.value('@PlazoMeses', 'INT'), 0)  -- Asignar 0 si es NULL
        FROM @xmlData.nodes('/root/RN/RN') AS T(RN)
        WHERE RN.value('@TipoRN', 'VARCHAR(64)') IS NOT NULL
        AND RN.value('@TTCM', 'VARCHAR(16)') IS NOT NULL;

        -- Insertar en la tabla MotivoInvalidacionTarjeta
        INSERT INTO dbo.MotivoInvalidacionTarjeta (nombre_motivo)
        SELECT 
            MIT.value('@Nombre', 'VARCHAR(32)')
        FROM @xmlData.nodes('/root/MIT/MIT') AS T(MIT)
        WHERE MIT.value('@Nombre', 'VARCHAR(32)') IS NOT NULL;

        -- Insertar en la tabla TipoMovimiento
        INSERT INTO dbo.TipoMovimiento (nombre_tipo_movimiento, accion)
        SELECT 
            TM.value('@Nombre', 'VARCHAR(64)'),
            TM.value('@Accion', 'VARCHAR(16)')
        FROM @xmlData.nodes('/root/TM/TM') AS T(TM)
        WHERE TM.value('@Nombre', 'VARCHAR(64)') IS NOT NULL
        AND TM.value('@Accion', 'VARCHAR(16)') IS NOT NULL;

        -- Insertar en la tabla UsuarioAdministrador
        INSERT INTO dbo.UsuarioAdministrador (nombre_usuario, password)
        SELECT 
            UA.value('@Nombre', 'VARCHAR(64)'),
            HASHBYTES('SHA2_256', UA.value('@Password', 'VARCHAR(128)'))
        FROM @xmlData.nodes('/root/UA/Usuario') AS T(UA)
        WHERE UA.value('@Nombre', 'VARCHAR(64)') IS NOT NULL
        AND UA.value('@Password', 'VARCHAR(128)') IS NOT NULL;

        -- Confirmar la transacción
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Si hay una transacción activa, hacer rollback
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

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
