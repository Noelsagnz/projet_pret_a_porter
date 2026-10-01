SELECT
    id_commande,
    id_client,
    date_commande,
    statut,
    montant_total,
    canal_commande,
    mode_paiement,
    mode_livraison,
    frais_livraison,
    code_promo,
    date_livraison,

    CASE
        WHEN date_livraison IS NOT NULL
        THEN date_livraison - date_commande
        ELSE NULL
    END AS delai_livraison

FROM {{ ref('stg_commandes') }}