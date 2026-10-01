SELECT
    id_ligne,
    id_commande,
    id_produit,
    quantite,
    prix_unitaire_facture,

    CASE
        WHEN LOWER(TRIM(taille)) = 'small' THEN 'S'
        WHEN LOWER(TRIM(taille)) = 'm' THEN 'M'
        WHEN LOWER(TRIM(taille)) = 'xl' THEN 'XL'
        ELSE TRIM(taille)
    END AS taille,

    COALESCE(TRIM(couleur), 'Non renseigné') AS couleur,

    remise_pct

FROM {{ source('bronze', 'lignes_commande') }}