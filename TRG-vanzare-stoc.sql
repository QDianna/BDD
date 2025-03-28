CREATE TRIGGER trg_vanzare_stoc
ON Vanzari
AFTER INSERT
AS
BEGIN
    DECLARE @id_stoc INT, @cantitate_vanduta FLOAT;

    SELECT @id_stoc = id_stoc, @cantitate_vanduta = cantitate_vanduta FROM inserted;

    -- Verificare dacă există suficient stoc pentru vânzare
    IF @cantitate_vanduta > (SELECT unitati_disponibile FROM Stoc WHERE id_stoc = @id_stoc)
    BEGIN
        RAISERROR ('Stoc insuficient pentru această vânzare!', 16, 1);
        ROLLBACK;
    END
    ELSE
    BEGIN
        -- Scade cantitatea vândută din stoc
        UPDATE Stoc
        SET unitati_disponibile = unitati_disponibile - @cantitate_vanduta
        WHERE id_stoc = @id_stoc;
    END;
END;
GO

