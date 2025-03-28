CREATE TRIGGER trg_plantare_teren
ON Operatiuni
AFTER INSERT
AS
BEGIN
    UPDATE t
    SET t.id_cultura = i.id_cultura,
        t.data_plantare = i.data_inceput,
        t.data_estimativa_recoltare = DATEADD(DAY, c.durata_crestere, i.data_inceput)
    FROM Terenuri t
    JOIN inserted i ON t.id_teren = i.id_teren
    JOIN Culturi c ON c.id_cultura = i.id_cultura
    WHERE i.tip_operatiune LIKE 'plantare';
END;
GO

