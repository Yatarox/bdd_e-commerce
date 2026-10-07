\encoding UTF8

SELECT 'CREATE DATABASE e_commerce WITH ENCODING = ''UTF8'' TEMPLATE = template0'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'e_commerce')\gexec

\connect e_commerce

-- Nettoyage (ordre inverse des dépendances)
DROP TABLE IF EXISTS ligne_commande CASCADE;
DROP TABLE IF EXISTS commande CASCADE;
DROP TABLE IF EXISTS produit CASCADE;
DROP TABLE IF EXISTS client CASCADE;

CREATE TABLE client (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    ville VARCHAR(255) NOT NULL,
    date_inscription DATE NOT NULL
);

CREATE TABLE produit (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    categorie VARCHAR(255) NOT NULL,
    prix NUMERIC(10, 2) NOT NULL CHECK (prix >= 0),
    stock INT NOT NULL CHECK (stock >= 0)
);

CREATE TABLE commande (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id INT NOT NULL,
    date_commande DATE NOT NULL,
    statut VARCHAR(20) NOT NULL,
    CONSTRAINT commande_client_fk
        FOREIGN KEY (client_id) REFERENCES client(id),
    CONSTRAINT commande_status_check
        CHECK (statut IN ('payée', 'expédiée', 'livrée', 'annulée'))
);

CREATE TABLE ligne_commande (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    commande_id INT NOT NULL,
    produit_id INT NOT NULL,
    quantite INT NOT NULL CHECK (quantite > 0),
    prix_unitaire NUMERIC(10, 2) NOT NULL CHECK (prix_unitaire >= 0),
    CONSTRAINT ligne_commande_commande_fk
        FOREIGN KEY (commande_id) REFERENCES commande(id),
    CONSTRAINT ligne_commande_produit_fk
        FOREIGN KEY (produit_id) REFERENCES produit(id)
);

CREATE INDEX idx_commande_client ON commande(client_id);
CREATE INDEX idx_ligne_commande_commande ON ligne_commande(commande_id);
CREATE INDEX idx_ligne_commande_produit ON ligne_commande(produit_id);