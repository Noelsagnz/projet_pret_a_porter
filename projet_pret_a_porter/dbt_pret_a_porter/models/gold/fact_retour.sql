SELECT
    r.id_retour,
    r.id_ligne,
    r.date_retour,
    r.motif,
    r.quantite_retournee,
    r.statut_remboursement,
    r.montant_rembourse

FROM {{ ref('stg_retours') }} r

