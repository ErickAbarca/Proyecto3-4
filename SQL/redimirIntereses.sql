ALTER PROCEDURE [dbo].[SP_RedimirIntereses]
    @id_tcm INT,  -- ID de la cuenta maestra
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResulTCode = 0;

        -- Comienza la transacción
        BEGIN TRANSACTION;

        -- Ajustar intereses corrientes y moratorios en cero
        UPDATE dbo.CuentaTarjetaMaestra
        SET saldo_actual = saldo_actual + 
            (SELECT ISNULL(SUM(monto_interes), 0) FROM dbo.InteresCorriente WHERE id_tcm = @id_tcm) + 
            (SELECT ISNULL(SUM(monto_interes), 0) FROM dbo.InteresMoratorio WHERE id_tcm = @id_tcm)
        WHERE id = @id_tcm;

        -- Eliminar intereses acumulados
        DELETE FROM dbo.InteresCorriente WHERE id_tcm = @id_tcm;
        DELETE FROM dbo.InteresMoratorio WHERE id_tcm = @id_tcm;

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
