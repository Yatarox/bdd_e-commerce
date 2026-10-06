# Base de données e-commerce

Projet PostgreSQL contenant le schéma, les données d'exemple et les requêtes
d'analyse des exercices 1 à 15 ainsi que la partie d'analyse libre.

## Prérequis

Deux modes d'exécution sont disponibles :

- PostgreSQL installé localement, avec la commande `psql` ;
- Docker.

Les fichiers SQL sont enregistrés en UTF-8 afin de préserver les accents des
statuts de commande.

## Installation avec PostgreSQL natif

### 1. Créer la base et les tables

Depuis le dossier du projet, connecté à une instance PostgreSQL :

```powershell
psql -U postgres -f .\schema.sql
```

Le script crée la base `e_commerce`, s'y connecte et crée les quatre tables :
`client`, `produit`, `commande` et `ligne_commande`.

Le mot de passe peut être demandé par PostgreSQL. Si le serveur n'est pas sur
la machine locale, ajouter `-h` et éventuellement `-p` à la commande.

### 2. Charger les données

```powershell
psql -U postgres -d e_commerce -v ON_ERROR_STOP=1 -f .\data.sql
```

L'option `ON_ERROR_STOP=1` arrête le chargement dès la première erreur.

### 3. Exécuter les analyses

```powershell
psql -U postgres -d e_commerce -f .\analysis.sql
```

Les résultats des exercices 11, 12 et 13 sont affichés successivement dans
le terminal. Le fichier [analysis.sql](./analysis.sql) regroupe les analyses.

## Installation avec Docker

### 1. Construire l'image

```powershell
docker build -t e-commerce-db .
```

### 2. Démarrer PostgreSQL

```powershell
docker run --name e-commerce-postgres `
  -e POSTGRES_USER=postgres `
  -e POSTGRES_PASSWORD=postgres `
  -e POSTGRES_DB=e_commerce `
  -p 5432:5432 `
  -v e-commerce-data:/var/lib/postgresql/data `
  -d e-commerce-db
```

Le `Dockerfile` copie `schema.sql` et `data.sql` dans
`/docker-entrypoint-initdb.d/`. Ils sont donc exécutés automatiquement lors
de la première création du volume.

### 3. Vérifier le démarrage

```powershell
docker logs e-commerce-postgres
```

### 4. Exécuter les analyses

```powershell
docker cp .\analysis.sql e-commerce-postgres:/tmp/analysis.sql
docker exec e-commerce-postgres `
  psql -U postgres -d e_commerce -f /tmp/analysis.sql
```

Ou ouvrir une session PostgreSQL :

```powershell
docker exec -it e-commerce-postgres psql -U postgres -d e_commerce
```

Puis exécuter dans `psql` :

```sql
\i /chemin/vers/analysis.sql
```

La première méthode est recommandée sous Windows, car elle transmet
directement le fichier local au conteneur.

### Réinitialiser la base Docker

Les scripts d'initialisation ne sont pas rejoués si le volume existe déjà.
Pour repartir de zéro :

```powershell
docker rm -f e-commerce-postgres
docker volume rm e-commerce-data
```

Puis reconstruire et relancer le conteneur avec les commandes précédentes.

## Principales conclusions

Sur le jeu de données fourni (100 clients, 65 produits, 500 commandes et
1 547 lignes de commande) :

- 103 commandes sont classées comme petits paniers, 206 comme paniers moyens
  et 191 comme gros paniers, selon les seuils de 500 € et 1 500 € ;
- le chiffre d'affaires calculé à partir des lignes de commande est de
  638 774,69 € ;
- le regroupement mensuel permet de comparer l'activité commerciale au cours
  de l'année 2025 ;
- 30 commandes sont antérieures à la date d'inscription de leur client.
  Elles constituent donc des incohérences de données à contrôler.

Les résultats détaillés sont produits directement par
[analysis.sql](./analysis.sql).
