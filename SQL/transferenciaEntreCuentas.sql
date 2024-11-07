ALTER PROCEDURE [dbo].[SP_TransferenciaEntreCuentas]
    @id_cuenta_origen INT,
    @id_cuenta_destino INT,
    @monto DECIMAL(18,2),
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        IF @id_cuenta_origen = @id_cuenta_destino
        BEGIN
            SET @OutResulTCode = 50001;  -- Error: Cuentas iguales
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.CuentaTarjetaMaestra WHERE id = @id_cuenta_origen)
        BEGIN
            SET @OutResulTCode = 50002;  -- Error: cuenta origen no existe
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.CuentaTarjetaMaestra WHERE id = @id_cuenta_destino)
        BEGIN
            SET @OutResulTCode = 50003;  -- Error: cuenta destino no existe
            RETURN;
        END

        BEGIN TRANSACTION;

        UPDATE dbo.CuentaTarjetaMaestra
        SET saldo_actual = saldo_actual - @monto
        WHERE id = @id_cuenta_origen;

        UPDATE dbo.CuentaTarjetaMaestra
        SET saldo_actual = saldo_actual + @monto
        WHERE id = @id_cuenta_destino;

        COMMIT TRANSACTION;
        SET @OutResulTCode = 0;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        INSERT INTO dbo.DBErrors VALUES (SUSER_SNAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
        SET @OutResulTCode = 50004;
    END CATCH;
    SET NOCOUNT OFF;
END;
GO
