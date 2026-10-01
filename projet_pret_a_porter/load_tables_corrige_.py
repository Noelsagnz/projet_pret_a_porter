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
    "password": "CGI2026",  # à remplacer
}

SCHEMA = "bronze"                # schéma où se trouvent les tables

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
dataframes = {}

for table in TABLES:
    try:
        df = pd.read_sql_table(table, engine, schema=SCHEMA)
        dataframes[table] = df
        print(f"OK  {table}: {len(df)} lignes, {df.shape[1]} colonnes")
    except Exception as e:
        print(f"ERREUR {table}: {e}")

print(f"\n{len(dataframes)}/{len(TABLES)} tables chargées")
