import pyodbc
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import matplotlib.colors as colors
import numpy as np


class MSSQLConnection:
    def __init__(self):
        self.host = 'localhost,1434'
        self.database = 'FermaAgricolaDB'
        self.username = 'sa'
        self.password = '04Art3mis11!'

    def openConnection(self):
        try:
            self.db = pyodbc.connect(
                f"DRIVER={{ODBC Driver 17 for SQL Server}};"
                f"SERVER={self.host};"
                f"DATABASE={self.database};"
                f"UID={self.username};"
                f"PWD={self.password};"
                "TrustServerCertificate=yes;"
            )
            self.cursor = self.db.cursor()
            print("Connection open!")

        except Exception as e:
            print("Connection not open!")
            print(e)

    def closeConnection(self):
        try:
            self.cursor.close()
            self.db.close()
            print("Connection closed!")

        except Exception as e:
            print("Connection not closed!")
            print(e)

    # raport complex 4 - operatiuni x calitate si cantitate de productie pe terenuri
    def getRaportPerformanteTerenuri(self):
        try:
            cmd = "EXEC RaportPerformanteTerenuri;"
            self.cursor.execute(cmd)
            rows = self.cursor.fetchall()
            return rows
        
        except Exception as e:
            print(e)
            return []

    # raport complex 6 - culturi x terenuri cu productie maxima + costurile operationale 
    def getRaportPerformanteCulturi(self):
        try:
            cmd = "EXEC RaportPerformanteCulturi;"
            self.cursor.execute(cmd)
            rows = self.cursor.fetchall()
            return rows
        
        except Exception as e:
            print(e)
            return []

    # raport complex 7 - culturi x procente de vanzari si cumparatori favoriti per categorii de calitate
    def getRaportVanzariCalitate(self):
        try:
            cmd = "EXEC RaportVanzariCalitate;"
            self.cursor.execute(cmd)
            rows = self.cursor.fetchall()
            return rows
        
        except Exception as e:
            print(e)
            return []


# grafic pentru raport complex 4
def plotRaportPerformanteTerenuri(data):
    terenuri = [row[0] for row in data]
    procente_productie = [row[3] for row in data]
    operatiuni = [row[4] for row in data]
    calitati_medii = [row[2] for row in data]

    plt.figure(figsize=(10, 6))
    scatter = plt.scatter(operatiuni, procente_productie, s=[c * 500 for c in calitati_medii], alpha=0.7, c=calitati_medii, cmap="viridis")
    plt.colorbar(scatter, label="Calitate medie")
    plt.xlabel("Număr operațiuni de întreținere")
    plt.ylabel("Procent producție (%)")
    plt.title("Performanța terenurilor (producție și întreținere)")
    plt.grid(True)

    for i, txt in enumerate(terenuri):
        plt.annotate(txt, (operatiuni[i], procente_productie[i]), fontsize=8, ha='right')

    plt.tight_layout()
    plt.show()


# grafic pentru raport complex 6
def plotRaportPerformanteCulturi(data):
    culturi = [f"{row[0]} ({row[1]})" for row in data]  # Cultura și terenul
    procente_productie = [row[2] for row in data]  # Procent producție
    costuri_total = np.array([row[5] for row in data], dtype=float)  # Convertire la array de tip float pentru normalizare

    plt.figure(figsize=(12, 8))
    
    # Normalizare pentru culori între 0 și 1
    norm = colors.Normalize(vmin=costuri_total.min(), vmax=costuri_total.max())
    sm = cm.ScalarMappable(norm=norm, cmap="coolwarm")
    sm.set_array([])  # Evităm erori ulterioare legate de array-ul mappable
    
    # Creare bar chart vertical
    bars = plt.bar(culturi, procente_productie, color=sm.to_rgba(costuri_total))
    plt.colorbar(sm, label="Cost total operațiuni (lei)")
    plt.ylabel("Procent producție (%)")
    plt.xlabel("Cultură și teren")
    plt.xticks(rotation=45, ha='right')  # Rotirea etichetelor pentru a fi mai lizibile
    plt.title("Procentul de producție în funcție de costul de producție")
    plt.tight_layout()

    for bar, cost in zip(bars, costuri_total):
        plt.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 1, f"{int(cost)} lei", va='bottom', ha='center')

    plt.show()


# grafic pentru raport complex 7
def plotRaportVanzariCalitate(data):
    categorii_calitate = [f"{row[0]} ({row[1]})" for row in data]  # Cultura și categoria de calitate
    procente_vanzari = [row[3] for row in data]  # Procentul din vânzările culturii (%)
    castiguri_totale = [row[2] for row in data]  # Câștig total (lei)
    cumparatori_principali = [row[4] for row in data]  # Cumpărătorul principal

    plt.figure(figsize=(12, 8))

    # Normalizare câștiguri pentru bara de culoare
    norm = plt.Normalize(min(castiguri_totale), max(castiguri_totale))
    colors = plt.cm.coolwarm(norm(castiguri_totale))
    sm = plt.cm.ScalarMappable(cmap="coolwarm", norm=norm)
    sm.set_array([])

    # Creare bar chart vertical
    bars = plt.bar(categorii_calitate, procente_vanzari, color=colors)
    plt.colorbar(sm, label="Câștig total (lei)")
    plt.ylabel("Procent din vânzările culturii (%)")
    plt.xlabel("Cultură (Categorie Calitate)")
    plt.title("Procentul din vânzările culturii și câștigul total per categorie de calitate")
    plt.xticks(rotation=45, ha='right')

    # Afișare etichete cu cumpărătorul principal
    for bar, cumparator, procent in zip(bars, cumparatori_principali, procente_vanzari):
        plt.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height() + 0.5,
            cumparator,
            ha='center',
            va='bottom',
            fontsize=9
        )

    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    conn = MSSQLConnection()
    conn.openConnection()

    # raport complex 4
    data = conn.getRaportPerformanteTerenuri()
    if data:
        plotRaportPerformanteTerenuri(data)
    else:
        print("Nu s-au găsit date pentru raport.")
    
    # raport complex 6
    data = conn.getRaportPerformanteCulturi()
    if data:
        plotRaportPerformanteCulturi(data)
    else:
        print("Nu s-au găsit date pentru raport.")

    # raport complex 7
    data = conn.getRaportVanzariCalitate()
    if data:
        plotRaportVanzariCalitate(data)
    else:
        print("Nu s-au găsit date pentru raport.")

    conn.closeConnection()

