SELECT
    id_client,
    TRIM(nom) AS nom,
    TRIM(prenom) AS prenom,
    TRIM(email) AS email,
    INITCAP(TRIM(ville)) AS ville,
    date_inscription,
    genre,
    date_naissance,
    LPAD(TRIM(code_postal), 5, '0') AS code_postal,
    TRIM(region) AS region,
    TRIM(canal_acquisition) AS canal_acquisition,
    optin_newsletter

FROM {{ source('bronze', 'clients') }}