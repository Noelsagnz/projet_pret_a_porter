SELECT
    id_commande,
    id_client,
    date_commande,
    statut,
    montant_total,

    canal_commande,

    CASE
        WHEN LOWER(TRIM(mode_paiement)) IN ('carte bancaire', 'cb')
            THEN 'Carte bancaire'

        WHEN LOWER(TRIM(mode_paiement)) = 'paypal'
            THEN 'PayPal'

        WHEN TRIM(mode_paiement) = '3x'
            THEN 'Paiement en 3x'

        ELSE TRIM(mode_paiement)
    END AS mode_paiement,

    mode_livraison,
    frais_livraison,
    code_promo,
    date_livraison

FROM {{ source('bronze', 'commandes') }}

WHERE montant_total IS NOT NULL
  AND (
      date_livraison >= date_commande
      OR date_livraison IS NULL
  )