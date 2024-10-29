ALTER PROCEDURE [dbo].[SP_CrearTarjetahabiente]
    @nombre VARCHAR(128),
    @id_tipo_documento INT,
    @documento_identidad VARCHAR(32),
    @nombre_usuario VARCHAR(64),
    @password VARCHAR(128),
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        IF EXISTS (SELECT 1 FROM dbo.Tarjetahabiente WHERE documento_identidad = @documento_identidad)
        BEGIN
            SET @OutResulTCode = 50006;  -- Código de error para documento duplicado
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM dbo.Tarjetahabiente WHERE nombre_usuario = @nombre_usuario)
        BEGIN
            SET @OutResulTCode = 50005;  -- Código de error para nombre de usuario duplicado
            RETURN;
        END

        -- Comienza la transacción
        BEGIN TRANSACTION;

        -- Inserción del nuevo tarjetahabiente
        INSERT INTO dbo.Tarjetahabiente (
            nombre,
            id_tipo_documento,
            documento_identidad,
            nombre_usuario,
            password
        ) VALUES (
            @nombre,
            @id_tipo_documento,
            @documento_identidad,
            @nombre_usuario,
            @password
        );

        -- Confirma la transacción
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
