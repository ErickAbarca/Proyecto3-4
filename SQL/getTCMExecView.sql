CREATE PROCEDURE SP_ObtenerCuentasPorTarjetahabiente
    @documento_identidad NVARCHAR(20)
AS
BEGIN
    DECLARE @idTarjetahabiente INT;
    SET @idTarjetahabiente = (SELECT id 
                              FROM Tarjetahabiente 
                              WHERE documento_identidad = @documento_identidad);
    SELECT * 
    FROM VistaCuentasTarjetahabiente
    WHERE TarjetahabienteID = @idTarjetahabiente;
END;
