CREATE TRIGGER trg_recoltare_teren
ON Operatiuni
AFTER INSERT
AS
BEGIN

    -- Inserăm doar dacă nu există deja o recoltă pentru aceeași combinație de `id_teren` și `data_recolta`
    INSERT INTO Recolte (id_teren, id_cultura, data_recolta, unitati_estimate)
    SELECT i.id_teren, t.id_cultura, i.data_final, t.suprafata_hectare * c.unitati_per_hectar
    FROM inserted i
    JOIN Terenuri t ON t.id_teren = i.id_teren
    JOIN Culturi c ON c.id_cultura = t.id_cultura
    WHERE i.tip_operatiune = 'recoltare';

    -- Actualizăm tabelul `Terenuri` (setare NULL după recoltare)
    UPDATE Terenuri
    SET id_cultura = NULL, data_plantare = NULL, data_estimativa_recoltare = NULL
    WHERE id_teren IN (SELECT id_teren FROM inserted WHERE tip_operatiune = 'recoltare');
END;
GO

