CREATE TRIGGER trg_recoltare_stoc
ON Recolte
AFTER UPDATE
AS
BEGIN
    DECLARE @id_cultura INT, @calitate FLOAT, @unitati_recoltate FLOAT;

    SELECT @id_cultura = id_cultura, @calitate = calitate, @unitati_recoltate = unitati_recoltate FROM inserted;

    IF EXISTS (SELECT 1 FROM Stoc WHERE id_cultura = @id_cultura AND calitate = @calitate)
    BEGIN
        -- Actualizare `unitati_disponibile` în `Stoc`
        UPDATE Stoc
        SET unitati_disponibile = unitati_disponibile + @unitati_recoltate
        WHERE id_cultura = @id_cultura AND calitate = @calitate;
    END
    ELSE
    BEGIN
        -- Inserare nouă intrare dacă nu există
        INSERT INTO Stoc (id_cultura, calitate, unitati_disponibile)
        VALUES (@id_cultura, @calitate, @unitati_recoltate);
    END;
END;
GO

