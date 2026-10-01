/* =========================================================
   CONTRÔLES DES INDICATEURS CLÉS
   Cohérence Bronze → Silver → Gold
   ========================================================= */


/* =========================================================
   1. CONTRÔLE DES VOLUMES
   ========================================================= */

SELECT
    'clients' AS objet,
    (SELECT COUNT(*) FROM bronze.clients) AS bronze,
    (SELECT COUNT(*) FROM silver.stg_clients) AS silver,
    (SELECT COUNT(*) FROM gold.dim_client) AS gold

UNION ALL

SELECT
    'commandes',
    (SELECT COUNT(*) FROM bronze.commandes),
    (SELECT COUNT(*) FROM silver.stg_commandes),
    (SELECT COUNT(*) FROM gold.fact_commande)

UNION ALL

SELECT
    'lignes_commande',
    (SELECT COUNT(*) FROM bronze.lignes_commande),
    (SELECT COUNT(*) FROM silver.stg_lignes_commande),
    (SELECT COUNT(*) FROM gold.fact_ligne_commande)

UNION ALL

SELECT
    'produits',
    (SELECT COUNT(*) FROM bronze.produits),
    (SELECT COUNT(*) FROM silver.stg_produits),
    (SELECT COUNT(*) FROM gold.dim_produit)

UNION ALL

SELECT
    'retours',
    (SELECT COUNT(*) FROM bronze.retours),
    (SELECT COUNT(*) FROM silver.stg_retours),
    (SELECT COUNT(*) FROM gold.fact_retour);


/* =========================================================
   2. RÉCONCILIATION DES REJETS
   Bronze = Silver + Rejets
   ========================================================= */

SELECT
    'commandes' AS objet,
    (SELECT COUNT(*) FROM bronze.commandes) AS bronze,
    (SELECT COUNT(*) FROM silver.stg_commandes) AS silver,
    (SELECT COUNT(*) FROM silver.rejets_commandes) AS rejets,
    (SELECT COUNT(*) FROM silver.stg_commandes)
        + (SELECT COUNT(*) FROM silver.rejets_commandes)
        AS silver_plus_rejets

UNION ALL

SELECT
    'retours',
    (SELECT COUNT(*) FROM bronze.retours),
    (SELECT COUNT(*) FROM silver.stg_retours),
    (SELECT COUNT(*) FROM silver.rejets_retours),
    (SELECT COUNT(*) FROM silver.stg_retours)
        + (SELECT COUNT(*) FROM silver.rejets_retours);


/* =========================================================
   3. CONTRÔLE DU CHIFFRE D'AFFAIRES
   Bronze = Silver = Gold
   ========================================================= */

SELECT
    ROUND(
        (
            SELECT SUM(
                quantite * prix_unitaire_facture
            )
            FROM bronze.lignes_commande
        ),
        2
    ) AS ca_bronze,

    ROUND(
        (
            SELECT SUM(
                quantite * prix_unitaire_facture
            )
            FROM silver.stg_lignes_commande
        ),
        2
    ) AS ca_silver,

    ROUND(
        (
            SELECT SUM(montant_ligne)
            FROM gold.fact_ligne_commande
        ),
        2
    ) AS ca_gold;


/* =========================================================
   4. CONTRÔLE DE LA MARGE BRUTE
   Silver = Gold
   ========================================================= */

SELECT
    ROUND(
        SUM(
            (l.prix_unitaire_facture - p.cout_unitaire)
            * l.quantite
        ),
        2
    ) AS marge_silver,

    ROUND(
        SUM(fl.marge_brute),
        2
    ) AS marge_gold

FROM silver.stg_lignes_commande l

LEFT JOIN silver.stg_produits p
    ON l.id_produit = p.id_produit

JOIN gold.fact_ligne_commande fl
    ON l.id_ligne = fl.id_ligne;


/* =========================================================
   5. CONTRÔLE DES QUANTITÉS VENDUES
   Bronze = Silver = Gold
   ========================================================= */

SELECT
    (
        SELECT SUM(quantite)
        FROM bronze.lignes_commande
    ) AS quantite_bronze,

    (
        SELECT SUM(quantite)
        FROM silver.stg_lignes_commande
    ) AS quantite_silver,

    (
        SELECT SUM(quantite)
        FROM gold.fact_ligne_commande
    ) AS quantite_gold;