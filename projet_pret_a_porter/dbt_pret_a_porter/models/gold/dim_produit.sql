SELECT
    id_produit,
    nom_produit,
    categorie,
    sous_categorie,
    genre_cible,
    marque,
    matiere,
    collection,
    prix_unitaire,
    cout_unitaire,
    stock_actuel,
    date_ajout_catalogue,
    actif
FROM {{ ref('stg_produits') }}