WITH dates AS (
    SELECT generate_series(
        (SELECT MIN(date_commande) FROM {{ ref('stg_commandes') }}),
        (SELECT MAX(date_commande) FROM {{ ref('stg_commandes') }}),
        INTERVAL '1 day'
    )::date AS date
)

SELECT
    date,
    EXTRACT(DAY FROM date)::integer AS jour,
    EXTRACT(MONTH FROM date)::integer AS mois,
    TO_CHAR(date, 'Month') AS nom_mois,
    EXTRACT(QUARTER FROM date)::integer AS trimestre,
    EXTRACT(YEAR FROM date)::integer AS annee,
    EXTRACT(ISODOW FROM date)::integer AS jour_semaine,
    TO_CHAR(date, 'Day') AS nom_jour
FROM dates