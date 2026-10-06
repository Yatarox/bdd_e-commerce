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