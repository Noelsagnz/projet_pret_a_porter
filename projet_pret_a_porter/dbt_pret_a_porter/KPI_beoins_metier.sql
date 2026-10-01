/* calcul KPI */
SELECT
    dd.annee,
    dd.mois,
    dd.nom_mois,

    -- Règle 1 : Chiffre d'affaires
    ROUND(
        SUM(
            fl.quantite * fl.prix_unitaire_facture
        ),
        2
    ) AS chiffre_affaires,

    -- Règle 8 : Marge brute
    ROUND(
        SUM(
            (fl.prix_unitaire_facture - fl.cout_unitaire)
            * fl.quantite
        ),
        2
    ) AS marge_brute,

    -- Taux de marge
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


	SELECT * FROM gold.fact_ligne_commande
	LIMIT 5;
	
	
	
	/* KPI 2 : Performance des produits */

WITH ventes AS (
    SELECT
        fl.id_produit,

        -- Quantité vendue
        SUM(fl.quantite) AS quantite_vendue,

        -- CA = SUM(quantite × prix_unitaire_facture)
        ROUND(
            SUM(
                fl.quantite * fl.prix_unitaire_facture
            ),
            2
        ) AS chiffre_affaires,

        -- Marge brute =
        -- SUM((prix_unitaire_facture - cout_unitaire) × quantite)
        ROUND(
            SUM(
                (fl.prix_unitaire_facture - fl.cout_unitaire)
                * fl.quantite
            ),
            2
        ) AS marge_brute

    FROM gold.fact_ligne_commande fl

    GROUP BY
        fl.id_produit
),

retours AS (
    SELECT
        fl.id_produit,

        -- Quantité retournée
        SUM(fr.quantite_retournee) AS quantite_retournee,

        -- Montant remboursé
        ROUND(
            SUM(fr.montant_rembourse),
            2
        ) AS montant_rembourse

    FROM gold.fact_retour fr

    JOIN gold.fact_ligne_commande fl
        ON fr.id_ligne = fl.id_ligne

    GROUP BY
        fl.id_produit
)

SELECT
    p.id_produit,
    p.nom_produit,

    COALESCE(v.quantite_vendue, 0) AS quantite_vendue,
    COALESCE(v.chiffre_affaires, 0) AS chiffre_affaires,
    COALESCE(v.marge_brute, 0) AS marge_brute,

    COALESCE(r.quantite_retournee, 0) AS quantite_retournee,
    COALESCE(r.montant_rembourse, 0) AS montant_rembourse

FROM gold.dim_produit p

LEFT JOIN ventes v
    ON p.id_produit = v.id_produit

LEFT JOIN retours r
    ON p.id_produit = r.id_produit

ORDER BY
    chiffre_affaires DESC;
	
	
	
	
	/* KPI 3 : Comportement et fidélité des clients */

SELECT
    dc.id_client,
    dc.nom,
    dc.prenom,

    -- Nombre de commandes
    COUNT(DISTINCT fc.id_commande) AS nb_commandes,

    -- CA = SUM(quantite × prix_unitaire_facture)
    ROUND(
        SUM(
            fl.quantite * fl.prix_unitaire_facture
        ),
        2
    ) AS chiffre_affaires,

    -- Panier moyen
    ROUND(
        SUM(
            fl.quantite * fl.prix_unitaire_facture
        )
        / NULLIF(
            COUNT(DISTINCT fc.id_commande),
            0
        ),
        2
    ) AS panier_moyen,

    -- Première commande
    MIN(fc.date_commande) AS premiere_commande,

    -- Dernière commande
    MAX(fc.date_commande) AS derniere_commande

FROM gold.dim_client dc

JOIN gold.fact_commande fc
    ON dc.id_client = fc.id_client

JOIN gold.fact_ligne_commande fl
    ON fc.id_commande = fl.id_commande

GROUP BY
    dc.id_client,
    dc.nom,
    dc.prenom

ORDER BY
    chiffre_affaires DESC;
	
	
-- KPI 4 : Qualité logistique - délais de livraison

SELECT
    COUNT(*) AS nb_commandes_livrees,

    ROUND(
        AVG(delai_livraison),
        2
    ) AS delai_moyen_jours,

    MIN(delai_livraison) AS delai_min_jours,

    MAX(delai_livraison) AS delai_max_jours

FROM gold.fact_commande

WHERE statut = 'livree';


/* KPI 5 : Efficacité des promotions et des soldes */

SELECT
    COUNT(*) AS nb_commandes,

    COUNT(*) FILTER (
        WHERE code_promo IS NOT NULL
    ) AS nb_commandes_avec_promo,

    COUNT(*) FILTER (
        WHERE code_promo = 'BIENVENUE10'
    ) AS nb_commandes_bienvenue10,

    ROUND(
        COUNT(*) FILTER (
            WHERE code_promo IS NOT NULL
        ) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS taux_utilisation_promo_pct,

    ROUND(
        COUNT(*) FILTER (
            WHERE code_promo = 'BIENVENUE10'
        ) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS taux_bienvenue10_pct

FROM gold.fact_commande;