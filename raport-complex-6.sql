USE FermaAgricolaDB;
GO

CREATE OR ALTER PROCEDURE RaportPerformanteCulturi
AS
BEGIN
    WITH ProducțieMaximă AS (
        SELECT 
            c.nume AS cultura,
            t.nume AS nume_teren,
            SUM(r.unitati_estimate) AS total_estimate,
            SUM(r.unitati_recoltate) AS total_recoltate,
            CAST((SUM(r.unitati_recoltate) * 100.0 / NULLIF(SUM(r.unitati_estimate), 0)) AS INT) AS procent_productie,
			SUM(o.cost) AS cost_total
		FROM Recolte r
        JOIN Terenuri t ON r.id_teren = t.id_teren
        JOIN Culturi c ON r.id_cultura = c.id_cultura
		JOIN Operatiuni o ON o.id_teren = t.id_teren
        WHERE YEAR(r.data_recolta) = 2023
        GROUP BY c.nume, t.nume
    )
    SELECT 
        p.cultura,
        p.nume_teren,
        p.procent_productie,
        p.total_recoltate,
        p.total_estimate,
		p.cost_total
    FROM ProducțieMaximă p
    JOIN (
        SELECT cultura, MAX(procent_productie) AS max_procent
        FROM ProducțieMaximă
        GROUP BY cultura
    ) m ON p.cultura = m.cultura AND p.procent_productie = m.max_procent
    ORDER BY p.cultura;
END;
GO
