SELECT id_client, nom, prenom, ville, date_inscription, email
FROM bronze.clients
WHERE email IS NULL
ORDER BY id_client;






SELECT * from bronze.clients limit 5; 


SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'bronze'
  AND table_name = 'clients'
ORDER BY ordinal_position;


-- valeurs manquant
SELECT
    COUNT(*) FILTER (WHERE id_client IS NULL) AS id_client_null,
    COUNT(*) FILTER (WHERE nom IS NULL) AS nom_null,
    COUNT(*) FILTER (WHERE prenom IS NULL) AS prenom_null,
    COUNT(*) FILTER (WHERE email IS NULL) AS email_null,
    COUNT(*) FILTER (WHERE ville IS NULL) AS ville_null,
    COUNT(*) FILTER (WHERE date_inscription IS NULL) AS date_inscription_null,
    COUNT(*) FILTER (WHERE genre IS NULL) AS genre_null,
    COUNT(*) FILTER (WHERE date_naissance IS NULL) AS date_naissance_null,
    COUNT(*) FILTER (WHERE code_postal IS NULL) AS code_postal_null,
    COUNT(*) FILTER (WHERE region IS NULL) AS region_null,
    COUNT(*) FILTER (WHERE canal_acquisition IS NULL) AS canal_acquisition_null,
    COUNT(*) FILTER (WHERE optin_newsletter IS NULL) AS optin_newsletter_null
FROM bronze.clients;


-- Doublons (aucune ligne ==> aucun doublon sur id_client)
SELECT
    id_client,
    COUNT(*) AS nombre
FROM bronze.clients
GROUP BY id_client
HAVING COUNT(*) > 1
ORDER BY nombre DESC;

-- controle email (aucune ligne ==> format correct)
SELECT
    id_client,
    email
FROM bronze.clients
WHERE email IS NOT NULL
  AND TRIM(email) !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

-- espace inutile:
SELECT
    id_client,
    nom,
    prenom,
    email,
    ville,
    genre,
    code_postal,
    region,
    canal_acquisition
FROM bronze.clients
WHERE nom <> TRIM(nom)
   OR prenom <> TRIM(prenom)
   OR email <> TRIM(email)
   OR ville <> TRIM(ville)
   OR genre <> TRIM(genre)
   OR code_postal <> TRIM(code_postal)
   OR region <> TRIM(region)
   OR canal_acquisition <> TRIM(canal_acquisition);

   -- controle genre
   SELECT
    genre,
    COUNT(*) AS nombre
FROM bronze.clients
GROUP BY genre
ORDER BY nombre DESC;

-- controle canal acquisition
SELECT
    canal_acquisition,
    COUNT(*) AS nombre
FROM bronze.clients
GROUP BY canal_acquisition
ORDER BY nombre DESC;


-- date d'inscription (aucune ligne ==> aucune date d'insrciption dans le futur)
SELECT *
FROM bronze.clients
WHERE date_inscription > CURRENT_DATE;


-- date naissance (aucune ligne ==> aucune date de naissance dans le futur)
SELECT *
FROM bronze.clients
WHERE date_naissance > CURRENT_DATE;


-- vérifier si date de naissance n'est pas postérieure à sa date d'inscription.
    SELECT
    id_client,
    date_naissance,
    date_inscription
FROM bronze.clients
WHERE date_naissance > date_inscription;


-- code postal
SELECT
    id_client,
    code_postal
FROM bronze.clients
WHERE code_postal IS NOT NULL
  AND TRIM(code_postal) !~ '^[0-9]{5}$';



  /* profilage commande */ -- 11 colonnes
  SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'bronze'
  AND table_name = 'commandes'
ORDER BY ordinal_position;

-- doublons commande (aucun sur l'id)
SELECT
    id_commande,
    COUNT(*) AS nombre
FROM bronze.commandes
GROUP BY id_commande
HAVING COUNT(*) > 1
ORDER BY nombre DESC;


-- valeur manquant (commandes)
SELECT
    COUNT(*) FILTER (WHERE id_commande IS NULL) AS id_commande_null,
    COUNT(*) FILTER (WHERE id_client IS NULL) AS id_client_null,
    COUNT(*) FILTER (WHERE date_commande IS NULL) AS date_commande_null,
    COUNT(*) FILTER (WHERE statut IS NULL) AS statut_null,
    COUNT(*) FILTER (WHERE montant_total IS NULL) AS montant_total_null,
    COUNT(*) FILTER (WHERE canal_commande IS NULL) AS canal_commande_null,
    COUNT(*) FILTER (WHERE mode_paiement IS NULL) AS mode_paiement_null,
    COUNT(*) FILTER (WHERE mode_livraison IS NULL) AS mode_livraison_null,
    COUNT(*) FILTER (WHERE frais_livraison IS NULL) AS frais_livraison_null,
    COUNT(*) FILTER (WHERE code_promo IS NULL) AS code_promo_null,
    COUNT(*) FILTER (WHERE date_livraison IS NULL) AS date_livraison_null
FROM bronze.commandes;


-- verif statut (150 n'ont vpas de statut)
SELECT
    statut,
    COUNT(*) AS nombre
FROM bronze.commandes
GROUP BY statut
ORDER BY nombre DESC;


-- commande sans statut (on voit des statuts non renseigné)
SELECT
    id_commande,
    id_client,
    date_commande,
    statut,
    montant_total,
    canal_commande,
    mode_paiement,
    mode_livraison,
    frais_livraison,
    code_promo,
    date_livraison
FROM bronze.commandes
WHERE statut IS NULL
--LIMIT 20;

-- canal_commande (100 qui sont null)
SELECT
    canal_commande,
    COUNT(*) AS nombre
FROM bronze.commandes
GROUP BY canal_commande
ORDER BY nombre DESC;


-- regarder les 100 lignes canal commandes
SELECT
    id_commande,
    id_client,
    date_commande,
    statut,
    montant_total,
    canal_commande,
    mode_paiement,
    mode_livraison,
    frais_livraison,
    code_promo,
    date_livraison
FROM bronze.commandes
WHERE canal_commande IS NULL
LIMIT 20;


-- mode de paiement
SELECT
    mode_paiement,
    COUNT(*) AS nombre
FROM bronze.commandes
GROUP BY mode_paiement
ORDER BY nombre DESC;


-- mode livraison
SELECT
    mode_livraison,
    COUNT(*) AS nombre
FROM bronze.commandes
GROUP BY mode_livraison
ORDER BY nombre DESC;

-- montant total
SELECT
    COUNT(*) AS nombre_negatifs
FROM bronze.commandes
WHERE montant_total < 0;


SELECT
    MIN(montant_total) AS montant_min,
    MAX(montant_total) AS montant_max,
    AVG(montant_total) AS montant_moyen
FROM bronze.commandes;

-- frais livraison
SELECT
    COUNT(*) AS nombre_negatifs
FROM bronze.commandes
WHERE frais_livraison < 0;

SELECT
    MIN(frais_livraison) AS frais_min,
    MAX(frais_livraison) AS frais_max,
    AVG(frais_livraison) AS frais_moyen
FROM bronze.commandes;


--controle date 
SELECT
    COUNT(*) AS nombre_anomalies
FROM bronze.commandes
WHERE date_livraison < date_commande;

SELECT
    id_commande,
    date_commande,
    date_livraison,
    statut,
    mode_livraison
FROM bronze.commandes
WHERE date_livraison < date_commande
ORDER BY date_commande
LIMIT 40;


-- 
    SELECT
    MIN(date_livraison - date_commande) AS ecart_min_jours,
    MAX(date_livraison - date_commande) AS ecart_max_jours
FROM bronze.commandes
WHERE date_livraison < date_commande;


SELECT
    COUNT(*) AS nombre_dates_futures
FROM bronze.commandes
WHERE date_commande > CURRENT_DATE;


-- 
SELECT
    id_commande,
    id_client,
    date_commande,
    statut,
    montant_total,
    canal_commande,
    mode_paiement,
    mode_livraison,
    frais_livraison,
    code_promo,
    date_livraison
FROM bronze.commandes
WHERE montant_total IS NULL
LIMIT 20;


-- 
SELECT
    COUNT(*) AS nombre_clients_inexistants
FROM bronze.commandes c
LEFT JOIN bronze.clients cl
    ON c.id_client = cl.id_client
WHERE cl.id_client IS NULL;


-- 
SELECT
    code_promo,
    COUNT(*) AS nombre
FROM bronze.commandes
WHERE code_promo IS NOT NULL
GROUP BY code_promo
ORDER BY nombre DESC;


--
SELECT
    COUNT(*) FILTER (WHERE statut <> TRIM(statut)) AS statut_avec_espaces,
    COUNT(*) FILTER (WHERE canal_commande <> TRIM(canal_commande)) AS canal_avec_espaces,
    COUNT(*) FILTER (WHERE mode_paiement <> TRIM(mode_paiement)) AS paiement_avec_espaces,
    COUNT(*) FILTER (WHERE mode_livraison <> TRIM(mode_livraison)) AS livraison_avec_espaces,
    COUNT(*) FILTER (WHERE code_promo <> TRIM(code_promo)) AS promo_avec_espaces
FROM bronze.commandes;


/* ligne commande */
