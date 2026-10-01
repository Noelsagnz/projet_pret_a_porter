/* controle client */

select distinct ville
FROM bronze_silver.stg_clients
order by ville;

SELECT
    id_client,
    ville,
    code_postal
FROM bronze_silver.stg_clients
WHERE id_client IN (77, 144, 175, 587, 2673);

--controle aprés nettoyage client (aucune ligne , donc ok pour les 2 requetes)
SELECT
    id_client,
    ville
FROM bronze_silver.stg_clients
WHERE ville <> TRIM(ville);

SELECT
    id_client,
    code_postal
FROM bronze_silver.stg_clients
WHERE code_postal !~ '^[0-9]{5}$';



/* controle commandes */
SELECT COUNT(*) AS nb_silver
FROM bronze_silver.stg_commandes;

SELECT COUNT(*) AS nb_rejets
FROM bronze_silver.rejets_commandes;

SELECT
    motif_rejet,
    COUNT(*) AS nombre
FROM bronze_silver.rejets_commandes
GROUP BY motif_rejet
ORDER BY nombre DESC;


/* controle ligne commande */
