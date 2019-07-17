DROP DATABASE IF EXISTS qoe_db;

CREATE DATABASE qoe_db;

\connect qoe_db;

DROP USER IF EXISTS qoe_user;
	
CREATE USER qoe_user WITH ENCRYPTED PASSWORD 'MPCLGP5432!';

GRANT ALL PRIVILEGES ON DATABASE qoe_db TO qoe_user;

DROP TABLE IF EXISTS measure;

CREATE TABLE public.measure (
	datetime timestamp NOT NULL,
	parameter varchar NOT NULL,
	value float4 NOT NULL,
	id serial NOT NULL UNIQUE PRIMARY KEY,
	groupid UUID not NULL
);

GRANT ALL PRIVILEGES ON TABLE measure TO qoe_user;

GRANT ALL PRIVILEGES ON SEQUENCE measure_id_seq TO qoe_user;
