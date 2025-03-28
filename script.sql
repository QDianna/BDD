USE FermaAgricolaDB;

DROP TABLE IF EXISTS Operatiuni;
DROP TABLE IF EXISTS Vanzari;
DROP TABLE IF EXISTS Recolte;
DROP TABLE IF EXISTS Terenuri;
DROP TABLE IF EXISTS Stoc;
DROP TABLE IF EXISTS Culturi;

-- Tabela pentru Culturi
CREATE TABLE Culturi (
    id_cultura INT PRIMARY KEY IDENTITY(1,1),
    tip_cultura VARCHAR(50) NOT NULL CHECK (tip_cultura IN ('leguma', 'fruct', 'cereala', 'iarba_aromatica', 'floare')),
    nume VARCHAR(50) NOT NULL UNIQUE,
    durata_crestere FLOAT CHECK (durata_crestere > 0),
	pret_unitar FLOAT CHECK (pret_unitar > 0),
	unitati_per_hectar FLOAT CHECK (unitati_per_hectar > 0)
);

-- Tabela pentru Terenuri
CREATE TABLE Terenuri (
	id_teren INT PRIMARY KEY IDENTITY(1,1),
	id_cultura INT NULL,
	FOREIGN KEY (id_cultura) REFERENCES Culturi(id_cultura),
	data_plantare DATE NULL,
    data_estimativa_recoltare DATE NULL,
	nume VARCHAR(50) NOT NULL UNIQUE,
	locatie VARCHAR(50) NOT NULL,
	suprafata_hectare FLOAT CHECK (suprafata_hectare > 0)
);

-- Tabela pentru Operatiuni
CREATE TABLE Operatiuni (
    id_operatiune INT PRIMARY KEY IDENTITY(1,1),
	id_teren INT NOT NULL,
	FOREIGN KEY (id_teren) REFERENCES Terenuri(id_teren),
    id_cultura INT NULL,
    FOREIGN KEY (id_cultura) REFERENCES Culturi(id_cultura),
    tip_operatiune VARCHAR(50) NOT NULL CHECK (tip_operatiune IN ('arare', 'plantare', 'adaugare ingrasamant', 'adaugare pesticid', 'recoltare')),
    descriere VARCHAR(200),
    data_inceput DATE NOT NULL,
	data_final DATE NOT NULL,
	cost FLOAT CHECK (cost >= 0)
);

-- Tabela pentru Recolte
CREATE TABLE Recolte (
	id_recolta INT PRIMARY KEY IDENTITY(1,1),
	id_teren INT NOT NULL,
	FOREIGN KEY (id_teren) REFERENCES Terenuri(id_teren),
	id_cultura INT NOT NULL,
	FOREIGN KEY (id_cultura) REFERENCES Culturi(id_cultura),
	data_recolta DATE NOT NULL,
	unitati_estimate FLOAT CHECK (unitati_estimate > 0),
	unitati_recoltate FLOAT CHECK (unitati_recoltate >= 0),
    calitate FLOAT CHECK (calitate >= 0.1 AND calitate <= 1)
);

-- Tabela pentru Stoc
CREATE TABLE Stoc (
	id_stoc INT PRIMARY KEY IDENTITY(1,1),
	id_cultura INT NOT NULL,
	FOREIGN KEY (id_cultura) REFERENCES Culturi(id_cultura),
	calitate FLOAT CHECK (calitate >= 0.1 AND calitate <= 1),
	unitati_disponibile FLOAT CHECK (unitati_disponibile >= 0)
);

-- Tabela pentru Vanzari
CREATE TABLE Vanzari (
    id_vanzare INT PRIMARY KEY IDENTITY(1,1),
	id_stoc INT NOT NULL,
	FOREIGN KEY (id_stoc) REFERENCES Stoc(id_stoc),
	data_vanzare DATE NOT NULL CHECK (data_vanzare <= GETDATE()),
	nume_cumparator VARCHAR(50),
	pret_unitar_vanzare FLOAT CHECK (pret_unitar_vanzare > 0),
    cantitate_vanduta FLOAT CHECK (cantitate_vanduta > 0),
	castig AS (pret_unitar_vanzare * cantitate_vanduta) PERSISTED
);
GO

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

-- Populare tabelă Culturi
INSERT INTO Culturi (tip_cultura, nume, durata_crestere, pret_unitar, unitati_per_hectar)
VALUES 
('leguma', 'Rosii', 60, 2.5, 10000),
('leguma', 'Castraveti', 50, 2.2, 9000),
('fruct', 'Capsuni', 90, 5.0, 8000),
('fruct', 'Afine', 120, 8.5, 6000),
('cereala', 'Grau', 120, 1.2, 15000),
('cereala', 'Porumb', 100, 1.5, 14000),
('iarba_aromatica', 'Busuioc', 40, 3.5, 5000),
('iarba_aromatica', 'Oregano', 35, 3.8, 4500),
('floare', 'Trandafir', 80, 10.0, 2000),
('floare', 'Crin', 70, 9.5, 2200);


-- Populare tabelă Terenuri
INSERT INTO Terenuri (nume, locatie, suprafata_hectare)
VALUES 
('Afla', 'Zona A', 2.5),
('Bella', 'Zona B', 3.0),
('Crina', 'Zona C', 1.8),
('Dorna', 'Zona D', 4.0),
('Eterna', 'Zona E', 5.0),
('Fortuna', 'Zona F', 2.2),
('Gloria', 'Zona G', 3.5);
GO

-- Operatiuni - plantare si recoltare 2023
-- Teren Afla
INSERT INTO Operatiuni (id_teren, id_cultura, tip_operatiune, descriere, data_inceput, data_final, cost)
VALUES
(1, 1, 'arare', 'Arat pentru plantarea de rosii pe Teren A', '2023-02-25', '2023-02-26', 250),  -- Arat înainte de plantare
(1, 1, 'plantare', 'Plantare de rosii pe Teren A', '2023-03-01', '2023-03-02', 500),
(1, 1, 'recoltare', 'Recoltare de rosii pe Teren A', '2023-06-01', '2023-06-02', 600);

INSERT INTO Operatiuni (id_teren, id_cultura, tip_operatiune, descriere, data_inceput, data_final, cost)
VALUES
(1, 2, 'arare', 'Arat pentru plantarea de castraveti pe Teren A', '2023-07-25', '2023-07-26', 260),  -- Arat înainte de plantare
(1, 2, 'plantare', 'Plantare de castraveti pe Teren A', '2023-08-01', '2023-08-02', 600),
(1, 2, 'recoltare', 'Recoltare de castraveti pe Teren A', '2023-10-01', '2023-10-02', 700);

-- Teren Bella
INSERT INTO Operatiuni (id_teren, id_cultura, tip_operatiune, descriere, data_inceput, data_final, cost)
VALUES 
(2, 3, 'arare', 'Arat pentru plantarea de capsuni pe Teren B', '2023-03-25', '2023-03-26', 300),  -- Arat înainte de plantare
(2, 3, 'adaugare ingrasamant', 'Adaugare ingrasamant pentru capsuni pe Teren B', '2023-03-28', '2023-03-29', 450),
(2, 3, 'adaugare pesticid', 'Adaugare pesticid pentru capsuni pe Teren B', '2023-04-10', '2023-04-11', 360),
(2, 3, 'plantare', 'Plantare de capsuni pe Teren B', '2023-04-01', '2023-04-02', 800),
(2, 3, 'recoltare', 'Recoltare de capsuni pe Teren B', '2023-07-01', '2023-07-02', 1000);

INSERT INTO Operatiuni (id_teren, id_cultura, tip_operatiune, descriere, data_inceput, data_final, cost)
VALUES
(2, 5, 'arare', 'Arat pentru plantarea de grau pe Teren B', '2023-08-20', '2023-08-21', 320),  -- Arat înainte de plantare
(2, 5, 'adaugare ingrasamant', 'Adaugare ingrasamant pentru grau pe Teren B', '2023-08-25', '2023-08-26', 540),
(2, 5, 'adaugare pesticid', 'Adaugare pesticid pentru grau pe Teren B', '2023-09-10', '2023-09-11', 300),
(2, 5, 'plantare', 'Plantare de grau pe Teren B', '2023-09-01', '2023-09-02', 900),
(2, 5, 'recoltare', 'Recoltare de grau pe Teren B', '2023-12-01', '2023-12-02', 600);

-- Teren Crina
INSERT INTO Operatiuni (id_teren, id_cultura, tip_operatiune, descriere, data_inceput, data_final, cost)
VALUES 
(3, 7, 'arare', 'Arat pentru plantarea de busuioc pe Teren C', '2023-04-15', '2023-04-16', 180),  -- Arat înainte de plantare
(3, 7, 'adaugare ingrasamant', 'Adaugare ingrasamant pentru busuioc pe Teren C', '2023-04-20', '2023-04-21', 270),
(3, 7, 'plantare', 'Plantare de busuioc pe Teren C', '2023-05-01', '2023-05-02', 360),
(3, 7, 'recoltare', 'Recoltare de busuioc pe Teren C', '2023-07-15', '2023-07-16', 450);

INSERT INTO Operatiuni (id_teren, id_cultura, tip_operatiune, descriere, data_inceput, data_final, cost)
VALUES
(3, 9, 'arare', 'Arat pentru plantarea de trandafiri pe Teren C', '2023-08-10', '2023-08-11', 200),  -- Arat înainte de plantare
(3, 9, 'adaugare ingrasamant', 'Adaugare ingrasamant pentru trandafiri pe Teren C', '2023-08-20', '2023-08-21', 360),
(3, 9, 'plantare', 'Plantare de trandafiri pe Teren C', '2023-09-15', '2023-09-16', 900),
(3, 9, 'recoltare', 'Recoltare de trandafiri pe Teren C', '2023-12-15', '2023-12-16', 1100);

-- Teren Dorna: operatiuni intense - productivitate proasta
INSERT INTO Operatiuni (id_teren, id_cultura, tip_operatiune, descriere, data_inceput, data_final, cost)
VALUES
(4, 1, 'arare', 'Arat pentru plantarea de rosii pe Teren D', '2023-03-01', '2023-03-02', 400),
(4, 1, 'adaugare ingrasamant', 'Adaugare ingrasamant pentru rosii pe Teren D', '2023-03-03', '2023-03-04', 600),
(4, 1, 'adaugare pesticid', 'Adaugare pesticid pentru rosii pe Teren D', '2023-03-10', '2023-03-11', 480),
(4, 1, 'plantare', 'Plantare de rosii pe Teren D', '2023-03-15', '2023-03-16', 1000),
(4, 1, 'recoltare', 'Recoltare de rosii pe Teren D', '2023-06-20', '2023-06-21', 1200);

INSERT INTO Operatiuni (id_teren, id_cultura, tip_operatiune, descriere, data_inceput, data_final, cost)
VALUES
(4, 2, 'arare', 'Arat pentru plantarea de castraveti pe Teren D', '2023-08-01', '2023-08-02', 420),
(4, 2, 'adaugare ingrasamant', 'Adaugare ingrasamant pentru castraveti pe Teren D', '2023-08-03', '2023-08-04', 680),
(4, 2, 'plantare', 'Plantare de castraveti pe Teren D', '2023-08-15', '2023-08-16', 1040),
(4, 2, 'recoltare', 'Recoltare de castraveti pe Teren D', '2023-10-20', '2023-10-21', 1400);

-- Teren Eterna: operatiuni minime - productivitate buna
INSERT INTO Operatiuni (id_teren, id_cultura, tip_operatiune, descriere, data_inceput, data_final, cost)
VALUES
(5, 1, 'arare', 'Arat pentru plantarea de rosii pe Teren E', '2023-03-01', '2023-03-02', 500),
(5, 1, 'plantare', 'Plantare de rosii pe Teren E', '2023-03-05', '2023-03-06', 1000),
(5, 1, 'recoltare', 'Recoltare de rosii pe Teren E', '2023-06-10', '2023-06-11', 1500);

INSERT INTO Operatiuni (id_teren, id_cultura, tip_operatiune, descriere, data_inceput, data_final, cost)
VALUES
(5, 2, 'arare', 'Arat pentru plantarea de castraveti pe Teren E', '2023-07-01', '2023-07-02', 550),
(5, 2, 'plantare', 'Plantare de castraveti pe Teren E', '2023-07-05', '2023-07-06', 1050),
(5, 2, 'recoltare', 'Recoltare de castraveti pe Teren E', '2023-10-05', '2023-10-06', 1600);



-- Actualizare tabela Recoltare (popularea s-a facut automat pentru fiecare
-- operatiune de recoltare, se actualizeaza doar unitatile recoltate si calitatea)
UPDATE Recolte SET unitati_recoltate = 22600, calitate = 0.88 WHERE id_teren = 1 AND data_recolta = '2023-06-02';
UPDATE Recolte SET unitati_recoltate = 19900, calitate = 0.82 WHERE id_teren = 1 AND data_recolta = '2023-10-02';
UPDATE Recolte SET unitati_recoltate = 24900, calitate = 0.85 WHERE id_teren = 2 AND data_recolta = '2023-07-02';
UPDATE Recolte SET unitati_recoltate = 45500, calitate = 0.95 WHERE id_teren = 2 AND data_recolta = '2023-12-02';
UPDATE Recolte SET unitati_recoltate = 8000, calitate = 0.88 WHERE id_teren = 3 AND data_recolta = '2023-07-16';
UPDATE Recolte SET unitati_recoltate = 3550, calitate = 0.94 WHERE id_teren = 3 AND data_recolta = '2023-12-16';

-- Teren Dorna: operatiuni intense - productivitate proasta
UPDATE Recolte 
SET unitati_recoltate = 34000, calitate = 0.78
WHERE id_teren = 4 AND data_recolta = '2023-10-21';
UPDATE Recolte 
SET unitati_recoltate = 30000, calitate = 0.86 
WHERE id_teren = 4 AND data_recolta = '2023-06-21';

-- Teren Eterna: operatiuni minime - productivitate buna
UPDATE Recolte 
SET unitati_recoltate = 48800, calitate = 0.95 
WHERE id_teren = 5 AND data_recolta = '2023-06-11';
UPDATE Recolte 
SET unitati_recoltate = 46000, calitate = 0.93 
WHERE id_teren = 5 AND data_recolta = '2023-10-06';


-- Vânzări din stoc pentru 2024
-- Rosii (0.88)
INSERT INTO Vanzari (id_stoc, data_vanzare, nume_cumparator, cantitate_vanduta)
VALUES 
(1, '2024-02-10', 'FarmPlus', 4000),
(1, '2024-03-05', 'AgriCorp', 3200),
(1, '2024-04-15', 'GreenHarvest', 5000);

-- Castraveti (0.82)
INSERT INTO Vanzari (id_stoc, data_vanzare, nume_cumparator, cantitate_vanduta)
VALUES 
(2, '2024-01-20', 'EcoFresh', 3000),
(2, '2024-03-10', 'HealthyFoods', 4500),
(2, '2024-05-01', 'FarmFresh', 2000);

-- Capsuni (0.85)
INSERT INTO Vanzari (id_stoc, data_vanzare, nume_cumparator, cantitate_vanduta)
VALUES 
(3, '2024-03-01', 'FruitLand', 6000),
(3, '2024-04-12', 'BioMarket', 5000),
(3, '2024-06-20', 'HealthFarm', 8000);

-- Grau (0.95)
INSERT INTO Vanzari (id_stoc, data_vanzare, nume_cumparator, cantitate_vanduta)
VALUES 
(4, '2024-02-05', 'Harvesters', 12000),
(4, '2024-03-25', 'WholeFarm', 10000),
(4, '2024-05-30', 'FarmSupply', 9000);

-- Busuioc (0.88)
INSERT INTO Vanzari (id_stoc, data_vanzare, nume_cumparator, cantitate_vanduta)
VALUES 
(5, '2024-02-22', 'SpiceGarden', 2000),
(5, '2024-04-10', 'HerbalStore', 2500),
(5, '2024-06-05', 'HealthyKitchen', 1500);

-- Trandafir (0.94)
INSERT INTO Vanzari (id_stoc, data_vanzare, nume_cumparator, cantitate_vanduta)
VALUES 
(6, '2024-01-25', 'FloraDecor', 1200),
(6, '2024-04-18', 'BloomCraft', 1800),
(6, '2024-06-30', 'FlowerBoutique', 1300);

-- Castraveti (0.78)
INSERT INTO Vanzari (id_stoc, data_vanzare, nume_cumparator, cantitate_vanduta)
VALUES 
(7, '2024-03-08', 'FreshMart', 7000),
(7, '2024-05-12', 'GreenFields', 6500),
(7, '2024-06-28', 'BioNature', 6000);

-- Rosii (0.86)
INSERT INTO Vanzari (id_stoc, data_vanzare, nume_cumparator, cantitate_vanduta)
VALUES 
(8, '2024-02-20', 'VeggieDelight', 5000),
(8, '2024-04-01', 'FarmToTable', 6000),
(8, '2024-06-10', 'OrganicTaste', 8000);

-- Rosii (0.95)
INSERT INTO Vanzari (id_stoc, data_vanzare, nume_cumparator, cantitate_vanduta)
VALUES 
(9, '2024-01-18', 'HarvestHome', 15000),
(9, '2024-03-22', 'LocalHarvest', 12000),
(9, '2024-05-05', 'HealthyHarvest', 13000);

-- Castraveti (0.93)
INSERT INTO Vanzari (id_stoc, data_vanzare, nume_cumparator, cantitate_vanduta)
VALUES 
(10, '2024-03-30', 'EcoVeggies', 14000),
(10, '2024-05-10', 'NatureFoods', 13000),
(10, '2024-06-25', 'PureHarvest', 12000);
GO

