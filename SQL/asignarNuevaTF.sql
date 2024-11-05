ALTER PROCEDURE [dbo].[SP_AsignarNuevaTarjetaFisica]
    @id_cuenta INT,  -- ID de la cuenta (puede ser TCA o TCM)
    @tipo_cuenta CHAR(3),  -- 'TCM' o 'TCA'
    @numero_tarjeta VARCHAR(16),
    @cvv VARCHAR(4),
    @fecha_vencimiento DATE,
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id_tcm INT = NULL;
    DECLARE @id_tca INT = NULL;

    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Validación: Determinar el tipo de cuenta (TCM o TCA)
        IF @tipo_cuenta = 'TCM'
            SET @id_tcm = @id_cuenta;
        ELSE IF @tipo_cuenta = 'TCA'
            SET @id_tca = @id_cuenta;
        ELSE
        BEGIN
            SET @OutResulTCode = 50021;  -- Error: Tipo de cuenta inválido
            RETURN;
        END

        -- Comienza la transacción
        BEGIN TRANSACTION;

        -- Inactivar la tarjeta física anterior de la cuenta
        UPDATE dbo.TarjetaFisica
        SET estado = 'Inactiva'
        WHERE (id_tcm = @id_tcm OR id_tca = @id_tca) AND estado = 'Activa';

        -- Asignar nueva tarjeta física
        INSERT INTO dbo.TarjetaFisica (
            numero_tarjeta,
            cvv,
            fecha_vencimiento,
            id_tcm,
            id_tca,
            estado
        ) VALUES (
            @numero_tarjeta,
            @cvv,
            @fecha_vencimiento,
            @id_tcm,
            @id_tca,
            'Activa'
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
