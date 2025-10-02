# Farm Management App - SQL Database Structure

Acest proiect simulează o aplicație de **management agricol** pe bază de date relaționale și rapoarte vizuale.  
Include atât **scripturi SQL** pentru structură și logică de business (triggers, proceduri stocate), cât și o aplicație **Python** care generează rapoarte grafice pe baza datelor.
Proiect realizat pentru cursul **Baze de Date Distribuite**, folosind **SSMS**.
---

## Structura proiectului

- **SQL**
  - `creare-tabele.sql` – creează toate tabelele bazei de date
  - `populare-tabele.sql` – inserează date care simulează un flux real
  - `TRG-plantare-teren.sql` – trigger pentru înregistrarea operațiunilor de plantare
  - `TRG-recoltare-teren.sql` – trigger pentru recoltări pe terenuri
  - `TRG-recoltare-stoc.sql` – trigger pentru actualizarea stocului la recoltare
  - `TRG-vanzare-stoc.sql` – trigger pentru actualizarea stocului la vânzare
  - `TRG-pret-vanzare.sql` – trigger pentru calculul prețurilor de vânzare
  - `raport-complex-4.sql` – procedură `RaportPerformanteTerenuri`
  - `raport-complex-6.sql` – procedură `RaportPerformanteCulturi`
  - `raport-complex-7.sql` – procedură `RaportVanzariCalitate`
  - `script.sql` – script master care rulează toate scripturile de inițializare

- **Python**
  - `main.py` – aplicația care se conectează la baza de date și generează rapoarte grafice
  - Utilizează `pyodbc`, `matplotlib` și `numpy`

---

## Funcționalități principale

- Bază de date cu tabele pentru **terenuri, culturi, operațiuni, recoltări, vânzări, stocuri**  
- Triggere pentru:
  - actualizarea stocurilor la recoltări și vânzări
  - validarea prețurilor de vânzare
  - corelarea operațiunilor cu terenurile
- Proceduri stocate pentru rapoarte complexe:
  - **Performanța terenurilor** (producție vs. întreținere)
  - **Performanța culturilor** (producție vs. costuri)
  - **Vânzări pe categorii de calitate** (procente și cumpărători principali)
- Aplicație Python pentru vizualizări grafice interactive pe baza datelor din rapoarte

---

## Setup

1. **Pornește SQL Server (Docker sau local).**  
   Conectează-te cu un client SQL (ex: SSMS).  

2. **Inițializează baza de date:**  
   Rulează scriptul:
   ```sql
   script.sql
   
3. **Rulează aplicația Python:**
   ```bash
   pip install pyodbc matplotlib numpy
   python main.py

