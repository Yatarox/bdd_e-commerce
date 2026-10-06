PARTIE 7 — ANALYSE LIBRE (INDICATEURS ET OBSERVATIONS MÉTIER SUPPLÉMENTAIRES)


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
Les écarts de CA proviennent donc uniquement du panier global et de la fréquence d'achat, et non de la taille de la base client locale.
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