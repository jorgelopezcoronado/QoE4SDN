-- Drop table

-- DROP TABLE public.measure;

CREATE TABLE public.measure (
	datetime timestamp NOT NULL,
	"parameter" varchar NOT NULL,
	value float4 NOT NULL,
	id serial NOT NULL UNIQUE PRIMARY KEY,
	groupid UUID not NULL
);
