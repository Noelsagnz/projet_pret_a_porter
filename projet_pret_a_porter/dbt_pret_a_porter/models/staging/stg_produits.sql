SELECT
    id_produit,
    TRIM(nom_produit) AS nom_produit,
    TRIM(categorie) AS categorie,
    prix_unitaire,
    stock_actuel,
    TRIM(sous_categorie) AS sous_categorie,
    TRIM(genre_cible) AS genre_cible,
    TRIM(marque) AS marque,
    COALESCE(TRIM(matiere), 'Non renseigné') AS matiere,
    TRIM(collection) AS collection,
    cout_unitaire,
    date_ajout_catalogue,
    actif

FROM {{ source('bronze', 'produits') }}