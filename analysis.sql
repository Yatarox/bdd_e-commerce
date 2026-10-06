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
    SELECT 1
    FROM commande co
    WHERE co.client_id = cl.id
      AND co.statut <> 'annulée'
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

-- Exercice 11

SELECT
    lc.commande_id,
    SUM(lc.quantite * lc.prix_unitaire) AS montant_total,
    CASE
        WHEN SUM(lc.quantite * lc.prix_unitaire) < 500 THEN 'Petit panier'
        WHEN SUM(lc.quantite * lc.prix_unitaire) < 1500 THEN 'Panier moyen'
        ELSE 'Gros panier'
    END AS categorie_montant
FROM ligne_commande lc
JOIN commande c ON c.id = lc.commande_id
GROUP BY lc.commande_id;

-- Exercice 12

WITH chiffre_affaires_mensuel AS (
    SELECT
        DATE_TRUNC('month', c.date_commande)::date AS mois,
        SUM(lc.quantite * lc.prix_unitaire) AS montant_total
    FROM ligne_commande lc
    JOIN commande c ON lc.commande_id = c.id
    GROUP BY DATE_TRUNC('month', c.date_commande)
)
SELECT
    EXTRACT(YEAR FROM mois)::INT AS annee,
    EXTRACT(MONTH FROM mois)::INT AS mois,
    ROUND(montant_total, 2) AS montant_total,
    ROUND(montant_total - LAG(montant_total) OVER (ORDER BY mois), 2)
        AS evolution_vs_mois_precedent,
    RANK() OVER (ORDER BY montant_total DESC) AS rang_ca_decroissant
FROM chiffre_affaires_mensuel
ORDER BY mois;


-- Exercice 13

SELECT
    commande.id AS commande_id,
    client.id AS client_id,
    commande.date_commande,
    client.date_inscription,
    COUNT(*) OVER () AS nb_anomalies
FROM commande
INNER JOIN client
    ON client.id = commande.client_id
WHERE commande.date_commande < client.date_inscription
ORDER BY commande.id;



-- EXERCICE 14 — PRODUITS SANS VENTE

SELECT
    p.id,
    p.nom AS produit,
    p.categorie,
    p.prix,
    p.stock
FROM produit p
WHERE NOT EXISTS (
    SELECT 1
    FROM ligne_commande lc
    JOIN commande c ON c.id = lc.commande_id
    WHERE lc.produit_id = p.id
)
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


-- Nombre de valeurs NULL effectivement présentes.
SELECT 'client' AS table_name, 'id' AS column_name, COUNT(*) AS valeurs_nulles
FROM client
WHERE id IS NULL
UNION ALL
SELECT 'client', 'nom', COUNT(*) FROM client WHERE nom IS NULL
UNION ALL
SELECT 'client', 'prenom', COUNT(*) FROM client WHERE prenom IS NULL
UNION ALL
SELECT 'client', 'email', COUNT(*) FROM client WHERE email IS NULL
UNION ALL
SELECT 'client', 'ville', COUNT(*) FROM client WHERE ville IS NULL
UNION ALL
SELECT 'client', 'date_inscription', COUNT(*) FROM client WHERE date_inscription IS NULL
UNION ALL
SELECT 'produit', 'id', COUNT(*) FROM produit WHERE id IS NULL
UNION ALL
SELECT 'produit', 'nom', COUNT(*) FROM produit WHERE nom IS NULL
UNION ALL
SELECT 'produit', 'categorie', COUNT(*) FROM produit WHERE categorie IS NULL
UNION ALL
SELECT 'produit', 'prix', COUNT(*) FROM produit WHERE prix IS NULL
UNION ALL
SELECT 'produit', 'stock', COUNT(*) FROM produit WHERE stock IS NULL
UNION ALL
SELECT 'commande', 'id', COUNT(*) FROM commande WHERE id IS NULL
UNION ALL
SELECT 'commande', 'client_id', COUNT(*) FROM commande WHERE client_id IS NULL
UNION ALL
SELECT 'commande', 'date_commande', COUNT(*) FROM commande WHERE date_commande IS NULL
UNION ALL
SELECT 'commande', 'statut', COUNT(*) FROM commande WHERE statut IS NULL
UNION ALL
SELECT 'ligne_commande', 'id', COUNT(*) FROM ligne_commande WHERE id IS NULL
UNION ALL
SELECT 'ligne_commande', 'commande_id', COUNT(*) FROM ligne_commande WHERE commande_id IS NULL
UNION ALL
SELECT 'ligne_commande', 'produit_id', COUNT(*) FROM ligne_commande WHERE produit_id IS NULL
UNION ALL
SELECT 'ligne_commande', 'quantite', COUNT(*) FROM ligne_commande WHERE quantite IS NULL
UNION ALL
SELECT 'ligne_commande', 'prix_unitaire', COUNT(*) FROM ligne_commande WHERE prix_unitaire IS NULL
ORDER BY table_name, column_name;


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



/**
PARTIE 7
**/
-- Quels sont les top 3 produits vendu chaque mois


WITH ventes_mensuelles AS (
    SELECT
        date_trunc('month', c.date_commande) AS mois,
        p.id AS produit_id,
        p.nom AS produit_nom,
        SUM(lc.quantite) AS quantite_vendue
    FROM ligne_commande lc
    JOIN commande c ON c.id = lc.commande_id
    JOIN produit p ON p.id = lc.produit_id
    WHERE c.statut <> 'annulée'
    GROUP BY date_trunc('month', c.date_commande), p.id, p.nom
),
classement AS (
    SELECT
        mois,
        produit_nom,
        quantite_vendue,
        RANK() OVER (PARTITION BY mois ORDER BY quantite_vendue DESC) AS rang
    FROM ventes_mensuelles
)
SELECT
    to_char(mois, 'YYYY-MM') AS mois,
    produit_nom,
    quantite_vendue
FROM classement
WHERE rang <= 3
ORDER BY mois, rang;

-- quels sont les produits qui apparaissent au moins 2 fois dans le top précédant

WITH ventes_mensuelles AS (
    SELECT
        date_trunc('month', c.date_commande) AS mois,
        p.id AS produit_id,
        p.nom AS produit_nom,
        SUM(lc.quantite) AS quantite_vendue
    FROM ligne_commande lc
    JOIN commande c ON c.id = lc.commande_id
    JOIN produit p ON p.id = lc.produit_id
    WHERE c.statut <> 'annulée'
    GROUP BY date_trunc('month', c.date_commande), p.id, p.nom
),
classement AS (
    SELECT
        mois,
        produit_id,
        produit_nom,
        quantite_vendue,
        RANK() OVER (PARTITION BY mois ORDER BY quantite_vendue DESC) AS rang
    FROM ventes_mensuelles
),
top3 AS (
    SELECT *
    FROM classement
    WHERE rang <= 3
)
SELECT
    produit_nom,
    COUNT(*) AS nb_apparitions_top3
FROM top3
GROUP BY produit_id, produit_nom
HAVING COUNT(*) >= 2
ORDER BY nb_apparitions_top3 DESC;

/*
ANALYSE LIBRE 1 : Chiffre d'affaires et activité par ville:
-Question : Quelles sont les villes qui génèrent le plus de chiffre d'affaires et comment se répartit l'activité par rapport au nombre de clients ?
-Intérêt métier : Permet d'identifier les zones géographiques porteuses pour cibler les efforts marketing et optimiser la logistique.
*/

SELECT 
    c.ville,
    COUNT(DISTINCT c.id) AS nombre_clients,
    COUNT(DISTINCT cmd.id) AS nombre_commandes,
    SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires
FROM client c
JOIN commande cmd ON c.id = cmd.client_id
JOIN ligne_commande lc ON cmd.id = lc.commande_id
WHERE cmd.statut != 'annulée'
GROUP BY c.ville
ORDER BY chiffre_affaires DESC;

/* 
-- OBSERVATIONS & INTERPRÉTATION (Analyse 1) :
• Montpellier et Marseille arrivent en tête (respectivement ~83,7k€ et ~75,1k€ 
pour 60 commandes chacunes).
• Strasbourg est la ville la moins performante (~40,3k€ pour 33 commandes).
• Le nombre de clients est strictement identique dans chaque ville (9 clients). 
• Les écarts de CA proviennent donc uniquement du panier global et de la fréquence d'achat, et non de la taille de la base client locale.
*/


/* 
ANALYSE LIBRE 2 : Identification des clients "VIP" (Top 10 Acheteurs)
-Question : Quels sont les clients ayant généré le plus de dépenses  cumulées sur la plateforme ?
-Intérêt métier : Permet de segmenter la base pour mettre en place un programme de fidélité et des offres sur-mesure.
*/

SELECT 
    c.nom,
    c.prenom,
    c.email,
    COUNT(DISTINCT cmd.id) AS total_commandes,
    SUM(lc.quantite * lc.prix_unitaire) AS montant_total_depense,
    ROUND(AVG(lc.quantite * lc.prix_unitaire), 2) AS moyenne_ligne_commande
FROM client c
JOIN commande cmd ON c.id = cmd.client_id
JOIN ligne_commande lc ON cmd.id = lc.commande_id
WHERE cmd.statut != 'annulée'
GROUP BY c.id, c.nom, c.prenom, c.email
ORDER BY montant_total_depense DESC
LIMIT 10;

/* 
-- OBSERVATIONS & INTERPRÉTATION (Analyse 2) :
• Alice Dubois est la meilleure cliente de la plateforme avec plus de 17 169 € 
dépensés sur 11 commandes.
• Un noyau dur de clients fidèles (famille Bernard, Paul Thomas, etc.) 
représente une part très importante du chiffre d'affaires global.
• Le panier moyen par ligne de commande pour ce top 10 oscille généralement 
entre 390 € et 570 €, montrant une régularité dans leurs achats de valeur.
*/


/*
ANALYSE LIBRE 3 : Impact financier des annulations par catégorie
-Question : Quelle catégorie de produits subit le plus d'annulations de commandes et quel est le manque à gagner financier associé ?
-Intérêt métier : Détecter des points de friction qualitatifs (ex: retours, descriptions trompeuses, ruptures) par catégorie de produits.
*/

SELECT 
    p.categorie,
    COUNT(DISTINCT cmd.id) AS commandes_annulees,
    SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires_perdu
FROM produit p
JOIN ligne_commande lc ON p.id = lc.produit_id
JOIN commande cmd ON lc.commande_id = cmd.id
WHERE cmd.statut = 'annulée'
GROUP BY p.categorie
ORDER BY chiffre_affaires_perdu DESC;

/* 
-- OBSERVATIONS & INTERPRÉTATION (Analyse 3) :
• La catégorie "Mode" subit le plus d'annulations (11 commandes) et engendre la perte financière la plus lourde (7 337,25 € perdus), ce qui est classique 
en e-commerce en raison des problèmes de taille ou de coupe.
• L' "Informatique" suit de très près avec 5 907,96 € de pertes pour 8 commandes  annulées, traduisant potentiellement des hésitations d'achat sur des paniers chers.
• L'"Audio" est la catégorie la moins touchée (1 721,46 € perdus). 
• L'entreprise doit auditer en priorité les fiches produits Mode et Informatique.
*/


/* ========================================================================
   ANALYSE 1 - Fidélisation et réachat

   Question : quelle proportion des clients actifs a passé plusieurs
   commandes ?
   Données nécessaires : commande.client_id et commande.statut.
*/

-- Répartition des clients actifs selon leur nombre de commandes valides.
WITH commandes_valides AS (
    SELECT client_id, COUNT(*) AS nb_commandes
    FROM commande
    WHERE statut <> 'annulée'
    GROUP BY client_id
)
SELECT
    nb_commandes,
    COUNT(*) AS nombre_clients
FROM commandes_valides
GROUP BY nb_commandes
ORDER BY nb_commandes;

-- Indicateurs synthétiques de fidélisation.
WITH commandes_valides AS (
    SELECT client_id, COUNT(*) AS nb_commandes
    FROM commande
    WHERE statut <> 'annulée'
    GROUP BY client_id
)
SELECT
    COUNT(*) AS clients_actifs,
    COUNT(*) FILTER (WHERE nb_commandes >= 2) AS clients_ayant_recommande,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE nb_commandes >= 2)
        / NULLIF(COUNT(*), 0),
        2
    ) AS taux_de_reamchat_pct
FROM commandes_valides;

/*
   Résultat observé avec data.sql : 90 clients actifs, dont 88 ont
   recommandé, soit 97,78 %. La base montre donc une clientèle très fidèle.
   Cet indicateur peut guider les actions de fidélisation et la prévision
   du volume de commandes récurrentes.
*/


/* ========================================================================
   ANALYSE 2 - Effet des promotions par catégorie

   Question : dans quelles catégories les prix réellement payés sont-ils
   les plus inférieurs au prix catalogue actuel ?
   Données nécessaires : produit.prix, ligne_commande.prix_unitaire,
   ligne_commande.quantite et commande.statut.
*/

SELECT
    p.categorie,
    SUM(lc.quantite) AS quantite_vendue,
    ROUND(SUM(lc.quantite * lc.prix_unitaire), 2) AS chiffre_affaires_reel,
    ROUND(SUM(lc.quantite * p.prix), 2) AS chiffre_affaires_au_prix_catalogue,
    ROUND(SUM(lc.quantite * (p.prix - lc.prix_unitaire)), 2)
        AS economie_totale_clients,
    ROUND(
        100.0 * SUM(lc.quantite * (p.prix - lc.prix_unitaire))
        / NULLIF(SUM(lc.quantite * p.prix), 0),
        2
    ) AS remise_moyenne_ponderee_pct,
    COUNT(*) FILTER (WHERE lc.prix_unitaire < p.prix)
        AS lignes_avec_remise
FROM ligne_commande lc
JOIN commande c ON c.id = lc.commande_id
JOIN produit p ON p.id = lc.produit_id
WHERE c.statut <> 'annulée'
GROUP BY p.categorie
ORDER BY remise_moyenne_ponderee_pct DESC;

/*
   Résultat observé avec data.sql : la remise moyenne pondérée est la plus
   élevée en Sport 6,95 %, puis en Maison 6,23 % et en Mode 6,16 %.
   L'économie totale calculée représente le montant théorique non payé par
   rapport aux prix catalogue actuels. Cela aide à mesurer l'effort
   promotionnel et à comparer son poids entre catégories.
*/


/* ========================================================================
   ANALYSE 3 - Produits vendus avec un stock critique

   Question : quels produits génèrent déjà des ventes alors que leur stock
   est nul ou inférieur ou égal à 10 unités ?
   Données nécessaires : produit.stock et les quantités des lignes de
   commande valides.
*/

SELECT
    p.id,
    p.nom,
    p.categorie,
    p.stock,
    COALESCE(
        SUM(
            CASE
                WHEN c.id IS NOT NULL THEN lc.quantite
                ELSE 0
            END
        ),
        0
    ) AS quantite_vendue,
    CASE
        WHEN p.stock = 0 THEN 'Rupture de stock'
        WHEN p.stock <= 10 THEN 'Stock critique'
        ELSE 'Stock suffisant'
    END AS niveau_alerte
FROM produit AS p
LEFT JOIN ligne_commande AS lc
    ON lc.produit_id = p.id
LEFT JOIN commande AS c
    ON c.id = lc.commande_id
   AND c.statut <> 'annulée'
WHERE p.stock <= 10
GROUP BY
    p.id,
    p.nom,
    p.categorie,
    p.stock
HAVING COALESCE(
    SUM(
        CASE
            WHEN c.id IS NOT NULL THEN lc.quantite
            ELSE 0
        END
    ),
    0
) > 0
ORDER BY
    p.stock,
    quantite_vendue DESC;

/*
   Résultat observé avec data.sql : 3 produits sont déjà à stock nul mais
   ont encore été vendus, notamment Lampe 2 66 unités vendue et Souris 2
   43 unités. Ces produits présentent un risque de rupture immédiat et
   peuvent justifier un réapprovisionnement prioritaire.
*/


/* ========================================================================
   ANALYSE 4 - Répartition du chiffre d'affaires selon le jour de la semaine

   Question : quels jours concentrent le plus de chiffre d'affaires ?
   Données nécessaires : commande.date_commande, commande.statut et le
   montant des lignes de commande.
*/

WITH ventes_par_commande AS (
    SELECT
        c.id,
        c.date_commande,
        SUM(lc.quantite * lc.prix_unitaire) AS montant_commande
    FROM commande c
    JOIN ligne_commande lc ON lc.commande_id = c.id
    WHERE c.statut <> 'annulée'
    GROUP BY c.id, c.date_commande
)
SELECT
    EXTRACT(ISODOW FROM date_commande)::INT AS numero_jour,
    CASE EXTRACT(ISODOW FROM date_commande)::INT
        WHEN 1 THEN 'Lundi'
        WHEN 2 THEN 'Mardi'
        WHEN 3 THEN 'Mercredi'
        WHEN 4 THEN 'Jeudi'
        WHEN 5 THEN 'Vendredi'
        WHEN 6 THEN 'Samedi'
        WHEN 7 THEN 'Dimanche'
    END AS jour_semaine,
    COUNT(*) AS nombre_commandes,
    ROUND(SUM(montant_commande), 2) AS chiffre_affaires,
    ROUND(AVG(montant_commande), 2) AS panier_moyen
FROM ventes_par_commande
GROUP BY numero_jour
ORDER BY chiffre_affaires DESC;

/*
   Résultat observé avec data.sql : le vendredi est le jour le plus
   contributeur au chiffre d'affaires 110 257,28 €, tandis que le samedi
   est le moins contributeur 79 101,51 . Cette information peut aider à
   planifier les campagnes commerciales, les effectifs et les stocks.
*/
