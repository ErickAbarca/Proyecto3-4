ALTER PROCEDURE SP_ConsultarCuentaAdicional
@documento_identidad NVARCHAR(20)
AS
BEGIN
    DECLARE @idTarjetahabiente INT,
            @idCuentaMaestra INT;
    SET @idTarjetahabiente = (SELECT id 
                              FROM Tarjetahabiente 
                              WHERE documento_identidad = @documento_identidad);
    SET @idCuentaMaestra = (SELECT id 
                            FROM CuentaTarjetaMaestra 
                            WHERE id_th = @idTarjetahabiente);

    SELECT cta.codigo_tca, 
    cta.id_tcm, 
    cta.id_th
    FROM CuentaTarjetaAdicional cta
    
    LEFT JOIN Tarjetahabiente th ON cta.id_th = th.id
    LEFT JOIN CuentaTarjetaMaestra ctm ON cta.id_tcm = ctm.id

    WHERE cta.id_tcm = @idCuentaMaestra
    OR cta.id_th = @idTarjetahabiente;

END;
