ALTER PROCEDURE [dbo].[ValidarUsuario]
    @username VARCHAR(64),
    @password VARCHAR(64),  -- Contraseña ingresada por el usuario
    @OutResultCode INT OUTPUT
AS
BEGIN
    SET @OutResultCode = 0;
    SET NOCOUNT ON;

    -- Asegurarse de que el nombre de usuario existe
    IF EXISTS (SELECT 1 FROM dbo.UsuarioAdministrador WHERE nombre_usuario = @username)
    BEGIN
        -- Verificar si la contraseña ingresada coincide con el hash almacenado
        IF EXISTS (
            SELECT 1 
            FROM dbo.UsuarioAdministrador 
            WHERE nombre_usuario = @username 
            AND password = HASHBYTES('SHA2_256', @password)
        )
        BEGIN
            -- Usuario validado correctamente
            SET @OutResultCode = 50005;  -- Usuario autenticado exitosamente
        END
        ELSE
        BEGIN
            -- Contraseña incorrecta
            SET @OutResultCode = 50007;  -- Contraseña incorrecta
        END
    END
    ELSE
    BEGIN
        -- Usuario no existe
        SET @OutResultCode = 50006;  -- Usuario no encontrado
    END;

    SET NOCOUNT OFF;
END;
