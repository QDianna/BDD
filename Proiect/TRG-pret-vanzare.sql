CREATE TRIGGER trg_pret_vanzare
ON Vanzari
AFTER INSERT
AS
BEGIN
    DECLARE @id_stoc INT, @id_cultura INT, @calitate FLOAT, @pret_cultura FLOAT;

    -- Preluarea datelor din tabela `Stoc`
    SELECT @id_stoc = id_stoc FROM inserted;
    SELECT @id_cultura = id_cultura, @calitate = calitate 
    FROM Stoc WHERE id_stoc = @id_stoc;

    -- Preluarea prețului unitar din tabela `Culturi`
    SELECT @pret_cultura = pret_unitar 
    FROM Culturi WHERE id_cultura = @id_cultura;

    -- Calculare `pret_unitar` și actualizare `Vanzari`
    UPDATE Vanzari
    SET pret_unitar_vanzare = @pret_cultura * @calitate
    WHERE id_vanzare IN (SELECT id_vanzare FROM inserted);
END;
GO

