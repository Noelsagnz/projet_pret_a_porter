/* =========================================================
   CONTRÔLES DES RÈGLES MÉTIER
   ========================================================= */


/* =========================================================
   RÈGLE 1
   Montant total commande = somme des lignes
   ========================================================= */

SELECT
    COUNT(*) AS nb_anomalies
FROM (
    SELECT
        c.id_commande,
        c.montant_total,
        COALESCE(
            SUM(l.quantite * l.prix_unitaire_facture),
            0
        ) AS total_lignes
    FROM silver.stg_commandes c
    LEFT JOIN silver.stg_lignes_commande l
        ON c.id_commande = l.id_commande
    GROUP BY
        c.id_commande,
        c.montant_total
    HAVING ROUND(c.montant_total, 2)
        <> ROUND(
            COALESCE(
                SUM(l.quantite * l.prix_unitaire_facture),
                0
            ),
            2
        )
) anomalies;


/* =========================================================
   RÈGLE 2
   Frais de livraison
   ========================================================= */

SELECT
    COUNT(*) AS nb_anomalies
FROM silver.stg_commandes
WHERE
       (
           mode_livraison = 'Express'
           AND ROUND(frais_livraison, 2) <> 9.90
       )
    OR (
           mode_livraison = 'Point relais'
           AND (
               (montant_total < 60 AND ROUND(frais_livraison, 2) <> 3.90)
               OR
               (montant_total >= 60 AND ROUND(frais_livraison, 2) <> 0)
           )
       )
    OR (
           mode_livraison = 'Standard'
           AND (
               (montant_total < 60 AND ROUND(frais_livraison, 2) <> 4.90)
               OR
               (montant_total >= 60 AND ROUND(frais_livraison, 2) <> 0)
           )
       );


/* =========================================================
   RÈGLE 3
   BIENVENUE10 uniquement sur la première commande
   ========================================================= */

WITH commandes_classees AS (
    SELECT
        id_commande,
        id_client,
        date_commande,
        code_promo,
        ROW_NUMBER() OVER (
            PARTITION BY id_client
            ORDER BY date_commande, id_commande
        ) AS rang_commande
    FROM silver.stg_commandes
)

SELECT
    COUNT(*) AS nb_anomalies
FROM commandes_classees
WHERE code_promo = 'BIENVENUE10'
  AND rang_commande <> 1;


/* =========================================================
   RÈGLE 4
   Remise 30-50% uniquement en janvier/juillet
   et sur les collections saisonnières
   ========================================================= */

SELECT
    COUNT(*) AS nb_anomalies
FROM silver.stg_lignes_commande l
JOIN silver.stg_commandes c
    ON l.id_commande = c.id_commande
JOIN silver.stg_produits p
    ON l.id_produit = p.id_produit
WHERE l.remise_pct BETWEEN 30 AND 50
  AND (
       EXTRACT(MONTH FROM c.date_commande) NOT IN (1, 7)
       OR p.collection NOT IN ('AH24', 'PE25')
  );


/* =========================================================
   RÈGLE 5
   Paiement en 3x uniquement à partir de 100 €
   ========================================================= */

SELECT
    COUNT(*) AS nb_anomalies
FROM silver.stg_commandes
WHERE mode_paiement = 'Paiement en 3x'
  AND montant_total < 100;


/* =========================================================
   RÈGLE 6
   date_livraison uniquement pour les commandes livrées
   ========================================================= */

SELECT
    COUNT(*) AS nb_anomalies
FROM silver.stg_commandes
WHERE
       (statut = 'livree' AND date_livraison IS NULL)
    OR (statut <> 'livree' AND date_livraison IS NOT NULL);


/* =========================================================
   RÈGLE 7
   Retours uniquement sur commandes livrées
   et remboursement = quantité retournée × prix facturé
   ========================================================= */


/* 7A - Retour uniquement sur une commande livrée */

SELECT
    COUNT(*) AS nb_anomalies
FROM silver.stg_retours r
JOIN silver.stg_lignes_commande l
    ON r.id_ligne = l.id_ligne
JOIN silver.stg_commandes c
    ON l.id_commande = c.id_commande
WHERE c.statut <> 'livree';


/* 7B - Contrôle du montant remboursé */

SELECT
    COUNT(*) AS nb_anomalies
FROM silver.stg_retours r
JOIN silver.stg_lignes_commande l
    ON r.id_ligne = l.id_ligne
WHERE r.statut_remboursement = 'rembourse'
  AND ROUND(r.montant_rembourse, 2)
      <> ROUND(
          r.quantite_retournee * l.prix_unitaire_facture,
          2
      );


/* =========================================================
   RÈGLE 8
   Marge brute =
   (prix_unitaire_facture - cout_unitaire) × quantité
   ========================================================= */

SELECT
    COUNT(*) AS nb_anomalies
FROM gold.fact_ligne_commande
WHERE cout_unitaire IS NOT NULL
  AND ROUND(marge_brute, 2)
      <> ROUND(
          (prix_unitaire_facture - cout_unitaire) * quantite,
          2
      );