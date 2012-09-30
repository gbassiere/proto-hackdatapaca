CREATE TABLE grid (
    id serial PRIMARY KEY,
    cell geometry(Polygon, 3857) NOT NULL,
    ecole1 smallint DEFAULT 0,
    ecole2 smallint DEFAULT 0,
    ecole3 smallint DEFAULT 0,
    ecole4 smallint DEFAULT 0,
    culte_mu smallint DEFAULT 0,
    culte_ch smallint DEFAULT 0,
    culte_ju smallint DEFAULT 0
);

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
