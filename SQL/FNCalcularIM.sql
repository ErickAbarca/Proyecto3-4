CREATE FUNCTION FN_CalcularInteresMoratorio
(
    @tipo_tcm INT,
    @saldo_pendiente DECIMAL(18,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @interes_mora DECIMAL(5,2);

    -- Determinar la tasa de interés moratoria según el tipo de cuenta
    SET @interes_mora = CASE 
        WHEN @tipo_tcm = 1 THEN 5.0  -- Oro
        WHEN @tipo_tcm = 2 THEN 5.0  -- Platino
        WHEN @tipo_tcm = 3 THEN 6.0  -- Corporativo
        ELSE 0
    END;

    -- Calcular el interés moratorio sobre el saldo pendiente
    RETURN @saldo_pendiente * @interes_mora / 100;
END;
GO
