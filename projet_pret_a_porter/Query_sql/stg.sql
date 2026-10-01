-- Vérification de la création des tables staging
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name = 'stg_clients';

SELECT *
FROM bronze.stg_clients
LIMIT 5;

SELECT *
FROM bronze.stg_commandes
LIMIT 5;

SELECT *
FROM bronze.stg_lignes_commande
LIMIT 5;

SELECT *
FROM bronze.stg_produits
LIMIT 5;

SELECT *
FROM bronze.stg_retours
LIMIT 5;