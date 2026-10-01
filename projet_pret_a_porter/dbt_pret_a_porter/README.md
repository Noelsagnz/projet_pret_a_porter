# Projet prêt-à-porter

Projet de pipeline analytique pour une boutique e-commerce de prêt-à-porter. Il transforme les données de vente dans PostgreSQL selon une architecture médaillon **Bronze → Silver → Gold**, contrôle leur qualité et prépare des indicateurs destinés à l’analyse métier et au reporting Power BI.

## Architecture

```text
Scripts SQL
    │
    ▼
PostgreSQL · bronze
    │
    ├── dbt staging : nettoyage et filtrage → silver
    ├── dbt rejets  : lignes écartées et motif → silver
    └── dbt gold    : dimensions et faits → gold
             │
             └── KPI et rapport Power BI

Airflow orchestre les contrôles Bronze, les exécutions dbt,
les tests de qualité et l'archivage des journaux.
```

| Couche | Contenu |
| --- | --- |
| **Bronze** | Données sources chargées telles quelles dans `bronze` : clients, commandes, lignes de commande, produits et retours. |
| **Silver** | Modèles `stg_*` nettoyés, ainsi que `rejets_commandes` et `rejets_retours` pour tracer les enregistrements écartés et leurs motifs. |
| **Gold** | Dimensions `dim_client`, `dim_date`, `dim_produit` et tables de faits `fact_commande`, `fact_ligne_commande`, `fact_retour`. |

Les modèles Silver sont configurés en vues et les modèles Gold en tables dans `dbt_projet/dbt_project.yml`.

## Contenu du dépôt

- `Database/boutique_pret_a_porter_bronze.sql` : création et alimentation des tables Bronze de la base initiale.
- `Database/boutique_pret_a_porter_increment_2026.sql` : lot additionnel de données, à appliquer après le script initial.
- `dbt_projet/` : projet dbt, sources, modèles Silver/Gold, tests, analyses et requêtes KPI.
- `dag_bronze_silver_gold.py` : DAG Airflow planifié quotidiennement.
- `load_tables.py`, `load_tables_corrige_.py`, `load_tables_metadata.py` : scripts d’inspection des tables Bronze avec pandas et SQLAlchemy.
- `Query_sql/` : requêtes de profilage et contrôles SQL.
- `Noel_rapport_pret_a_porter.pbix` : rapport Power BI.
- Les documents Word, PDF et PowerPoint contiennent des supports et éléments de présentation du projet.

## Prérequis

- PostgreSQL, avec `psql` ou pgAdmin pour exécuter les scripts SQL.
- Python 3 et les bibliothèques utilisées par les scripts (`pandas`, `SQLAlchemy`, `psycopg2`).
- dbt Core et l’adaptateur PostgreSQL `dbt-postgres`.
- Apache Airflow pour l’orchestration ; son installation est facultative pour exécuter dbt manuellement.

Aucun fichier de dépendances Python (`requirements.txt`) n’est fourni actuellement. Les environnements virtuels présents dans le dépôt sont spécifiques à la machine et ne remplacent pas une liste de dépendances reproductible.

## Installation et préparation des données

1. Créer une base PostgreSQL, puis exécuter `Database/boutique_pret_a_porter_bronze.sql` sur cette base. Le script crée le schéma `bronze`, ses cinq tables et les données initiales. **Attention : il contient des `DROP TABLE ... CASCADE` et réinitialise les tables Bronze.**
2. Pour ajouter le lot incrémental, exécuter `Database/boutique_pret_a_porter_increment_2026.sql` après le chargement initial. Ce script ajoute des lignes ; il n’est pas rejouable tel quel, car les clés déjà insérées provoqueront des conflits.
3. Configurer les connexions PostgreSQL et dbt avant de lancer les traitements.

### Harmoniser le nom de la base

Les fichiers du dépôt utilisent plusieurs noms de base (`pret_porter`, `pret_a_porter` et `boutique_pret_a_porter`). Avant l’exécution, choisir un nom unique et l’appliquer partout où il est configuré :

- `dbt_projet/models/staging/_sources.yml` (`database` de la source Bronze) ;
- `dbt_projet/profiles.yml` dans le fichier utilisateur `~/.dbt/profiles.yml` ;
- les paramètres de connexion dans les scripts Python ;
- les paramètres du DAG Airflow.

Le script SQL initial indique `pret_porter` dans ses instructions de création de base. Vérifier également que l’utilisateur PostgreSQL choisi a accès à cette base.

### Profil dbt PostgreSQL

Le profil déclaré par le projet s’appelle `dbt_projet`. Créer `~/.dbt/profiles.yml` (sur Windows : `%USERPROFILE%\.dbt\profiles.yml`) avec les paramètres de votre environnement. Exemple utilisant des variables d’environnement pour éviter d’écrire un mot de passe dans le dépôt :

```yaml
dbt_projet:
  target: dev
  outputs:
    dev:
      type: postgres
      host: "{{ env_var('PGHOST', 'localhost') }}"
      user: "{{ env_var('PGUSER') }}"
      password: "{{ env_var('PGPASSWORD') }}"
      port: "{{ env_var('PGPORT', '5432') | int }}"
      dbname: "{{ env_var('PGDATABASE') }}"
      schema: public
      threads: 4
```

Définir `PGUSER`, `PGPASSWORD` et `PGDATABASE` dans l’environnement avant les commandes dbt. `PGHOST` et `PGPORT` sont facultatives si leurs valeurs par défaut conviennent. Ne pas committer de mot de passe ni de fichier `profiles.yml` contenant des secrets.

## Exécuter dbt

Depuis le dossier `dbt_projet` :

```bash
cd dbt_projet

dbt debug --profiles-dir "${HOME}/.dbt"
dbt run --select staging --profiles-dir "${HOME}/.dbt"
dbt test --profiles-dir "${HOME}/.dbt"
dbt run --select gold --profiles-dir "${HOME}/.dbt"
```

Sous Windows PowerShell, remplacer le chemin du profil par `$HOME\.dbt`. Pour construire tous les modèles et lancer leurs tests dbt dans l’ordre des dépendances, utiliser :

```bash
dbt build --profiles-dir "${HOME}/.dbt"
```

Les tests définis dans `dbt_projet/models/schema.yml` contrôlent notamment la présence et l’unicité des identifiants des modèles staging.

## Orchestration Airflow

Le DAG `pipeline_bronze_silver_gold` suit l’ordre suivant :

1. vérifier que les cinq tables Bronze existent et contiennent des lignes ;
2. construire les modèles staging ;
3. exécuter les tests dbt ;
4. construire les modèles Gold ;
5. archiver les informations d’exécution.

Le DAG est configuré avec une planification quotidienne (`@daily`). Il s’appuie sur `psql`, la variable d’environnement `PGPASSWORD`, dbt et un répertoire d’archives. **Ses chemins dbt et ses répertoires sont actuellement codés en dur pour une configuration Linux/WSL particulière** : les adapter à l’installation locale avant de déclarer ou lancer le DAG. La tâche `ingest_bronze` vérifie les tables déjà présentes ; elle ne charge pas les fichiers SQL dans PostgreSQL.

## Contrôles et indicateurs

Les modèles staging harmonisent certains champs (espaces, casse, tailles et valeurs manquantes) et excluent les commandes ou retours invalides. Les lignes écartées sont consultables dans les modèles `rejets_*`.

Les requêtes dbt et SQL couvrent notamment :

- la réconciliation des volumes entre Bronze, Silver, Gold et les rejets ;
- le chiffre d’affaires, les quantités vendues et la marge brute ;
- les frais de livraison, codes promotionnels, remises et paiements en 3 fois ;
- la cohérence des dates de livraison et des montants remboursés.

La synthèse de contrôles existante est dans `dbt_projet/analyses/synthese_controles.md`. Elle documente des anomalies métier présentes dans les données analysées ; celles-ci ne signifient pas nécessairement que la construction dbt est en échec.

## Scripts Python

Les scripts `load_tables*.py` se connectent à PostgreSQL et lisent les tables Bronze dans des DataFrames pandas. Le script `load_tables_metadata.py` ajoute `date_chargement` et `source` aux DataFrames en mémoire. Ces scripts ne matérialisent pas eux-mêmes une nouvelle couche dans la base. Vérifier leur configuration avant exécution : les noms de base et les valeurs de connexion y sont codés en dur et ne sont pas uniformes.

## Arborescence simplifiée

```text
projet_pret_a_porter/
├── Database/
├── Query_sql/
├── dbt_projet/
│   ├── analyses/
│   ├── macros/
│   ├── models/
│   │   ├── gold/
│   │   └── staging/
│   └── tests/
├── dag_bronze_silver_gold.py
├── load_tables.py
├── load_tables_corrige_.py
└── load_tables_metadata.py
```
