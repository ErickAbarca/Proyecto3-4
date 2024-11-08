CREATE PROCEDURE [dbo].[SP_RegistrarUsuarioAdministrador]
    @nombre_usuario VARCHAR(64),
    @password VARCHAR(128),
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Validación: Verificar si el usuario ya existe
        IF EXISTS (SELECT 1 FROM UsuarioAdministrador WHERE nombre_usuario = @nombre_usuario)
        BEGIN
            SET @OutResulTCode = 50022;  -- Código de error para usuario duplicado
            RETURN;
        END

        -- Comienza la transacción
        BEGIN TRANSACTION;

        -- Inserción del nuevo administrador con contraseña encriptada
        INSERT INTO UsuarioAdministrador (nombre_usuario, password)
        VALUES (@nombre_usuario, HASHBYTES('SHA2_256', @password));

        -- Confirmar la transacción
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        -- Manejo de errores
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        INSERT INTO DBErrors VALUES (
            SUSER_SNAME(), 
            ERROR_NUMBER(), 
            ERROR_STATE(), 
            ERROR_SEVERITY(), 
            ERROR_LINE(), 
            ERROR_PROCEDURE(), 
            ERROR_MESSAGE(), 
            GETDATE());

        SET @OutResulTCode = 50008;
    END CATCH;
END;
GO
