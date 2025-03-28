USE FermaAgricolaDB;
GO

CREATE OR ALTER PROCEDURE RaportVanzariCalitate
AS
BEGIN
    -- CTE pentru a calcula calitatea pe baza prețului unitar de vânzare
    WITH CalitateCalculata AS (
        SELECT 
            c.nume AS cultura,
            v.nume_cumparator,
            v.cantitate_vanduta,
            v.castig,
            v.pret_unitar_vanzare / c.pret_unitar AS calitate,  -- Formula pentru calitate
            CASE  
                WHEN v.pret_unitar_vanzare / c.pret_unitar BETWEEN 0.1 AND 0.5 THEN 'Mediocra'
                WHEN v.pret_unitar_vanzare / c.pret_unitar > 0.5 AND v.pret_unitar_vanzare / c.pret_unitar <= 0.7 THEN 'Buna'
                WHEN v.pret_unitar_vanzare / c.pret_unitar > 0.7 AND v.pret_unitar_vanzare / c.pret_unitar <= 0.9 THEN 'Foarte Buna'
                WHEN v.pret_unitar_vanzare / c.pret_unitar > 0.9 AND v.pret_unitar_vanzare / c.pret_unitar <= 1 THEN 'Excelenta'
            END AS categorie_calitate
        FROM Vanzari v
        JOIN Stoc s ON v.id_stoc = s.id_stoc
        JOIN Culturi c ON s.id_cultura = c.id_cultura
        WHERE YEAR(v.data_vanzare) = 2024
    ),
    CastigPerCalitate AS (
        SELECT 
            c.cultura,
            c.categorie_calitate,
            SUM(c.castig) AS castig_total,
            SUM(c.cantitate_vanduta) AS cantitate_totala,
            CAST((SUM(c.castig) * 100.0 / NULLIF((SELECT SUM(castig) FROM CalitateCalculata WHERE cultura = c.cultura), 0)) AS INT) AS procent_din_vanzarile_culturii
        FROM CalitateCalculata c
        GROUP BY cultura, categorie_calitate
    ),
    CumparatoriPreferati AS (
        SELECT 
            cultura,
            categorie_calitate,
            nume_cumparator,
            SUM(cantitate_vanduta) AS cantitate_totala
        FROM CalitateCalculata
        GROUP BY cultura, categorie_calitate, nume_cumparator
    )
    SELECT 
        cpc.cultura,
        cpc.categorie_calitate,
        cpc.castig_total,
        cpc.procent_din_vanzarile_culturii,
        cp.nume_cumparator,
        cp.cantitate_totala
    FROM CastigPerCalitate cpc
    JOIN (
        SELECT cultura, categorie_calitate, MAX(cantitate_totala) AS max_cantitate
        FROM CumparatoriPreferati
        GROUP BY cultura, categorie_calitate
    ) max_cp ON cpc.cultura = max_cp.cultura AND cpc.categorie_calitate = max_cp.categorie_calitate
    JOIN CumparatoriPreferati cp ON cp.cultura = max_cp.cultura AND cp.categorie_calitate = max_cp.categorie_calitate AND cp.cantitate_totala = max_cp.max_cantitate
    ORDER BY cpc.cultura, cpc.categorie_calitate;
END;
GO