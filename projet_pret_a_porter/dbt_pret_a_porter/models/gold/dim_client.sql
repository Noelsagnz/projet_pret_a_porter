SELECT
    id_client,
    nom,
    prenom,
    email,
    ville,
    date_inscription,
    genre,
    date_naissance,
    code_postal,
    region,
    canal_acquisition,
    optin_newsletter
FROM {{ ref('stg_clients') }}