    -- Règle 1 : CA = SUM(quantite × prix_unitaire_facture)
    ROUND(
        SUM(
            fl.quantite * fl.prix_unitaire_facture
        ),
        2
    ) AS chiffre_affaires,

    -- Règle 8 : Marge brute =
    -- SUM((prix_unitaire_facture - cout_unitaire) × quantite)
    ROUND(
        SUM(
            (fl.prix_unitaire_facture - fl.cout_unitaire)
            * fl.quantite
        ),
        2
    ) AS marge_brute,

    -- Taux de marge = Marge brute / CA × 100
    ROUND(
        SUM(
            (fl.prix_unitaire_facture - fl.cout_unitaire)
            * fl.quantite
        )
        / NULLIF(
            SUM(
                fl.quantite * fl.prix_unitaire_facture
            ),
            0
        ) * 100,
        2
    ) AS taux_marge_pct

FROM gold.fact_ligne_commande fl

JOIN gold.fact_commande fc
    ON fl.id_commande = fc.id_commande

JOIN gold.dim_date dd
    ON fc.date_commande = dd.date

GROUP BY
    dd.annee,
    dd.mois,
    dd.nom_mois

ORDER BY
    dd.annee,
    dd.mois;
/* Contrôle des volumes Bronze → Silver → Gold */

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
	
	
	
/* vérifier les rejets */
	
	SELECT
    'commandes' AS objet,
    (SELECT COUNT(*) FROM bronze.commandes) AS bronze,
    (SELECT COUNT(*) FROM silver.stg_commandes) AS silver,
    (SELECT COUNT(*) FROM silver.rejets_commandes) AS rejets,
    (SELECT COUNT(*) FROM silver.stg_commandes)
      + (SELECT COUNT(*) FROM silver.rejets_commandes) AS silver_plus_rejets

UNION ALL

SELECT
    'retours',
    (SELECT COUNT(*) FROM bronze.retours),
    (SELECT COUNT(*) FROM silver.stg_retours),
    (SELECT COUNT(*) FROM silver.rejets_retours),
    (SELECT COUNT(*) FROM silver.stg_retours)
      + (SELECT COUNT(*) FROM silver.rejets_retours);
	  
	  
	  
	 /* Contrôle du CA global Bronze → Silver → Gold */

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
	
	
	


/* Contrôle de la marge brute globale Silver → Gold */

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
	
	
	
/* Contrôle des quantités vendues Bronze → Silver → Gold */

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