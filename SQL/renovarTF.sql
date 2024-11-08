CREATE PROCEDURE [dbo].[SP_RenovarTarjetaFisica]
    @id_tf INT,  -- ID de la tarjeta física
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @fecha_vencimiento DATE;
    DECLARE @id_tcm INT;
    DECLARE @cargo_renovacion DECIMAL(10,2);

    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Validación: Obtener fecha de vencimiento y verificar si la tarjeta existe y necesita renovación
        SELECT @fecha_vencimiento = fecha_vencimiento, @id_tcm = id_tcm
        FROM dbo.TarjetaFisica
        WHERE id = @id_tf AND estado = 'Activa';

        IF @fecha_vencimiento IS NULL
        BEGIN
            SET @OutResulTCode = 50019;  -- Error: Tarjeta no encontrada o ya inactiva
            RETURN;
        END

        IF @fecha_vencimiento > GETDATE()
        BEGIN
            SET @OutResulTCode = 50020;  -- Error: Tarjeta aún no necesita renovación
            RETURN;
        END

        -- Obtener cargo de renovación según el tipo de cuenta maestra
        SELECT @cargo_renovacion = RN.cargo_servicio_tcm
        FROM dbo.CuentaTarjetaMaestra CTM
        JOIN dbo.ReglaNegocio RN ON RN.tipo_tcm = CTM.tipo_tcm
        WHERE CTM.id = @id_tcm;

        -- Comienza la transacción
        BEGIN TRANSACTION;

        -- Actualizar la fecha de vencimiento de la tarjeta (por ejemplo, extender 3 años)
        UPDATE dbo.TarjetaFisica
        SET fecha_vencimiento = DATEADD(YEAR, 3, GETDATE())
        WHERE id = @id_tf;

        -- Registrar el cargo de renovación como movimiento
        INSERT INTO dbo.Movimiento (
            id_tf,
            fecha_movimiento,
            tipo_movimiento,
            monto,
            descripcion,
            referencia
        ) VALUES (
            @id_tf,
            GETDATE(),
            4,  -- Supone que "4" es el tipo de movimiento para "Renovación"
            @cargo_renovacion,
            'Renovación de tarjeta física',
            NULL
        );

        -- Confirmar la transacción
        COMMIT TRANSACTION;

        SET @OutResulTCode = 0;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        INSERT INTO dbo.DBErrors VALUES (
            SUSER_SNAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );

        SET @OutResulTCode = 50008;
    END CATCH;

    SET NOCOUNT OFF;
END;
GO
