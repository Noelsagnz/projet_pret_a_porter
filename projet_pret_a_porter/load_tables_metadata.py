from datetime import datetime

import pandas as pd
from sqlalchemy import create_engine

# =========================
# PARAMÈTRES
# =========================
DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "database": "pret_porter",   # nom de la base créée dans PostgreSQL
    "user": "postgres",
    "password": "MOT_DE_PASSE",  # à remplacer
}

SCHEMA = "bronze"                # schéma où se trouvent les tables
SOURCE = "boutique_pret_a_porter.sql"   # nom de la source à tracer

TABLES = [
    "clients",
    "produits",
    "commandes",
    "lignes_commande",
    "retours",
]

# =========================
# CONNEXION POSTGRESQL
# =========================
engine = create_engine(
    f"postgresql+psycopg2://{DB_CONFIG['user']}:{DB_CONFIG['password']}"
    f"@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"
)

# =========================
# CHARGEMENT DES TABLES
# =========================
# Une seule date pour tout le lot : toutes les tables ont le même horodatage
date_chargement = datetime.now()

dataframes = {}

for table in TABLES:
    try:
        df = pd.read_sql_table(table, engine, schema=SCHEMA)

        # Colonnes techniques ajoutées à chaque table
        df["date_chargement"] = date_chargement
        df["source"] = SOURCE

        dataframes[table] = df
        print(f"OK  {table}: {len(df)} lignes, {df.shape[1]} colonnes")
    except Exception as e:
        print(f"ERREUR {table}: {e}")

print(f"\n{len(dataframes)}/{len(TABLES)} tables chargées")

# Contrôle : les 2 dernières colonnes de chaque table
for table, df in dataframes.items():
    print(f"\n{table}")
    print(df[["date_chargement", "source"]].head(2))
