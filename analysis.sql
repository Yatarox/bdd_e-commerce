-- Exercice 1 — Explorer les produits 
SELECT nom, categorie, prix, stock
FROM produit
ORDER BY categorie, nom;
 

SELECT nom, categorie, prix, stock
FROM produit
WHERE prix > 100
ORDER BY prix DESC;

-- Exercice 2 — Explorer les clients
SELECT id, nom, prenom, email, ville, date_inscription
FROM client
WHERE ville = 'Paris'
ORDER BY nom, prenom;
 

SELECT ville, COUNT(*) AS nb_clients
FROM client
GROUP BY ville
ORDER BY nb_clients DESC, ville;
 
 
-- Exercice 3 — Explorer les commandes
SELECT
    co.id            AS commande_id,
    co.date_commande,
    co.statut,
    cl.id            AS client_id,
    cl.nom,
    cl.prenom,
    cl.email,
    cl.ville
FROM commande co
JOIN client cl ON cl.id = co.client_id
ORDER BY co.date_commande, co.id;
 
 
-- Exercice 4 — Montant d'une ligne de commande
SELECT
    lc.id            AS ligne_id,
    lc.commande_id,
    lc.produit_id,
    lc.quantite,
    lc.prix_unitaire,
    lc.quantite * lc.prix_unitaire AS montant_ligne
FROM ligne_commande lc
ORDER BY lc.commande_id, lc.id;
 
 
-- Exercice 5 — Montant total de chaque commande
SELECT
    co.id            AS commande_id,
    co.date_commande,
    co.statut,
    SUM(lc.quantite * lc.prix_unitaire) AS montant_total
FROM commande co
JOIN ligne_commande lc ON lc.commande_id = co.id
GROUP BY co.id, co.date_commande, co.statut
ORDER BY co.id;
 
 
-- Exercice 6 — Chiffre d'affaires par catégorie
SELECT
    p.categorie,
    SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires,
    SUM(lc.quantite)                    AS quantite_vendue
FROM ligne_commande lc
JOIN commande co ON co.id = lc.commande_id
JOIN produit  p  ON p.id  = lc.produit_id
WHERE co.statut <> 'annulée'
GROUP BY p.categorie
ORDER BY chiffre_affaires DESC;
 
 
-- Exercice 7 — Top 10 des produits les plus vendus (en quantité)
SELECT
    p.nom     AS produit,
    p.categorie,
    SUM(lc.quantite) AS quantite_vendue
FROM ligne_commande lc
JOIN commande co ON co.id = lc.commande_id
JOIN produit  p  ON p.id  = lc.produit_id
WHERE co.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie
ORDER BY quantite_vendue DESC, p.nom
LIMIT 10;
 
 
-- Exercice 8 — Top 10 des produits par chiffre d'affaires
SELECT
    p.nom     AS produit,
    p.categorie,
    SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires
FROM ligne_commande lc
JOIN commande co ON co.id = lc.commande_id
JOIN produit  p  ON p.id  = lc.produit_id
WHERE co.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie
ORDER BY chiffre_affaires DESC, p.nom
LIMIT 10;
 
 
-- Exercice 9 — Clients
SELECT
    cl.id,
    cl.nom,
    cl.prenom,
    COUNT(DISTINCT co.id)                         AS nb_commandes,
    COALESCE(SUM(lc.quantite * lc.prix_unitaire), 0) AS montant_total
FROM client cl
LEFT JOIN commande co
       ON co.client_id = cl.id
      AND co.statut <> 'annulée'
LEFT JOIN ligne_commande lc
       ON lc.commande_id = co.id
GROUP BY cl.id, cl.nom, cl.prenom
ORDER BY montant_total DESC, cl.id;
 

SELECT cl.id, cl.nom, cl.prenom, cl.email, cl.ville
FROM client cl
WHERE NOT EXISTS (
    SELECT 1 FROM commande co WHERE co.client_id = cl.id
)
ORDER BY cl.id;
 

 
-- Exercice 10 — Panier moyen
WITH total_commande AS (
    SELECT
        co.id,
        SUM(lc.quantite * lc.prix_unitaire) AS montant
    FROM commande co
    JOIN ligne_commande lc ON lc.commande_id = co.id
    WHERE co.statut <> 'annulée'
    GROUP BY co.id
)
SELECT
    SUM(montant)           AS chiffre_affaires,
    COUNT(*)               AS nb_commandes,
    ROUND(AVG(montant), 2) AS panier_moyen
FROM total_commande;
 

WITH total_commande AS (
    SELECT
        co.id,
        DATE_TRUNC('month', co.date_commande)::date AS mois,
        SUM(lc.quantite * lc.prix_unitaire)         AS montant
    FROM commande co
    JOIN ligne_commande lc ON lc.commande_id = co.id
    WHERE co.statut <> 'annulée'
    GROUP BY co.id, DATE_TRUNC('month', co.date_commande)
)
SELECT
    TO_CHAR(mois, 'YYYY-MM') AS mois,
    SUM(montant)             AS chiffre_affaires,
    COUNT(*)                 AS nb_commandes,
    ROUND(AVG(montant), 2)   AS panier_moyen
FROM total_commande
GROUP BY mois
ORDER BY mois;