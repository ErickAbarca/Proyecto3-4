CREATE TRIGGER trg_UpdateSaldoAfterMovimiento
ON Movimiento
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_tcm INT, @tipo_movimiento INT, @monto DECIMAL(18,2);

    SELECT @id_tcm = tf.id_tcm, 
           @tipo_movimiento = i.tipo_movimiento,
           @monto = i.monto
    FROM inserted i
    JOIN TarjetaFisica tf ON i.id_tf = tf.id;

    -- Verifica si el movimiento es un débito o un crédito
    IF @tipo_movimiento IN (SELECT id FROM TipoMovimiento WHERE accion = 'Débito')
    BEGIN
        UPDATE CuentaTarjetaMaestra
        SET saldo_actual = saldo_actual + @monto
        WHERE id = @id_tcm;
    END
    ELSE IF @tipo_movimiento IN (SELECT id FROM TipoMovimiento WHERE accion = 'Crédito')
    BEGIN
        UPDATE CuentaTarjetaMaestra
        SET saldo_actual = saldo_actual - @monto
        WHERE id = @id_tcm;
    END
END;
GO
