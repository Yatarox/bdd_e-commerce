
-- EXERCICE 14 — PRODUITS SANS VENTE

SELECT
    p.id,
    p.nom AS produit,
    p.categorie,
    p.prix,
    p.stock
FROM produit p
LEFT JOIN ligne_commande lc
    ON p.id = lc.produit_id
WHERE lc.produit_id IS NULL
ORDER BY p.nom;


-- EXERCICE 15.A — EXPLORATION

-- Nombre de lignes par table

SELECT 'client' AS table_name, COUNT(*) AS nombre_lignes
FROM client

UNION ALL

SELECT 'produit', COUNT(*)
FROM produit

UNION ALL

SELECT 'commande', COUNT(*)
FROM commande

UNION ALL

SELECT 'ligne_commande', COUNT(*)
FROM ligne_commande;


-- Colonnes et types

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('client', 'produit', 'commande', 'ligne_commande')
ORDER BY table_name, ordinal_position;


-- Vérification des valeurs NULL autorisées

SELECT
    table_name,
    column_name,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('client', 'produit', 'commande', 'ligne_commande')
ORDER BY table_name, ordinal_position;


-- EXERCICE 15.B — ANALYSE COMMERCIALE

SELECT
    ROUND(SUM(lc.quantite * lc.prix_unitaire), 2)
        AS chiffre_affaires_total,

    COUNT(DISTINCT c.id)
        AS nombre_commandes,

    ROUND(
        SUM(lc.quantite * lc.prix_unitaire)
        / COUNT(DISTINCT c.id),
        2
    ) AS panier_moyen,

    COUNT(DISTINCT c.client_id)
        AS clients_actifs

FROM commande c
JOIN ligne_commande lc
    ON c.id = lc.commande_id

WHERE c.statut NOT LIKE 'annul%';


-- Taux d'annulation

SELECT
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE statut LIKE 'annul%'
        ) / COUNT(*),
        2
    ) AS taux_annulation_pourcent
FROM commande;


-- EXERCICE 15.C — ANALYSE DES CLIENTS

SELECT
    cl.id AS client_id,
    cl.nom,
    cl.prenom,
    cl.email,

    ROUND(
        SUM(lc.quantite * lc.prix_unitaire),
        2
    ) AS chiffre_affaires

FROM client cl
JOIN commande c
    ON cl.id = c.client_id
JOIN ligne_commande lc
    ON c.id = lc.commande_id

WHERE c.statut NOT LIKE 'annul%'

GROUP BY
    cl.id,
    cl.nom,
    cl.prenom,
    cl.email

ORDER BY chiffre_affaires DESC
LIMIT 10;


-- EXERCICE 15.D — SYNTHESE MENSUELLE

DROP TABLE IF EXISTS synthese_mensuelle;

CREATE TABLE synthese_mensuelle AS
SELECT
    DATE_TRUNC('month', c.date_commande)::date AS mois,

    COUNT(DISTINCT c.id) AS nombre_commandes,

    ROUND(
        SUM(lc.quantite * lc.prix_unitaire),
        2
    ) AS chiffre_affaires,

    ROUND(
        SUM(lc.quantite * lc.prix_unitaire)
        / COUNT(DISTINCT c.id),
        2
    ) AS panier_moyen

FROM commande c
JOIN ligne_commande lc
    ON c.id = lc.commande_id

WHERE c.statut NOT LIKE 'annul%'

GROUP BY DATE_TRUNC('month', c.date_commande)
ORDER BY mois;


/*
La table synthese_mensuelle permet de suivre l'évolution
de l'activité commerciale mois par mois.

Elle permet de comparer le nombre de commandes,
le chiffre d'affaires et le panier moyen afin d'identifier
les périodes de forte ou de faible activité et d'observer
les évolutions des ventes.
*/