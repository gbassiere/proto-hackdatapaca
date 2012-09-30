-- Créer le schéma de la grille de visualisation
CREATE TABLE grid (
    id serial PRIMARY KEY,
    cell geometry(Polygon, 3857) NOT NULL,
    ecole1 smallint DEFAULT 0,
    ecole2 smallint DEFAULT 0,
    ecole3 smallint DEFAULT 0,
    ecole4 smallint DEFAULT 0,
    culte_mu smallint DEFAULT 0,
    culte_ch smallint DEFAULT 0,
    culte_ju smallint DEFAULT 0,
    velo smallint DEFAULT 0
);

-- Créer les cellules de la grille de visualisation (couvrant Marseille avec une maille de 500m)
DO LANGUAGE plpgsql $$
DECLARE
    xmin integer := 587000;
    ymin integer := 5344000;
    xmax integer := 616000;
    ymax integer := 5371000;
    step integer := 500;
    x integer;
    y integer;
    query text;
BEGIN
    x := xmin;
    LOOP
        y := ymin;
        LOOP
            query := format('INSERT INTO grid (cell) VALUES (''SRID=3857;POLYGON((%1$s %2$s, %1$s %4$s, %3$s %4$s, %3$s %2$s, %1$s %2$s))''::geometry)', x, y, x+step, y+step);
            EXECUTE query;
            y := y + step;
            EXIT WHEN y >= ymax;
        END LOOP;
        x := x + step;
        EXIT WHEN x >= xmax;
    END LOOP;
END;
$$;

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
    total :=
        CASE WHEN ec1_ok = 1 THEN ec1_val ELSE 0 END +
        CASE WHEN ec2_ok = 1 THEN ec2_val ELSE 0 END +
        CASE WHEN ec3_ok = 1 THEN ec3_val ELSE 0 END +
        CASE WHEN ec4_ok = 1 THEN ec4_val ELSE 0 END +
        CASE WHEN cum_ok = 1 THEN cum_val ELSE 0 END +
        CASE WHEN cuc_ok = 1 THEN cuc_val ELSE 0 END +
        CASE WHEN cuj_ok = 1 THEN cuj_val ELSE 0 END;
    RETURN (total/coef)::smallint;
END;
$$ LANGUAGE plpgsql;
