CREATE PROCEDURE CargarDatosDesdeXML
    @xmlData XML
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        --Validacion de la estructura del XML
        IF @xmlData.exist('/movimientos') = 0
        BEGIN
            RAISERROR('El XML no tiene la estructura correcta', 16, 1);
            RETURN;
        END
    END TRY
    BEGIN CATCH
    END CATCH
END;
GO