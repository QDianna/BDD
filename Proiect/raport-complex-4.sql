USE FermaAgricolaDB;
GO

CREATE OR ALTER PROCEDURE RaportPerformanteTerenuri
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        t.nume AS nume_teren,
        COUNT(DISTINCT r.id_recolta) AS numar_recolte,
        ROUND(AVG(r.calitate), 3) AS calitate_medie,
        CAST((SUM(r.unitati_recoltate) * 100.0 / NULLIF(SUM(r.unitati_estimate), 0)) AS INT) AS procent_productie,
        COUNT(DISTINCT o.id_operatiune) AS numar_operatiuni_intretinere
    FROM Terenuri t
    JOIN Recolte r ON t.id_teren = r.id_teren
    LEFT JOIN Operatiuni o ON t.id_teren = o.id_teren AND o.tip_operatiune IN ('arare', 'adaugare ingrasamant', 'adaugare pesticid')
    WHERE r.data_recolta BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY t.nume
    ORDER BY procent_productie DESC, calitate_medie DESC;
END;
GO
