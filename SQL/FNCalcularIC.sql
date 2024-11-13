CREATE FUNCTION FN_CalcularInteresCorriente
(
    @tipo_tcm INT,
    @saldo_actual DECIMAL(18,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @interes_mensual DECIMAL(5,2);

    -- Determinar la tasa de interés según el tipo de cuenta
    SET @interes_mensual = CASE 
        WHEN @tipo_tcm = 1 THEN 3.5  -- Oro
        WHEN @tipo_tcm = 2 THEN 4.0  -- Platino
        WHEN @tipo_tcm = 3 THEN 4.0  -- Corporativo
        ELSE 0
    END;

    -- Calcular el interés sobre el saldo actual
    RETURN @saldo_actual * @interes_mensual / 100;
END;
GO
