SELECT
    r.*,
    lc.quantite AS quantite_commandee,
    c.date_commande,

    CASE
        WHEN r.quantite_retournee IS NULL
             AND r.date_retour IS NULL
            THEN 'quantite_retournee_null + date_retour_null'

        WHEN r.quantite_retournee IS NULL
             AND r.date_retour < c.date_commande
            THEN 'quantite_retournee_null + date_retour_avant_commande'

        WHEN r.quantite_retournee IS NULL
            THEN 'quantite_retournee_null'

        WHEN r.quantite_retournee > lc.quantite
             AND r.date_retour IS NULL
            THEN 'quantite_retournee_superieure + date_retour_null'

        WHEN r.quantite_retournee > lc.quantite
             AND r.date_retour < c.date_commande
            THEN 'quantite_retournee_superieure + date_retour_avant_commande'

        WHEN r.quantite_retournee > lc.quantite
            THEN 'quantite_retournee_superieure_a_commande'

        WHEN r.date_retour IS NULL
            THEN 'date_retour_null'

        WHEN r.date_retour < c.date_commande
            THEN 'date_retour_avant_commande'
    END AS motif_rejet

FROM {{ source('bronze', 'retours') }} r

JOIN {{ source('bronze', 'lignes_commande') }} lc
    ON r.id_ligne = lc.id_ligne

JOIN {{ source('bronze', 'commandes') }} c
    ON lc.id_commande = c.id_commande

WHERE r.quantite_retournee IS NULL
   OR r.quantite_retournee > lc.quantite
   OR r.date_retour IS NULL
   OR r.date_retour < c.date_commande