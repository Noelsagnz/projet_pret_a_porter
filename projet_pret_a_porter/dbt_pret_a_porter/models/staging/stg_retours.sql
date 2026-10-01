SELECT
    r.id_retour,
    r.id_ligne,
    r.date_retour,
    TRIM(r.motif) AS motif,
    r.quantite_retournee,

    COALESCE(
        NULLIF(TRIM(r.statut_remboursement), ''),
        'Non renseigné'
    ) AS statut_remboursement,

    r.montant_rembourse

FROM {{ source('bronze', 'retours') }} r

JOIN {{ source('bronze', 'lignes_commande') }} lc
    ON r.id_ligne = lc.id_ligne

JOIN {{ source('bronze', 'commandes') }} c
    ON lc.id_commande = c.id_commande

WHERE r.quantite_retournee IS NOT NULL
  AND r.quantite_retournee <= lc.quantite
  AND r.date_retour >= c.date_commande