CREATE VIEW VistaCuentasTarjetahabiente AS
SELECT 
    th.id AS TarjetahabienteID,
    th.nombre AS NombreTarjetahabiente,
    th.documento_identidad AS DocumentoIdentidad,
    ctm.codigo_tcm AS CodigoCuentaMaestra,
    ctm.limite_credito AS LimiteCredito,
    ctm.saldo_actual AS SaldoActual,
    ctm.fecha_creacion AS FechaCreacionCuenta,
    tcm.nombre_tipo_tcm AS TipoCuentaMaestra
FROM 
    Tarjetahabiente th
INNER JOIN 
    CuentaTarjetaMaestra ctm ON th.id = ctm.id_th
INNER JOIN 
    TipoCuentaMaestra tcm ON ctm.tipo_tcm = tcm.id;