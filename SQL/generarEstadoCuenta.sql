ALTER PROCEDURE [dbo].[SP_GenerarEstadoCuentaDiario]
    @id_tcm INT,           -- ID de la CuentaTarjetaMaestra
    @fecha_corte DATE,     -- Fecha del estado de cuenta
    @OutResultCode INT OUTPUT  -- Declaración correcta de la variable de salida
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar si ya hay una transacción activa antes de comenzar una nueva
    IF XACT_STATE() = 0
    BEGIN
        BEGIN TRANSACTION;  -- Iniciar la transacción solo si no hay una activa
    END

    BEGIN TRY
        -- Inicializar el código de salida
        SET @OutResultCode = 0;

        -- Variables para almacenar valores calculados
        DECLARE @saldo_actual DECIMAL(18,2);
        DECLARE @pago_minimo DECIMAL(18,2);
        DECLARE @pago_contado DECIMAL(18,2);
        DECLARE @intereses_corrientes DECIMAL(18,2) = 0;
        DECLARE @intereses_moratorios DECIMAL(18,2) = 0;

        -- Obtener saldo actual de la Cuenta Maestra hasta la fecha de corte
        SELECT @saldo_actual = saldo_actual
        FROM CuentaTarjetaMaestra
        WHERE id = @id_tcm;

        -- Verificar si no se encontró saldo para la cuenta
        IF @saldo_actual IS NULL
        BEGIN
            -- Insertar el error en la tabla DBErrors
            INSERT INTO dbo.DBErrors
            VALUES (
                SYSTEM_USER,
                50001,  -- Código de error personalizado
                1,      -- Estado de error
                16,     -- Severidad
                ERROR_LINE(),
                'SP_GenerarEstadoCuentaDiario', 
                'Saldo no encontrado para la cuenta ' + CAST(@id_tcm AS VARCHAR(10)),
                GETDATE()
            );

            -- Establecer código de error y terminar el procedimiento
            SET @OutResultCode = 50001;  -- Código de error personalizado
            ROLLBACK TRANSACTION;  -- Asegurarse de que la transacción se revierta en caso de error
            RETURN;
        END

        -- Calcular pago mínimo como un porcentaje del saldo actual
        SET @pago_minimo = @saldo_actual * 0.05;

        -- El pago de contado es el saldo completo
        SET @pago_contado = @saldo_actual;

        -- Asignar un valor de 0 si no hay intereses corrientes
SELECT @intereses_corrientes = ISNULL(SUM(monto_interes), 0)
FROM InteresCorriente
WHERE id_tcm = @id_tcm AND fecha_operacion <= @fecha_corte;


-- Asignar un valor de 0 si no hay intereses moratorios
SELECT @intereses_moratorios = ISNULL(SUM(monto_interes), 0)
FROM InteresMoratorio
WHERE id_tcm = @id_tcm AND fecha_operacion <= @fecha_corte;


        -- Insertar el estado de cuenta en la tabla EstadoCuenta
        INSERT INTO EstadoCuenta (id_tcm, fecha_corte, saldo_actual, pago_minimo, pago_contado, intereses_corrientes, intereses_moratorios)
        VALUES (@id_tcm, @fecha_corte, @saldo_actual, @pago_minimo, @pago_contado, @intereses_corrientes, @intereses_moratorios);

        -- Realizar el COMMIT solo si todo ha ido bien
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Si ocurre un error, hacer rollback de la transacción
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        -- Ajustar el tamaño del mensaje antes de insertarlo en DBErrors
DECLARE @ErrorMessage NVARCHAR(4000) = LEFT(ERROR_MESSAGE(), 4000);
INSERT INTO dbo.DBErrors
VALUES (
    SYSTEM_USER,
    ERROR_NUMBER(),
    ERROR_STATE(),
    ERROR_SEVERITY(),
    ERROR_LINE(),
    ERROR_PROCEDURE(),
    @ErrorMessage,
    GETDATE()
);


        -- Código de error estándar
        SET @OutResultCode = 50008;
    END CATCH;

    -- Asegurarse de que siempre se desactive el conteo de filas
    SET NOCOUNT OFF;
END;
