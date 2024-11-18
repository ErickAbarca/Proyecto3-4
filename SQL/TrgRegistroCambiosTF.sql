CREATE TRIGGER trg_RegistrarCambioEstadoTarjeta
ON TarjetaFisica
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO HistorialEstadoTarjeta (id_tarjeta, estado_anterior, nuevo_estado, fecha_cambio)
    SELECT 
        i.id,               
        d.estado,           
        i.estado,           
        GETDATE()           
    FROM inserted i
    INNER JOIN deleted d ON i.id = d.id
    WHERE i.estado <> d.estado;  
END;
GO
