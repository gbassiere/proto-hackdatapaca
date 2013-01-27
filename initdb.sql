-- Copyright © 2012 Gilles Bassière
-- This work is free. You can redistribute it and/or modify it under the
-- terms of the Do What The Fuck You Want To Public License, Version 2,
-- as published by Sam Hocevar. See the COPYING file for more details.

-- Créer le schéma de la grille de visualisation
CREATE TABLE grid (
    id serial PRIMARY KEY,
    ecole1 smallint DEFAULT 0,
    ecole2 smallint DEFAULT 0,
    ecole3 smallint DEFAULT 0,
    ecole4 smallint DEFAULT 0,
    culte_mu smallint DEFAULT 0,
    culte_ch smallint DEFAULT 0,
    culte_ju smallint DEFAULT 0,
    velo smallint DEFAULT 0
);

SELECT AddGeometryColumn('grid', 'cell', 3857, 'POLYGON', 2);

-- Fonction facilitant l'écriture de la requête de visualisation
CREATE OR REPLACE FUNCTION get_cell_value(ec1_val smallint, ec2_val smallint, ec3_val smallint, ec4_val smallint, cum_val smallint, cuc_val smallint, cuj_val smallint, vel_val smallint, ec1_ok integer, ec2_ok integer, ec3_ok integer, ec4_ok integer, cum_ok integer, cuc_ok integer, cuj_ok integer, vel_ok integer) RETURNS smallint AS $$
DECLARE
    total integer;
    coef integer;
BEGIN
    coef := ec1_ok + ec2_ok + ec3_ok + ec4_ok + cum_ok + cuc_ok + cuj_ok + vel_ok;
    IF coef = 0 THEN
        RETURN 0;
    END IF;
    total := ec1_ok * ec1_val + ec2_ok * ec2_val + ec3_ok * ec3_val + ec4_ok * ec4_val + cum_ok * cum_val + cuc_ok * cuc_val + cuj_ok * cuj_val + vel_ok * vel_val;
    RETURN (total/coef)::smallint;
END;
$$ LANGUAGE plpgsql;
