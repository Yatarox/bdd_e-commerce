
CREATE DATABASE e_commerce;
\c e_commerce;

CREATE TABLE IF NOT EXISTS client (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    ville VARCHAR(255) NOT NULL,
    date_inscription DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS produit (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    categorie VARCHAR(255) NOT NULL,
    prix NUMERIC(10, 2) NOT NULL,
    stock INT NOT NULL
);

CREATE TABLE IF NOT EXISTS commande (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id INT NOT NULL,
    date_commande DATE NOT NULL,
    statut VARCHAR(20) NOT NULL,
    FOREIGN KEY (client_id) REFERENCES client(id),
    CONSTRAINT commande_status_check
        CHECK (statut IN ('payée', 'expédiée', 'livrée', 'annulée'))
);

CREATE TABLE IF NOT EXISTS ligne_commande (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    commande_id INT NOT NULL,
    produit_id INT NOT NULL,
    quantite INT NOT NULL,
    prix_unitaire NUMERIC(10, 2) NOT NULL,
    FOREIGN KEY (commande_id) REFERENCES commande(id),
    FOREIGN KEY (produit_id) REFERENCES produit(id)
);