ALTER PROCEDURE SP_ObtenerCuentasPorTarjetahabiente
    @documento_identidad NVARCHAR(20)
AS
BEGIN
    DECLARE @idTarjetahabiente INT;
    SET @idTarjetahabiente = (SELECT TarjetahabienteID 
                              FROM Tarjetahabiente 
                              WHERE DocumentoIdentidad = @documento_identidad);
    SELECT * 
    FROM VistaCuentasTarjetahabiente
    WHERE TarjetahabienteID = @idTarjetahabiente;
END;
