/*
   PARTIE 7 - ANALYSE LIBRE
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
    p.id AS produit_id,
    p.nom AS produit,
    p.categorie,
    p.stock,
    COALESCE(SUM(lc.quantite), 0) AS quantite_vendue,
    ROUND(COALESCE(SUM(lc.quantite * lc.prix_unitaire), 0), 2)
        AS chiffre_affaires,
    CASE
        WHEN p.stock = 0 THEN 'Rupture de stock'
        ELSE 'Stock critique'
    END AS niveau_alerte
FROM produit p
LEFT JOIN ligne_commande lc ON lc.produit_id = p.id
LEFT JOIN commande c
    ON c.id = lc.commande_id
   AND c.statut <> 'annulée'
WHERE p.stock <= 10
GROUP BY p.id, p.nom, p.categorie, p.stock
HAVING COALESCE(SUM(CASE WHEN c.id IS NOT NULL THEN lc.quantite ELSE 0 END), 0) > 0
ORDER BY p.stock, quantite_vendue DESC;

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
