FROM postgres:16-alpine

ENV POSTGRES_DB=e_commerce
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres

COPY create_schema.sql /docker-entrypoint-initdb.d/01-schema.sql
COPY seed_data.sql /docker-entrypoint-initdb.d/02-data.sql

EXPOSE 5432
