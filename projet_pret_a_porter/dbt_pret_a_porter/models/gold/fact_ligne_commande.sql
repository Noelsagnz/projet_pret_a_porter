SELECT
    lc.id_ligne,
    lc.id_commande,
    lc.id_produit,
    lc.quantite,
    lc.prix_unitaire_facture,
    lc.taille,
    lc.couleur,
    lc.remise_pct,
    p.cout_unitaire,

    lc.quantite * lc.prix_unitaire_facture AS montant_ligne,

    (lc.prix_unitaire_facture - p.cout_unitaire) * lc.quantite AS marge_brute

FROM {{ ref('stg_lignes_commande') }} lc

LEFT JOIN {{ ref('stg_produits') }} p
    ON lc.id_produit = p.id_produit