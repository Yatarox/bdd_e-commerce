-- =====================================================================
-- PARTIE 3 — ANALYSE SQL
-- =====================================================================

-- Exercice 1 — Explorer les produits
SELECT nom, categorie, prix, stock
FROM produit
ORDER BY categorie, nom;

-- Produits dont le prix est supérieur à 100 €
SELECT nom, categorie, prix, stock
FROM produit
WHERE prix > 100
ORDER BY prix DESC;


-- Exercice 2 — Explorer les clients
-- Clients d'une ville donnée (modifier 'Paris' selon le besoin)
SELECT id, nom, prenom, email, ville, date_inscription
FROM client
WHERE ville = 'Paris'
ORDER BY nom, prenom;

-- Nombre de clients par ville
SELECT ville, COUNT(*) AS nb_clients
FROM client
GROUP BY ville
ORDER BY nb_clients DESC, ville;


-- Exercice 3 — Explorer les commandes
SELECT
    co.id AS commande_id,
    co.date_commande,
    co.statut,
    cl.id AS client_id,
    cl.nom,
    cl.prenom,
    cl.email,
    cl.ville
FROM commande co
JOIN client cl ON cl.id = co.client_id
ORDER BY co.date_commande, co.id;


-- Exercice 4 — Montant d'une ligne de commande
SELECT
    lc.id AS ligne_id,
    lc.commande_id,
    lc.produit_id,
    lc.quantite,
    lc.prix_unitaire,
    lc.quantite * lc.prix_unitaire AS montant_ligne
FROM ligne_commande lc
ORDER BY lc.commande_id, lc.id;


-- Exercice 5 — Montant total de chaque commande
-- Toutes les commandes sont listées avec leur statut (les annulées
-- restent visibles ici, mais ne sont pas comptées dans les indicateurs).
SELECT
    co.id AS commande_id,
    co.date_commande,
    co.statut,
    COALESCE(SUM(lc.quantite * lc.prix_unitaire), 0) AS montant_total
FROM commande co
LEFT JOIN ligne_commande lc ON lc.commande_id = co.id
GROUP BY co.id, co.date_commande, co.statut
ORDER BY co.id;


-- Exercice 6 — Chiffre d'affaires par catégorie
SELECT
    p.categorie,
    SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires,
    SUM(lc.quantite) AS quantite_vendue
FROM ligne_commande lc
JOIN commande co ON co.id = lc.commande_id
JOIN produit p ON p.id = lc.produit_id
WHERE co.statut <> 'annulée'
GROUP BY p.categorie
ORDER BY chiffre_affaires DESC;


-- Exercice 7 — Top 10 des produits les plus vendus (en quantité)
SELECT
    p.nom AS produit,
    p.categorie,
    SUM(lc.quantite) AS quantite_vendue
FROM ligne_commande lc
JOIN commande co ON co.id = lc.commande_id
JOIN produit p ON p.id = lc.produit_id
WHERE co.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie
ORDER BY quantite_vendue DESC, p.nom
LIMIT 10;


-- Exercice 8 — Top 10 des produits par chiffre d'affaires
SELECT
    p.nom AS produit,
    p.categorie,
    SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires
FROM ligne_commande lc
JOIN commande co ON co.id = lc.commande_id
JOIN produit p ON p.id = lc.produit_id
WHERE co.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie
ORDER BY chiffre_affaires DESC, p.nom
LIMIT 10;


-- Exercice 9 — Clients
-- Nombre de commandes (hors annulées) et montant total dépensé par client.
-- Un client sans commande apparaît avec 0 / 0.
SELECT
    cl.id,
    cl.nom,
    cl.prenom,
    COUNT(DISTINCT co.id) FILTER (WHERE co.statut <> 'annulée') AS nb_commandes,
    COALESCE(
        SUM(lc.quantite * lc.prix_unitaire) FILTER (WHERE co.statut <> 'annulée'),
        0
    ) AS montant_total
FROM client cl
LEFT JOIN commande co ON co.client_id = cl.id
LEFT JOIN ligne_commande lc ON lc.commande_id = co.id
GROUP BY cl.id, cl.nom, cl.prenom
ORDER BY montant_total DESC, cl.id;

-- Clients n'ayant JAMAIS passé de commande (quel que soit le statut :
-- une commande annulée reste une commande passée).
SELECT cl.id, cl.nom, cl.prenom, cl.email, cl.ville
FROM client cl
WHERE NOT EXISTS (
    SELECT 1
    FROM commande co
    WHERE co.client_id = cl.id
)
ORDER BY cl.id;


-- Exercice 10 — Panier moyen
-- Panier moyen global (une ligne = une commande non annulée)
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
    SUM(montant) AS chiffre_affaires,
    COUNT(*) AS nb_commandes,
    ROUND(AVG(montant), 2) AS panier_moyen
FROM total_commande;

-- Panier moyen par mois
WITH total_commande AS (
    SELECT
        co.id,
        DATE_TRUNC('month', co.date_commande)::date AS mois,
        SUM(lc.quantite * lc.prix_unitaire) AS montant
    FROM commande co
    JOIN ligne_commande lc ON lc.commande_id = co.id
    WHERE co.statut <> 'annulée'
    GROUP BY co.id, DATE_TRUNC('month', co.date_commande)
)
SELECT
    TO_CHAR(mois, 'YYYY-MM') AS mois,
    SUM(montant) AS chiffre_affaires,
    COUNT(*) AS nb_commandes,
    ROUND(AVG(montant), 2) AS panier_moyen
FROM total_commande
GROUP BY mois
ORDER BY mois;

/*
Différence entre les trois notions :
- Chiffre d'affaires : somme des montants de toutes les commandes valides
  (mesure le volume d'argent généré).
- Nombre de commandes : nombre de commandes valides (mesure l'activité
  et la fréquence d'achat, sans tenir compte des montants).
- Panier moyen = chiffre d'affaires / nombre de commandes : montant moyen
  dépensé par commande. Un CA qui monte peut venir de plus de commandes
  (volume) ou de paniers plus gros (valeur) ; le panier moyen permet de
  distinguer les deux.
*/


-- =====================================================================
-- PARTIE 4 — TRANSFORMATION DES DONNÉES
-- =====================================================================

-- Exercice 11 — Catégoriser les commandes selon leur montant
-- Choix : les commandes annulées sont exclues, par cohérence avec le
-- calcul du panier moyen (une commande annulée n'est pas un panier réel).
WITH montant_commande AS (
    SELECT
        co.id AS commande_id,
        co.date_commande,
        SUM(lc.quantite * lc.prix_unitaire) AS montant_total
    FROM commande co
    JOIN ligne_commande lc ON lc.commande_id = co.id
    WHERE co.statut <> 'annulée'
    GROUP BY co.id, co.date_commande
)
SELECT
    commande_id,
    date_commande,
    montant_total,
    CASE
        WHEN montant_total < 500  THEN 'Petit panier'
        WHEN montant_total < 1500 THEN 'Panier moyen'
        ELSE 'Gros panier'
    END AS categorie_montant
FROM montant_commande
ORDER BY commande_id;

-- Récapitulatif par catégorie de panier
WITH montant_commande AS (
    SELECT
        co.id AS commande_id,
        SUM(lc.quantite * lc.prix_unitaire) AS montant_total
    FROM commande co
    JOIN ligne_commande lc ON lc.commande_id = co.id
    WHERE co.statut <> 'annulée'
    GROUP BY co.id
)
SELECT
    CASE
        WHEN montant_total < 500  THEN 'Petit panier'
        WHEN montant_total < 1500 THEN 'Panier moyen'
        ELSE 'Gros panier'
    END AS categorie_montant,
    COUNT(*) AS nb_commandes,
    ROUND(SUM(montant_total), 2) AS chiffre_affaires
FROM montant_commande
GROUP BY 1
ORDER BY MIN(montant_total);


-- Exercice 12 — Analyse temporelle du chiffre d'affaires
-- Par mois : CA, évolution vs mois précédent, rang et repérage des
-- périodes les plus fortes / faibles. Commandes annulées exclues.
WITH ca_mensuel AS (
    SELECT
        DATE_TRUNC('month', c.date_commande)::date AS mois,
        COUNT(DISTINCT c.id) AS nb_commandes,
        SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires
    FROM commande c
    JOIN ligne_commande lc ON lc.commande_id = c.id
    WHERE c.statut <> 'annulée'
    GROUP BY DATE_TRUNC('month', c.date_commande)
),
classement AS (
    SELECT
        mois,
        nb_commandes,
        chiffre_affaires,
        LAG(chiffre_affaires) OVER (ORDER BY mois) AS ca_precedent,
        RANK() OVER (ORDER BY chiffre_affaires DESC) AS rang_haut,
        RANK() OVER (ORDER BY chiffre_affaires ASC)  AS rang_bas
    FROM ca_mensuel
)
SELECT
    TO_CHAR(mois, 'YYYY-MM') AS mois,
    nb_commandes,
    ROUND(chiffre_affaires, 2) AS chiffre_affaires,
    ROUND(chiffre_affaires - ca_precedent, 2) AS evolution_vs_mois_precedent,
    ROUND(100.0 * (chiffre_affaires - ca_precedent) / NULLIF(ca_precedent, 0), 2)
        AS evolution_pct,
    rang_haut AS rang_ca_decroissant,
    CASE
        WHEN rang_haut <= 3 THEN 'Période forte'
        WHEN rang_bas  <= 3 THEN 'Période faible'
        ELSE ''
    END AS repere
FROM classement
ORDER BY mois;

-- Vue par trimestre pour lire la tendance générale
SELECT
    TO_CHAR(DATE_TRUNC('quarter', c.date_commande), 'YYYY-"T"Q') AS trimestre,
    COUNT(DISTINCT c.id) AS nb_commandes,
    ROUND(SUM(lc.quantite * lc.prix_unitaire), 2) AS chiffre_affaires
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY DATE_TRUNC('quarter', c.date_commande)
ORDER BY DATE_TRUNC('quarter', c.date_commande);

/*
Lecture : la colonne "repere" désigne les 3 mois les plus forts et les 3
mois les plus faibles ; evolution_pct et la vue trimestrielle montrent si
l'activité progresse, se stabilise ou recule sur l'année.
*/


-- =====================================================================
-- PARTIE 5 — QUALITÉ DES DONNÉES
-- =====================================================================

-- Exercice 13 — Commandes antérieures à l'inscription du client
SELECT
    commande.id AS commande_id,
    client.id AS client_id,
    commande.date_commande,
    client.date_inscription
FROM commande
JOIN client ON client.id = commande.client_id
WHERE commande.date_commande < client.date_inscription
ORDER BY commande.id;

-- Nombre d'anomalies détectées
SELECT COUNT(*) AS nb_anomalies
FROM commande
JOIN client ON client.id = commande.client_id
WHERE commande.date_commande < client.date_inscription;


-- Exercice 14 — Produits jamais vendus (aucune ligne de commande)
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
    WHERE lc.produit_id = p.id
)
ORDER BY p.nom;

-- Produits dont les seules ventes sont des commandes annulées
-- (aucune vente réellement aboutie)
SELECT
    p.id,
    p.nom AS produit,
    p.categorie,
    p.prix,
    p.stock
FROM produit p
WHERE EXISTS (
        SELECT 1
        FROM ligne_commande lc
        WHERE lc.produit_id = p.id
    )
  AND NOT EXISTS (
        SELECT 1
        FROM ligne_commande lc
        JOIN commande c ON c.id = lc.commande_id
        WHERE lc.produit_id = p.id
          AND c.statut <> 'annulée'
    )
ORDER BY p.nom;

/*
Intérêt pour l'entreprise : un produit jamais vendu immobilise du stock
et de la trésorerie. Cela peut révéler un problème de visibilité, de prix
ou de pertinence de l'offre, et justifier une promotion, un déstockage,
une mise en avant ou le retrait du catalogue.
*/


-- =====================================================================
-- PARTIE 6 — TABLEAU DE BORD EN SQL
-- =====================================================================

-- Exercice 15.A — Exploration
-- Nombre de lignes de chaque table
SELECT 'client' AS table_name, COUNT(*) AS nombre_lignes FROM client
UNION ALL
SELECT 'produit', COUNT(*) FROM produit
UNION ALL
SELECT 'commande', COUNT(*) FROM commande
UNION ALL
SELECT 'ligne_commande', COUNT(*) FROM ligne_commande;

-- Colonnes, types de données et nullabilité
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('client', 'produit', 'commande', 'ligne_commande')
ORDER BY table_name, ordinal_position;

-- Valeurs manquantes effectivement présentes, pour chaque colonne
SELECT 'client' AS table_name, j.colonne AS column_name,
       COUNT(*) FILTER (WHERE j.valeur = 'null'::jsonb) AS valeurs_nulles
FROM client t, LATERAL jsonb_each(to_jsonb(t)) AS j(colonne, valeur)
GROUP BY j.colonne
UNION ALL
SELECT 'produit', j.colonne,
       COUNT(*) FILTER (WHERE j.valeur = 'null'::jsonb)
FROM produit t, LATERAL jsonb_each(to_jsonb(t)) AS j(colonne, valeur)
GROUP BY j.colonne
UNION ALL
SELECT 'commande', j.colonne,
       COUNT(*) FILTER (WHERE j.valeur = 'null'::jsonb)
FROM commande t, LATERAL jsonb_each(to_jsonb(t)) AS j(colonne, valeur)
GROUP BY j.colonne
UNION ALL
SELECT 'ligne_commande', j.colonne,
       COUNT(*) FILTER (WHERE j.valeur = 'null'::jsonb)
FROM ligne_commande t, LATERAL jsonb_each(to_jsonb(t)) AS j(colonne, valeur)
GROUP BY j.colonne
ORDER BY table_name, column_name;


-- Exercice 15.B — Analyse commerciale (une seule requête)
SELECT
    ROUND(SUM(lc.quantite * lc.prix_unitaire), 2) AS chiffre_affaires_total,
    COUNT(DISTINCT c.id) AS nombre_commandes,
    ROUND(SUM(lc.quantite * lc.prix_unitaire) / COUNT(DISTINCT c.id), 2)
        AS panier_moyen,
    COUNT(DISTINCT c.client_id) AS clients_actifs
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée';

-- Taux d'annulation (sur l'ensemble des commandes)
SELECT
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE statut = 'annulée') / COUNT(*),
        2
    ) AS taux_annulation_pourcent
FROM commande;


-- Exercice 15.C — Top 10 des clients par chiffre d'affaires
SELECT
    cl.id AS client_id,
    cl.nom,
    cl.prenom,
    cl.email,
    ROUND(SUM(lc.quantite * lc.prix_unitaire), 2) AS chiffre_affaires
FROM client cl
JOIN commande c ON c.client_id = cl.id
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY cl.id, cl.nom, cl.prenom, cl.email
ORDER BY chiffre_affaires DESC
LIMIT 10;


-- Exercice 15.D — Synthèse mensuelle
DROP TABLE IF EXISTS synthese_mensuelle;

CREATE TABLE synthese_mensuelle AS
SELECT
    DATE_TRUNC('month', c.date_commande)::date AS mois,
    COUNT(DISTINCT c.id) AS nombre_commandes,
    ROUND(SUM(lc.quantite * lc.prix_unitaire), 2) AS chiffre_affaires,
    ROUND(
        SUM(lc.quantite * lc.prix_unitaire) / COUNT(DISTINCT c.id),
        2
    ) AS panier_moyen
FROM commande c
JOIN ligne_commande lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY DATE_TRUNC('month', c.date_commande)
ORDER BY mois;

SELECT * FROM synthese_mensuelle ORDER BY mois;

/*
La table synthese_mensuelle permet de suivre l'activité mois par mois :
- nombre de commandes : fréquence d'achat ;
- chiffre d'affaires : volume d'argent généré ;
- panier moyen : valeur moyenne d'une commande.
En les comparant, on voit si une hausse du CA vient de plus de commandes
ou de paniers plus élevés, et on repère les mois forts et faibles.
*/


-- =====================================================================
-- PARTIE 7 — ANALYSE LIBRE
-- =====================================================================

/* ---------------------------------------------------------------------
ANALYSE 1 — Chiffre d'affaires et activité par ville
Question : quelles villes génèrent le plus de chiffre d'affaires ?
Données : client.ville, commande, ligne_commande (hors annulées).
Intérêt : cibler les zones porteuses (marketing, logistique).
--------------------------------------------------------------------- */
SELECT
    c.ville,
    COUNT(DISTINCT c.id) AS nombre_clients,
    COUNT(DISTINCT cmd.id) AS nombre_commandes,
    ROUND(SUM(lc.quantite * lc.prix_unitaire), 2) AS chiffre_affaires
FROM client c
JOIN commande cmd ON cmd.client_id = c.id
JOIN ligne_commande lc ON lc.commande_id = cmd.id
WHERE cmd.statut <> 'annulée'
GROUP BY c.ville
ORDER BY chiffre_affaires DESC;

/*
Observations : Montpellier et Marseille arrivent en tête (~83,7 k€ et
~75,1 k€, 60 commandes chacune) ; Strasbourg est la moins performante
(~40,3 k€, 33 commandes). Chaque ville compte le même nombre de clients
(9) : les écarts viennent donc de la fréquence d'achat et du panier, pas
de la taille de la base clients.
*/


/* ---------------------------------------------------------------------
ANALYSE 2 — Évolution mensuelle du taux d'annulation
Question : le taux d'annulation est-il stable ou concentré sur certains
mois ?
Données : commande.date_commande et commande.statut.
Intérêt : repérer une période de dégradation (rupture de stock,
problème de livraison, campagne mal ciblée).
--------------------------------------------------------------------- */
SELECT
    TO_CHAR(DATE_TRUNC('month', date_commande), 'YYYY-MM') AS mois,
    COUNT(*) AS nb_commandes,
    COUNT(*) FILTER (WHERE statut = 'annulée') AS nb_annulees,
    ROUND(100.0 * COUNT(*) FILTER (WHERE statut = 'annulée') / COUNT(*), 2)
        AS taux_annulation_pct
FROM commande
GROUP BY DATE_TRUNC('month', date_commande)
ORDER BY DATE_TRUNC('month', date_commande);

/*
Lecture : un mois dont le taux dépasse nettement la moyenne annuelle
(voir 15.B) mérite une investigation. Compléter ici avec les mois
observés après exécution.
*/


/* ---------------------------------------------------------------------
ANALYSE 3 — Impact financier des annulations par catégorie
Question : quelle catégorie subit le plus d'annulations et quel est le
manque à gagner ?
Données : produit.categorie, ligne_commande, commande.statut.
Intérêt : détecter des points de friction par catégorie.
--------------------------------------------------------------------- */
SELECT
    p.categorie,
    COUNT(DISTINCT cmd.id) AS commandes_annulees,
    ROUND(SUM(lc.quantite * lc.prix_unitaire), 2) AS chiffre_affaires_perdu
FROM produit p
JOIN ligne_commande lc ON lc.produit_id = p.id
JOIN commande cmd ON cmd.id = lc.commande_id
WHERE cmd.statut = 'annulée'
GROUP BY p.categorie
ORDER BY chiffre_affaires_perdu DESC;

/*
Observations : « Mode » subit le plus d'annulations (11 commandes,
7 337,25 € perdus), suivie de « Informatique » (8 commandes,
5 907,96 €). « Audio » est la moins touchée (1 721,46 €). Les fiches
produits Mode et Informatique sont à auditer en priorité.
*/


/* ---------------------------------------------------------------------
ANALYSE 4 — Produits les plus vendus chaque mois
Question : quels sont les 3 produits les plus vendus chaque mois, et
lesquels reviennent régulièrement ?
Données : ligne_commande, commande, produit (hors annulées).
Intérêt : repérer les produits phares et les effets de saisonnalité.
--------------------------------------------------------------------- */
WITH ventes_mensuelles AS (
    SELECT
        DATE_TRUNC('month', c.date_commande) AS mois,
        p.id AS produit_id,
        p.nom AS produit_nom,
        SUM(lc.quantite) AS quantite_vendue
    FROM ligne_commande lc
    JOIN commande c ON c.id = lc.commande_id
    JOIN produit p ON p.id = lc.produit_id
    WHERE c.statut <> 'annulée'
    GROUP BY DATE_TRUNC('month', c.date_commande), p.id, p.nom
),
classement AS (
    SELECT
        mois,
        produit_id,
        produit_nom,
        quantite_vendue,
        RANK() OVER (PARTITION BY mois ORDER BY quantite_vendue DESC) AS rang
    FROM ventes_mensuelles
)
SELECT
    TO_CHAR(mois, 'YYYY-MM') AS mois,
    produit_nom,
    quantite_vendue,
    rang
FROM classement
WHERE rang <= 3
ORDER BY mois, rang;

-- Produits présents au moins 2 fois dans ces tops mensuels
WITH ventes_mensuelles AS (
    SELECT
        DATE_TRUNC('month', c.date_commande) AS mois,
        p.id AS produit_id,
        p.nom AS produit_nom,
        SUM(lc.quantite) AS quantite_vendue
    FROM ligne_commande lc
    JOIN commande c ON c.id = lc.commande_id
    JOIN produit p ON p.id = lc.produit_id
    WHERE c.statut <> 'annulée'
    GROUP BY DATE_TRUNC('month', c.date_commande), p.id, p.nom
),
classement AS (
    SELECT
        mois,
        produit_id,
        produit_nom,
        RANK() OVER (PARTITION BY mois ORDER BY quantite_vendue DESC) AS rang
    FROM ventes_mensuelles
)
SELECT
    produit_nom,
    COUNT(*) AS nb_apparitions_top3
FROM classement
WHERE rang <= 3
GROUP BY produit_id, produit_nom
HAVING COUNT(*) >= 2
ORDER BY nb_apparitions_top3 DESC, produit_nom;


/* ---------------------------------------------------------------------
ANALYSE 5 — Fidélisation et réachat
Question : quelle proportion des clients actifs a passé plusieurs
commandes ?
Données : commande.client_id et commande.statut.
Intérêt : mesurer la fidélité et guider les actions de rétention.
--------------------------------------------------------------------- */
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
    ) AS taux_de_reachat_pct
FROM commandes_valides;

/*
Observations : 90 clients actifs, dont 88 ont recommandé, soit 97,78 %.
La clientèle est très fidèle ; ce taux peut servir à prévoir le volume
de commandes récurrentes et à cibler les rares clients non fidélisés.
*/


/* ---------------------------------------------------------------------
ANALYSE 6 — Effet des promotions par catégorie
Question : dans quelles catégories les prix payés sont-ils les plus
inférieurs au prix catalogue actuel ?
Données : produit.prix, ligne_commande.prix_unitaire, quantite, statut.
Intérêt : mesurer l'effort promotionnel par catégorie.
--------------------------------------------------------------------- */
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
    COUNT(*) FILTER (WHERE lc.prix_unitaire < p.prix) AS lignes_avec_remise
FROM ligne_commande lc
JOIN commande c ON c.id = lc.commande_id
JOIN produit p ON p.id = lc.produit_id
WHERE c.statut <> 'annulée'
GROUP BY p.categorie
ORDER BY remise_moyenne_ponderee_pct DESC;

/*
Observations : la remise moyenne pondérée est la plus élevée en Sport
(6,95 %), puis Maison (6,23 %) et Mode (6,16 %). L'économie totale
représente le montant théoriquement non encaissé par rapport aux prix
catalogue actuels.
*/


/* ---------------------------------------------------------------------
ANALYSE 7 — Produits vendus avec un stock critique
Question : quels produits se vendent alors que leur stock est nul ou
inférieur ou égal à 10 unités ?
Données : produit.stock et quantités des lignes de commande valides.
Intérêt : prioriser le réapprovisionnement.
--------------------------------------------------------------------- */
SELECT
    p.id,
    p.nom,
    p.categorie,
    p.stock,
    SUM(lc.quantite) AS quantite_vendue,
    CASE
        WHEN p.stock = 0 THEN 'Rupture de stock'
        ELSE 'Stock critique'
    END AS niveau_alerte
FROM produit p
JOIN ligne_commande lc ON lc.produit_id = p.id
JOIN commande c ON c.id = lc.commande_id
WHERE p.stock <= 10
  AND c.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie, p.stock
ORDER BY p.stock, quantite_vendue DESC;

/*
Observations : 3 produits sont à stock nul mais ont été vendus,
notamment Lampe 2 (66 unités) et Souris 2 (43 unités) : risque de
rupture immédiat, réapprovisionnement prioritaire.
*/


/* ---------------------------------------------------------------------
ANALYSE 8 — Chiffre d'affaires selon le jour de la semaine
Question : quels jours concentrent le plus de chiffre d'affaires ?
Données : commande.date_commande, statut et montants des lignes.
Intérêt : planifier campagnes, effectifs et stocks.
--------------------------------------------------------------------- */
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
GROUP BY numero_jour, jour_semaine
ORDER BY chiffre_affaires DESC;

/*
Observations : le vendredi est le jour le plus contributeur
(110 257,28 €), le samedi le moins (79 101,51 €).
*/