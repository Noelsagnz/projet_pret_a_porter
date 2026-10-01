SELECT
    *,
    CASE
        WHEN montant_total IS NULL
             AND date_livraison < date_commande
            THEN 'montant_total_null + date_livraison_incoherente'

        WHEN montant_total IS NULL
            THEN 'montant_total_null'

        WHEN date_livraison < date_commande
            THEN 'date_livraison_avant_date_commande'
    END AS motif_rejet

FROM {{ source('bronze', 'commandes') }}

WHERE montant_total IS NULL
   OR date_livraison < date_commande