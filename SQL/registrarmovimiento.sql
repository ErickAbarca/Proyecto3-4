ALTER PROCEDURE [dbo].[SP_RegistrarMovimiento]
    @id_tf INT,  -- ID de la tarjeta física
    @tipo_movimiento INT,  -- Referencia al tipo de movimiento
    @monto DECIMAL(18,2),
    @descripcion VARCHAR(256),
    @referencia VARCHAR(64),
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Validación: Verificar que la tarjeta física esté activa y no vencida
        IF NOT EXISTS (SELECT 1 FROM dbo.TarjetaFisica 
                       WHERE id = @id_tf 
                       AND estado = 'Activa' 
                       AND fecha_vencimiento > GETDATE())
        BEGIN
            SET @OutResulTCode = 50014;  -- Código de error para tarjeta inactiva o vencida
            RETURN;
        END

        -- Validación: Verificar que el tipo de movimiento exista
        IF NOT EXISTS (SELECT 1 FROM dbo.TipoMovimiento WHERE id = @tipo_movimiento)
        BEGIN
            SET @OutResulTCode = 50015;  -- Código de error para tipo de movimiento no encontrado
            RETURN;
        END

        -- Comienza la transacción
        BEGIN TRANSACTION;

        -- Inserción del nuevo movimiento
        INSERT INTO dbo.Movimiento (
            id_tf,
            fecha_movimiento,
            tipo_movimiento,
            monto,
            descripcion,
            referencia
        ) VALUES (
            @id_tf,
            GETDATE(),
            @tipo_movimiento,
            @monto,
            @descripcion,
            @referencia
        );

        -- Confirmar la transacción
        COMMIT TRANSACTION;

        -- Código de salida en caso de éxito
        SET @OutResulTCode = 0;

    END TRY
    BEGIN CATCH
        -- Manejo de errores
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        -- Registrar error en tabla de errores
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

        -- Código de error estándar
        SET @OutResulTCode = 50008;
    END CATCH;

    SET NOCOUNT OFF;
END;
GO