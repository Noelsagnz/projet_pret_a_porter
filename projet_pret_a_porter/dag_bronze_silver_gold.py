
from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path
import os
import subprocess

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator


# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

DB_HOST = "172.29.128.1"
DB_PORT = "5432"
DB_NAME = "pret_a_porter"
DB_USER = "postgres"

DBT_PROJECT_DIR = "/mnt/c/Users/GK/Documents/Noel/Jour7jour8/projet_etl/dbt_projet"
DBT_EXECUTABLE = "/home/gk/dbt_venv/bin/dbt"
DBT_PROFILES_DIR = "/home/gk/.dbt"

ARCHIVE_DIR = "/home/gk/airflow/archives/quality_reports"

BRONZE_TABLES = [
    "clients",
    "commandes",
    "lignes_commande",
    "produits",
    "retours",
]


default_args = {
    "owner": "formation_cgi",
    "retries": 2,
    "retry_delay": timedelta(minutes=2),
}


# -------------------------------------------------------------------
# 1. Vérification Bronze
# -------------------------------------------------------------------

def check_bronze():
    """Vérifie que les 5 tables Bronze existent et contiennent des données."""

    password = os.environ.get("PGPASSWORD")

    if not password:
        raise RuntimeError(
            "La variable d'environnement PGPASSWORD n'est pas définie."
        )

    for table in BRONZE_TABLES:

        query = (
            "SELECT COUNT(*) "
            f"FROM bronze.{table};"
        )

        result = subprocess.run(
            [
                "psql",
                "-h", DB_HOST,
                "-p", DB_PORT,
                "-U", DB_USER,
                "-d", DB_NAME,
                "-t",
                "-A",
                "-c", query,
            ],
            env={**os.environ, "PGPASSWORD": password},
            capture_output=True,
            encoding="utf-8",
            errors="replace",
            text=True,
            check=True,
        )

        count = int(result.stdout.strip())

        if count == 0:
            raise RuntimeError(
                f"La table bronze.{table} est vide."
            )

        print(f"bronze.{table} : {count} lignes")


# -------------------------------------------------------------------
# DAG
# -------------------------------------------------------------------

with DAG(
    dag_id="pipeline_bronze_silver_gold",
    default_args=default_args,
    description="Pipeline Bronze -> Silver -> Tests qualité -> Gold -> Archivage",
    schedule="@daily",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["formation", "medaillon", "dbt"],
) as dag:

    # 1. Bronze
    ingest_bronze = PythonOperator(
        task_id="ingest_bronze",
        python_callable=check_bronze,
    )

    # 2. Silver
    dbt_silver = BashOperator(
        task_id="dbt_silver",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"{DBT_EXECUTABLE} run "
            f"--select staging "
            f"--profiles-dir {DBT_PROFILES_DIR}"
        ),
    )

    # 3. Tests qualité
    tests_qualite = BashOperator(
        task_id="tests_qualite",
        bash_command="""
        set -o pipefail

        ARCHIVE_RUN="{{ ts_nodash }}"
        ARCHIVE_PATH="/home/gk/airflow/archives/quality_reports/${ARCHIVE_RUN}"

        mkdir -p "${ARCHIVE_PATH}"

        cd "/mnt/c/Users/GK/Documents/Noel/Jour7jour8/projet_etl/dbt_projet"

        /home/gk/dbt_venv/bin/dbt test \
          --profiles-dir /home/gk/.dbt \
          2>&1 | tee "${ARCHIVE_PATH}/dbt_test.log"

        exit ${PIPESTATUS[0]}
        """,
    )

    # 4. Gold
    dbt_gold = BashOperator(
        task_id="dbt_gold",
        bash_command=(
            f"cd {DBT_PROJECT_DIR} && "
            f"{DBT_EXECUTABLE} run "
            f"--select gold "
            f"--profiles-dir {DBT_PROFILES_DIR}"
        ),
    )

    # 5. Archivage
    def archivage_rapports(**context):
        """Archive les informations de l'exécution."""

        archive_run = context["ts_nodash"]
        archive_path = Path(ARCHIVE_DIR) / archive_run
        archive_path.mkdir(parents=True, exist_ok=True)

        run_info = archive_path / "run_info.txt"

        run_info.write_text(
            f"DAG : {context['dag'].dag_id}\n"
            f"Run ID : {context['run_id']}\n"
            f"Date : {context['ts']}\n"
            f"Tests qualité : exécutés\n",
            encoding="utf-8",
        )

        print(f"Rapport archivé dans : {archive_path}")

    archivage = PythonOperator(
        task_id="archivage_rapports",
        python_callable=archivage_rapports,
        trigger_rule="all_done",
    )

    # ----------------------------------------------------------------
    # Dépendances
    # ----------------------------------------------------------------

    ingest_bronze >> dbt_silver >> tests_qualite >> dbt_gold

    [tests_qualite, dbt_gold] >> archivage