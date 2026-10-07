# Base de données e-commerce

Projet PostgreSQL consacré à la modélisation, au chargement et à l'analyse
d'une base de données e-commerce.

## Contenu du dépôt

```text
.
├── create_schema.sql
├── seed_ecommerce.sql
├── analysis.sql
├── Dockerfile
└── docker_cmd.txt
```

- `create_schema.sql` crée la base `e_commerce`, les tables, les contraintes et
  les index.
- `seed_ecommerce.sql` insère le jeu de données fourni.
- `analysis.sql` contient les requêtes des exercices 1 à 15 ainsi que les
  analyses complémentaires.
- `Dockerfile` et `docker_cmd.txt` contiennent la configuration et les
  commandes prévues pour une exécution avec Docker.

## Modèle de données

La base contient quatre tables :

| Table | Description |
| --- | --- |
| `client` | Clients de la plateforme |
| `produit` | Produits du catalogue |
| `commande` | Commandes passées par les clients |
| `ligne_commande` | Produits et quantités associés à chaque commande |

Les principales contraintes sont les suivantes :

- chaque client possède une adresse e-mail unique ;
- une commande est associée à un client existant ;
- une ligne de commande référence une commande et un produit existants ;
- les quantités, les prix et les stocks ne peuvent pas être négatifs ;
- le statut d'une commande est limité à `payée`, `expédiée`, `livrée` ou
  `annulée` ;
- le prix unitaire est conservé dans `ligne_commande` afin de garder le prix
  réellement appliqué lors de la commande, même si le prix du catalogue change.

Le montant d'une ligne est calculé ainsi :

```text
quantite × prix_unitaire
```

Les commandes annulées sont exclues des calculs de chiffre d'affaires, de
quantités vendues et de panier moyen.

## Prérequis

- PostgreSQL 16 ou une version compatible ;
- la commande `psql` disponible dans le `PATH` ;
- les fichiers SQL enregistrés en UTF-8.

## Installation avec PostgreSQL

Depuis le dossier du projet, créer le schéma :

```powershell
psql -U postgres -f .\create_schema.sql
```

Le script crée la base `e_commerce` si nécessaire, s'y connecte et recrée les
quatre tables.

Charger ensuite les données :

```powershell
psql -U postgres -d e_commerce -v ON_ERROR_STOP=1 -f .\seed_ecommerce.sql
```

L'option `ON_ERROR_STOP=1` arrête l'exécution dès la première erreur.

Si PostgreSQL est installé sur un autre hôte ou utilise un autre port, ajouter
les options correspondantes, par exemple `-h localhost -p 5432`.

## Vérifier le chargement

```powershell
psql -U postgres -d e_commerce
```

Puis exécuter :

```sql
SELECT 'client' AS table_name, COUNT(*) AS row_count FROM client
UNION ALL
SELECT 'produit', COUNT(*) FROM produit
UNION ALL
SELECT 'commande', COUNT(*) FROM commande
UNION ALL
SELECT 'ligne_commande', COUNT(*) FROM ligne_commande;
```

Le jeu de données fourni contient normalement :

| Table | Nombre de lignes |
| --- | ---: |
| `client` | 100 |
| `produit` | 65 |
| `commande` | 500 |
| `ligne_commande` | 1 547 |

## Exécuter les analyses

```powershell
psql -U postgres -d e_commerce -v ON_ERROR_STOP=1 -f .\analysis.sql
```

Le fichier couvre notamment :

1. l'exploration des produits, des clients et des commandes ;
2. le calcul des montants par ligne et par commande ;
3. le chiffre d'affaires par catégorie et par produit ;
4. le panier moyen et la segmentation des commandes ;
5. l'analyse temporelle du chiffre d'affaires ;
6. le contrôle de la qualité des données ;
7. la production de synthèses commerciales et de tableaux de bord ;
8. des analyses complémentaires sur les clients, les annulations et les
   produits.

## Utilisation avec Docker

Les commandes prévues sont disponibles dans
[`docker_cmd.txt`](./docker_cmd.txt). Elles permettent de construire l'image,
de démarrer PostgreSQL et d'ouvrir une session `psql` dans le conteneur.

```powershell
docker build -t e-commerce-db .
docker run --name e-commerce-postgres `
  -e POSTGRES_USER=postgres `
  -e POSTGRES_PASSWORD=postgres `
  -e POSTGRES_DB=e_commerce `
  -p 5432:5432 `
  -v e-commerce-data:/var/lib/postgresql/data `
  -d e-commerce-db
```

Pour ouvrir une session SQL dans le conteneur :

```powershell
docker exec -it e-commerce-postgres psql -U postgres -d e_commerce
```
