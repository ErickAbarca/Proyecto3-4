CREATE PROCEDURE [dbo].[getTHs]
AS
BEGIN
    SELECT id,
            nombre,
            documento_identidad
     FROM Tarjetahabiente
    ORDER BY nombre;
END