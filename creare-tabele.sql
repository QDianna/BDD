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

