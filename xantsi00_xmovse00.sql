DROP TABLE "Zlodej" CASCADE CONSTRAINTS;

DROP TABLE "Rajon" CASCADE CONSTRAINTS;

DROP TABLE "Zlodej_v_rajone" CASCADE CONSTRAINTS;

DROP TABLE "Typ_zlocinu" CASCADE CONSTRAINTS;

DROP TABLE "Zlodej_byl_proskolen_pro_typ_zlocinu" CASCADE CONSTRAINTS;

DROP TABLE "Zlocin" CASCADE CONSTRAINTS;

DROP TABLE "Povoleni" CASCADE CONSTRAINTS;

DROP TABLE "Zlodej_ziskal_povoleni" CASCADE CONSTRAINTS;

DROP TABLE "Zlodej_provedl_zlocin" CASCADE CONSTRAINTS;

DROP TABLE "Zlocin_byl_proveden_v_rajone" CASCADE CONSTRAINTS;

DROP TABLE "Typ_vybaveni" CASCADE CONSTRAINTS;

DROP TABLE "Zlodej_byl_proskolen_pro_typ_vybaveni" CASCADE CONSTRAINTS;

DROP TABLE "Typ_zlocinu_vyzaduje_typ_vybaveni" CASCADE CONSTRAINTS;

DROP TABLE "Vybaveni" CASCADE CONSTRAINTS;

DROP TABLE "Zlodej_vlastni_vybaveni_v_dobe" CASCADE CONSTRAINTS;

CREATE TABLE "Zlodej" (
 -- malá změna oproti ER: místo ID jsme zavedli rodné číslo pro implementaci speciálního omezení hodnot
    "rodne_cislo" INT NOT NULL PRIMARY KEY,
    "realne_jmeno" VARCHAR(256) DEFAULT NULL,
    "prezdivka" VARCHAR(256) NOT NULL,
 -- malá změna oproti ER: místo věku jsme zavedli datum narození
    "datum_narozeni" DATE NOT NULL,
 -- velká změna oproti ER: v hodnocení ER bylo řečeno, že mrtvý a živý zloděje
 -- není vhodná specializace, takže jsme to odstranily a přidaly specializace
 -- typu zlocinu na krádež a loupež, viz entita Typ_zlocinu
    "datum_umrti" DATE DEFAULT NULL,
    "vypsana_odmena" INT DEFAULT NULL,
 -- determinace omezení tvaru rodného čísla
    CONSTRAINT "je_validni_RC" CHECK ((MOD("rodne_cislo", 11) = 0) AND NOT (REGEXP_LIKE(TO_CHAR("rodne_cislo"), '[^0-9]')) AND (LENGTH(TO_CHAR("rodne_cislo")) BETWEEN 9 AND 10) AND (LENGTH(TO_CHAR("rodne_cislo")) != 9 OR SUBSTR(TO_CHAR("rodne_cislo"), -3) != '000' ) AND (CAST(SUBSTR(TO_CHAR("rodne_cislo"), 5, 2) AS INT) BETWEEN 0 AND 99) AND (CAST(SUBSTR(TO_CHAR("rodne_cislo"), 3, 2) AS INT)BETWEEN 1 AND 12) OR (CAST(SUBSTR(TO_CHAR("rodne_cislo"), 3, 2) AS INT)BETWEEN 50 AND 62) AND (CAST(SUBSTR(TO_CHAR("rodne_cislo"), 1, 2) AS INT)BETWEEN 1 AND 31))
);

CREATE TABLE "Rajon" (
    "kod" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "nazev" VARCHAR(256) NOT NULL,
    "pozice" VARCHAR(256) NOT NULL,
    "pocet_lidi" INT NOT NULL,
    "dostupne_bohatstvi" INT NOT NULL,
    "kapacita_zlodeju" INT NOT NULL
);

-- vztahy mnoho-mnoho jsme implementovaly jako zvlastni tabulku
CREATE TABLE "Zlodej_v_rajone" (
    "RC_zlodeje" INT NOT NULL,
    "kod_rajonu" INT NOT NULL,
    CONSTRAINT "kod_zlodej_rajon" PRIMARY KEY ("RC_zlodeje", "kod_rajonu"),
    CONSTRAINT "rajon_cizi_klic_zlodej" FOREIGN KEY ("kod_rajonu") REFERENCES "Rajon" ("kod") ON DELETE CASCADE,
    CONSTRAINT "zlodej_cizi_klic_rajon" FOREIGN KEY ("RC_zlodeje") REFERENCES "Zlodej" ("rodne_cislo") ON DELETE CASCADE
);

CREATE TABLE "Typ_zlocinu" (
    "kod" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "nazev_typu" VARCHAR(256) NOT NULL,
    "popis" VARCHAR(256) NOT NULL,
    "mira_obtiznosti_provedeni" INT NOT NULL,
    "mira_obtiznosti_proskoleni" INT NOT NULL,
    -- Na základě textu zprávy hodnocení ER jsme rozhodly odstranit specializace
    -- na živého a mrtvého zlodeje a zavest specializace typu zločinu na dva nadtypy
    -- - krádež a loupež, kdy u krádeže bude zaveden atribut "požadovaná úroveň dovedností 
    -- nepřitahovat pozornost", a u loupeže atribut "požadovaná úroveň síly"
    -- jelikož všechny vztahy jsou společné pro krádež a loupež a
    -- specializace je úplná a disjunktní, rozdílných atributů je málo,
    -- bylo rozhodnuto vytvořit jednu tabulku
    -- krádež
    "požadovaná úroveň dovedností nepřitahovat pozornost" INT DEFAULT NULL,
    -- loupež
    "požadovaná úroveň síly" INT DEFAULT NULL,
    -- rozlišení specializací podle prázdné hodnoty
    CHECK ("požadovaná úroveň dovedností nepřitahovat pozornost" IS NULL OR "požadovaná úroveň síly" IS NULL),
    CHECK ("požadovaná úroveň dovedností nepřitahovat pozornost" IS NOT NULL OR "požadovaná úroveň síly" IS NOT NULL)  
);

CREATE TABLE "Zlodej_byl_proskolen_pro_typ_zlocinu" (
    "RC_zlodeje" INT NOT NULL,
    "kod_typu_zlocinu" INT NOT NULL,
    CONSTRAINT "kod_skoleni_zlodeje_pro_typ_zlocinu" PRIMARY KEY ("RC_zlodeje", "kod_typu_zlocinu"),
    CONSTRAINT "zlodej_cizi_klic_skoleni_zlocin" FOREIGN KEY ("RC_zlodeje") REFERENCES "Zlodej" ("rodne_cislo") ON DELETE CASCADE,
    CONSTRAINT "skoleni_cizi_klic_zlocin" FOREIGN KEY ("kod_typu_zlocinu") REFERENCES "Typ_zlocinu" ("kod") ON DELETE CASCADE
);

CREATE TABLE "Zlocin" (
    "kod" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "datum" DATE NOT NULL,
    "popis" VARCHAR(256) NOT NULL,
    "mira_obtiznosti" INT NOT NULL,
    "korist" INT DEFAULT NULL,
    "kod_typu" INT NOT NULL,
    CONSTRAINT "zlocin_entita_cizi_klic" FOREIGN KEY ("kod_typu") REFERENCES "Typ_zlocinu" ("kod") ON DELETE CASCADE
);

CREATE TABLE "Povoleni" (
    "kod" INT GENERATED AS IDENTITY NOT NULL,
    "kod_typu" INT NOT NULL, --kod typu zlocinu 
    "kod_zlocinu" DEFAULT NULL, --id samotneho zlocinu
    CONSTRAINT "kod_povoleni_entita" PRIMARY KEY ("kod", "kod_typu"),
    CONSTRAINT "povoleni_cizi_klic_typ" FOREIGN KEY ("kod_typu") REFERENCES "Typ_zlocinu" ("kod") ON DELETE CASCADE,
    CONSTRAINT "povoleni_cizi_klic_zlocin" FOREIGN KEY ("kod_zlocinu") REFERENCES "Zlocin" ("kod") ON DELETE CASCADE
);

CREATE TABLE "Zlodej_ziskal_povoleni" (
    "RC_zlodeje" INT NOT NULL,
    "kod_povoleni" INT NOT NULL, --id povoleni
    "kod_typu" INT NOT NULL,  
    CONSTRAINT "kod_povoleni_zlodeje" PRIMARY KEY ("RC_zlodeje", "kod_povoleni"),
    CONSTRAINT "zlodej_cizi_klic_povoleni" FOREIGN KEY ("RC_zlodeje") REFERENCES "Zlodej" ("rodne_cislo") ON DELETE CASCADE,
    CONSTRAINT "povoleni_vazba_cizi_klic" FOREIGN KEY ("kod_povoleni", "kod_typu") REFERENCES "Povoleni" ("kod", "kod_typu") ON DELETE CASCADE
);

CREATE TABLE "Zlodej_provedl_zlocin" (
    "RC_zlodeje" INT NOT NULL,
    "kod_zlocinu" INT NOT NULL,
    CONSTRAINT "kod_zlocinu_zlodeje" PRIMARY KEY ("RC_zlodeje", "kod_zlocinu"),
    CONSTRAINT "zlodej_cizi_klic_zlocin" FOREIGN KEY ("RC_zlodeje") REFERENCES "Zlodej" ("rodne_cislo") ON DELETE CASCADE,
    CONSTRAINT "zlocin_vazba_cizi_klic" FOREIGN KEY ("kod_zlocinu") REFERENCES "Zlocin" ("kod") ON DELETE CASCADE
);

CREATE TABLE "Zlocin_byl_proveden_v_rajone" (
    "kod_zlocinu" INT NOT NULL,
    "kod_rajonu" INT NOT NULL,
    CONSTRAINT "kod_zlocin_rajon" PRIMARY KEY ("kod_zlocinu", "kod_rajonu"),
    CONSTRAINT "rajon_cizi_klic_zlocin" FOREIGN KEY ("kod_rajonu") REFERENCES "Rajon" ("kod") ON DELETE CASCADE,
    CONSTRAINT "zlocin_cizi_klic_rajon" FOREIGN KEY ("kod_zlocinu") REFERENCES "Zlocin" ("kod") ON DELETE CASCADE
);

CREATE TABLE "Typ_vybaveni" (
    "kod" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "nazev_typu" VARCHAR(256) NOT NULL
);

CREATE TABLE "Zlodej_byl_proskolen_pro_typ_vybaveni" (
    "RC_zlodeje" INT NOT NULL,
    "kod_typu_vybaveni" INT NOT NULL,
    CONSTRAINT "kod_skoleni_zlodeje_pro_vybaveni" PRIMARY KEY ("RC_zlodeje", "kod_typu_vybaveni"),
    CONSTRAINT "zlodej_cizi_klic_skoleni_vybaveni" FOREIGN KEY ("RC_zlodeje") REFERENCES "Zlodej" ("rodne_cislo") ON DELETE CASCADE,
    CONSTRAINT "skoleni_cizi_klic_vybaveni" FOREIGN KEY ("kod_typu_vybaveni") REFERENCES "Typ_vybaveni" ("kod") ON DELETE CASCADE
);

CREATE TABLE "Typ_zlocinu_vyzaduje_typ_vybaveni" (
    "kod_typu_zlocinu" INT NOT NULL,
    "kod_typu_vybaveni" INT NOT NULL,
    CONSTRAINT "kod_typu_zlocinu_pro_typ_vybaveni" PRIMARY KEY ("kod_typu_zlocinu", "kod_typu_vybaveni"),
    CONSTRAINT "zlocin_typ_cizi_klic" FOREIGN KEY ("kod_typu_zlocinu") REFERENCES "Zlocin" ("kod") ON DELETE CASCADE,
    CONSTRAINT "vybaveni_typ_cizi_klic" FOREIGN KEY ("kod_typu_vybaveni") REFERENCES "Typ_vybaveni" ("kod") ON DELETE CASCADE
);

CREATE TABLE "Vybaveni" (
    "kod" INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    "nazev" VARCHAR(256) NOT NULL,
    "popis" VARCHAR(256) NOT NULL,
    "kod_typu" INT NOT NULL,
    CONSTRAINT "vybaveni_entita_cizi_klic" FOREIGN KEY ("kod_typu") REFERENCES "Typ_vybaveni" ("kod") ON DELETE CASCADE
);

CREATE TABLE "Zlodej_vlastni_vybaveni_v_dobe" (
    "RC_zlodeje" INT NOT NULL,
    "kod_vybaveni" INT NOT NULL,
    "zacatek" DATE NOT NULL,
    "konec" DATE DEFAULT NULL,
    CONSTRAINT "kod_vlastnictvi_vybaveni" PRIMARY KEY ("RC_zlodeje", "kod_vybaveni"),
    CONSTRAINT "zlodej_cizi_klic_vlastnictvi_vybaveni" FOREIGN KEY ("RC_zlodeje") REFERENCES "Zlodej" ("rodne_cislo") ON DELETE CASCADE,
    CONSTRAINT "vybaveni_cizi_klic_vlastnictvi" FOREIGN KEY ("kod_vybaveni") REFERENCES "Vybaveni" ("kod") ON DELETE CASCADE
);

--insert
INSERT INTO "Zlodej" (
    "rodne_cislo",
    "realne_jmeno",
    "prezdivka",
    "datum_narozeni"
) VALUES (
    '540312113',
    'Otto Smith',
    'Krtek',
    TO_DATE('1954-03-12', 'YYYY-MM-DD')
);

INSERT INTO "Zlodej" (
    "rodne_cislo",
    "realne_jmeno",
    "prezdivka",
    "datum_narozeni",
    "vypsana_odmena"
) VALUES (
    '450123124',
    'Carlo Perecz',
    'Kmotr',
    TO_DATE('1945-01-23', 'YYYY-MM-DD'),
    '10000000'
);

INSERT INTO "Zlodej" (
    "rodne_cislo",
    "prezdivka",
    "datum_narozeni",
    "datum_umrti"
) VALUES (
    '941201129',
    'Sipava',
    TO_DATE('1994-12-01', 'YYYY-MM-DD'),
    TO_DATE('2021-05-29', 'YYYY-MM-DD')
);

INSERT INTO "Zlodej" (
    "rodne_cislo",
    "realne_jmeno",
    "prezdivka",
    "datum_narozeni",
    "vypsana_odmena"
) VALUES (
    '700413098',
    'Alfred Fritz',
    'Bytar',
    TO_DATE('1970-04-13', 'YYYY-MM-DD'),
    '50000'
);

INSERT INTO "Zlodej" (
    "rodne_cislo",
    "prezdivka",
    "datum_narozeni"
) VALUES (
    '9910050040',
    'Ctverak',
    TO_DATE('1999-10-05', 'YYYY-MM-DD')
);


INSERT INTO "Rajon" (
    "nazev",
    "pozice",
    "pocet_lidi",
    "dostupne_bohatstvi",
    "kapacita_zlodeju"
) VALUES (
    'Chodov',
    'Jizni mesto',
    '10000',
    '250000',
    '18'
);

INSERT INTO "Rajon" (
    "nazev",
    "pozice",
    "pocet_lidi",
    "dostupne_bohatstvi",
    "kapacita_zlodeju"
) VALUES (
    'Opatov',
    'Jizni mesto',
    '7000',
    '150000',
    '15'
);

INSERT INTO "Rajon" (
    "nazev",
    "pozice",
    "pocet_lidi",
    "dostupne_bohatstvi",
    "kapacita_zlodeju"
) VALUES (
    'Roztyly',
    'Jizni mesto',
    '5800',
    '750000',
    '7'
);

INSERT INTO "Rajon" (
    "nazev",
    "pozice",
    "pocet_lidi",
    "dostupne_bohatstvi",
    "kapacita_zlodeju"
) VALUES (
    'Haje',
    'Jizni mesto',
    '6500',
    '100000',
    '10'
);

INSERT INTO "Rajon" (
    "nazev",
    "pozice",
    "pocet_lidi",
    "dostupne_bohatstvi",
    "kapacita_zlodeju"
) VALUES (
    'Mustek',
    'Stare mesto',
    '20000',
    '25000000',
    '55'
);


INSERT INTO "Zlodej_v_rajone"
    SELECT
        '540312113',
        "kod"
    FROM
        "Rajon"
    WHERE
        "nazev" = 'Chodov';

INSERT INTO "Zlodej_v_rajone"
    SELECT
        '540312113',
        "kod"
    FROM
        "Rajon"
    WHERE
        "nazev" = 'Opatov';

INSERT INTO "Zlodej_v_rajone"
    SELECT
        '700413098',
        "kod"
    FROM
        "Rajon"
    WHERE
        "nazev" = 'Opatov';

INSERT INTO "Zlodej_v_rajone"
    SELECT
        '450123124',
        "kod"
    FROM
        "Rajon"
    WHERE
        "nazev" = 'Chodov';

INSERT INTO "Zlodej_v_rajone"
    SELECT
        '9910050040',
        "kod"
    FROM
        "Rajon"
    WHERE
        "nazev" = 'Mustek';


INSERT INTO "Typ_zlocinu" (
    "nazev_typu",
    "popis",
    "mira_obtiznosti_provedeni",
    "mira_obtiznosti_proskoleni",
    "požadovaná úroveň dovedností nepřitahovat pozornost"
) VALUES (
    'Krádež peněženky',
    'Drobné krádeže z kapes cestujících DPMB a turistů na náměsti Svobody',
    '3',
    '6',
    '6'
);

INSERT INTO "Typ_zlocinu" (
    "nazev_typu",
    "popis",
    "mira_obtiznosti_provedeni",
    "mira_obtiznosti_proskoleni",
    "požadovaná úroveň dovedností nepřitahovat pozornost"
) VALUES (
    'Krádež kufru',
    'Krádež kufru na letišti a nádraží',
    '2',
    '3',
    '4'
);

INSERT INTO "Typ_zlocinu" (
    "nazev_typu",
    "popis",
    "mira_obtiznosti_provedeni",
    "mira_obtiznosti_proskoleni",
    "požadovaná úroveň dovedností nepřitahovat pozornost"
) VALUES (
    'Krádež indentity',
    'Krádež osobních údajů',
    '2',
    '3',
    '1'
);

INSERT INTO "Typ_zlocinu" (
    "nazev_typu",
    "popis",
    "mira_obtiznosti_provedeni",
    "mira_obtiznosti_proskoleni",
    "požadovaná úroveň síly"
) VALUES (
    'Loupež v bytě',
    'Násilní krádež v bytě',
    '5',
    '5', 
    '7'
);

INSERT INTO "Typ_zlocinu" (
    "nazev_typu",
    "popis",
    "mira_obtiznosti_provedeni",
    "mira_obtiznosti_proskoleni",
    "požadovaná úroveň dovedností nepřitahovat pozornost"
) VALUES (
    'Vydírání',
    'Vydírání od civilistů',
    '4',
    '4',
    '2'
);


INSERT INTO "Zlodej_byl_proskolen_pro_typ_zlocinu"
    SELECT
        '450123124',
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Krádež peněženky';

INSERT INTO "Zlodej_byl_proskolen_pro_typ_zlocinu"
    SELECT
        '450123124',
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Krádež kufru';

INSERT INTO "Zlodej_byl_proskolen_pro_typ_zlocinu"
    SELECT
        '540312113',
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Krádež kufru';

INSERT INTO "Zlodej_byl_proskolen_pro_typ_zlocinu"
    SELECT
        '941201129',
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Krádež indentity';

INSERT INTO "Zlodej_byl_proskolen_pro_typ_zlocinu"
    SELECT
        '941201129',
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Vydírání';


INSERT INTO "Zlocin" (
    "datum",
    "popis",
    "mira_obtiznosti",
    "korist",
    "kod_typu"
)
    SELECT
        TO_DATE('2024-03-16', 'YYYY-MM-DD'),
        'Ukradl babičce zlaté zuby',
        '5',
        '12000',
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Krádež peněženky';

INSERT INTO "Zlocin" (
    "datum",
    "popis",
    "mira_obtiznosti",
    "korist",
    "kod_typu"
)
    SELECT
        TO_DATE('2020-11-12', 'YYYY-MM-DD'),
        'Vymohl u může peníze',
        '2',
        '6000',
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Vydírání';

INSERT INTO "Zlocin" (
    "datum",
    "popis",
    "mira_obtiznosti",
    "korist",
    "kod_typu"
)
    SELECT
        TO_DATE('2021-06-08', 'YYYY-MM-DD'),
        'Vymohl u prodavačky peníze',
        '4',
        '25000',
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Vydírání';

INSERT INTO "Zlocin" (
    "datum",
    "popis",
    "mira_obtiznosti",
    "korist",
    "kod_typu"
)
    SELECT
        TO_DATE('2001-12-03', 'YYYY-MM-DD'),
        'Loupež v bytě 2+kk',
        '5',
        '15000',
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Loupež v bytě';

INSERT INTO "Zlocin" (
    "datum",
    "popis",
    "mira_obtiznosti",
    "korist",
    "kod_typu"
)
    SELECT
        TO_DATE('2012-11-23', 'YYYY-MM-DD'),
        'Ukradl kufr na letišti',
        '6',
        '30000',
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Krádež kufru';


INSERT INTO "Povoleni" (
    "kod_typu"
)
    SELECT
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Krádež peněženky';

INSERT INTO "Povoleni" (
    "kod_typu"
)
    SELECT
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Vydírání';

INSERT INTO "Povoleni" (
    "kod_typu"
)
    SELECT
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Krádež kufru';

INSERT INTO "Povoleni" (
    "kod_typu"
)
    SELECT
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Krádež indentity';

INSERT INTO "Povoleni" (
    "kod_typu"
)
    SELECT
        "kod"
    FROM
        "Typ_zlocinu"
    WHERE
        "nazev_typu" = 'Loupež v bytě';

INSERT INTO "Zlodej_ziskal_povoleni" (
    "RC_zlodeje",
    "kod_povoleni",
    "kod_typu"
) VALUES (
    540312113,
    3,
    2
);

INSERT INTO "Zlodej_ziskal_povoleni" (
    "RC_zlodeje",
    "kod_povoleni",
    "kod_typu"
) VALUES (
    9910050040,
    3,
    2
);

INSERT INTO "Zlodej_provedl_zlocin" (
    "RC_zlodeje", 
    "kod_zlocinu"   
) VALUES (
    '540312113', 
    1
);

INSERT INTO "Zlodej_provedl_zlocin" (
    "RC_zlodeje", 
    "kod_zlocinu"   
) VALUES (
    '540312113', 
    2
); 

INSERT INTO "Zlodej_provedl_zlocin" (
    "RC_zlodeje", 
    "kod_zlocinu"   
) VALUES (
    '9910050040', 
    3
); 

INSERT INTO "Zlodej_provedl_zlocin" (
    "RC_zlodeje", 
    "kod_zlocinu"   
) VALUES (
    '700413098', 
    3
); 

INSERT INTO "Zlodej_provedl_zlocin" (
    "RC_zlodeje", 
    "kod_zlocinu"   
) VALUES (
    '450123124', 
    4
); 

INSERT INTO "Zlodej_provedl_zlocin" (
    "RC_zlodeje", 
    "kod_zlocinu"   
) VALUES (
    '700413098', 
    5
); 

INSERT INTO "Zlocin_byl_proveden_v_rajone"
    SELECT
        '1',
        "kod"
    FROM
        "Rajon"
    WHERE
        "nazev" = 'Chodov';

INSERT INTO "Zlocin_byl_proveden_v_rajone"
    SELECT
        '2',
        "kod"
    FROM
        "Rajon"
    WHERE
        "nazev" = 'Opatov';

INSERT INTO "Zlocin_byl_proveden_v_rajone"
    SELECT
        '3',
        "kod"
    FROM
        "Rajon"
    WHERE
        "nazev" = 'Mustek';

INSERT INTO "Zlocin_byl_proveden_v_rajone"
    SELECT
        '4',
        "kod"
    FROM
        "Rajon"
    WHERE
        "nazev" = 'Haje';

INSERT INTO "Zlocin_byl_proveden_v_rajone"
    SELECT
        '5',
        "kod"
    FROM
        "Rajon"
    WHERE
        "nazev" = 'Chodov';


INSERT INTO "Typ_vybaveni" (
    "nazev_typu"
) VALUES (
    'Nožík'
);

INSERT INTO "Typ_vybaveni" (
    "nazev_typu"
) VALUES (
    'Puška'
);

INSERT INTO "Typ_vybaveni" (
    "nazev_typu"
) VALUES (
    'Vysílačka'
);

INSERT INTO "Typ_vybaveni" (
    "nazev_typu"
) VALUES (
    'Lano'
);

INSERT INTO "Typ_vybaveni" (
    "nazev_typu"
) VALUES (
    'Auto'
);

INSERT INTO "Zlodej_byl_proskolen_pro_typ_vybaveni"
    SELECT
        '540312113',
        "kod"
    FROM
        "Typ_vybaveni"
    WHERE
        "nazev_typu" = 'Puška';

INSERT INTO "Zlodej_byl_proskolen_pro_typ_vybaveni"
    SELECT
        '700413098',
        "kod"
    FROM
        "Typ_vybaveni"
    WHERE
        "nazev_typu" = 'Nožík';

INSERT INTO "Zlodej_byl_proskolen_pro_typ_vybaveni"
    SELECT
        '450123124',
        "kod"
    FROM
        "Typ_vybaveni"
    WHERE
        "nazev_typu" = 'Lano';

INSERT INTO "Zlodej_byl_proskolen_pro_typ_vybaveni"
    SELECT
        '450123124',
        "kod"
    FROM
        "Typ_vybaveni"
    WHERE
        "nazev_typu" = 'Auto';

INSERT INTO "Zlodej_byl_proskolen_pro_typ_vybaveni"
    SELECT
        '9910050040',
        "kod"
    FROM
        "Typ_vybaveni"
    WHERE
        "nazev_typu" = 'Vysílačka';


INSERT INTO "Typ_zlocinu_vyzaduje_typ_vybaveni"
    SELECT
        '1',
        "kod"
    FROM
        "Typ_vybaveni"
    WHERE
        "nazev_typu" = 'Nožík';

INSERT INTO "Typ_zlocinu_vyzaduje_typ_vybaveni"
    SELECT
        '4',
        "kod"
    FROM
        "Typ_vybaveni"
    WHERE
        "nazev_typu" = 'Puška';

INSERT INTO "Typ_zlocinu_vyzaduje_typ_vybaveni"
    SELECT
        '2',
        "kod"
    FROM
        "Typ_vybaveni"
    WHERE
        "nazev_typu" = 'Vysílačka';

INSERT INTO "Typ_zlocinu_vyzaduje_typ_vybaveni"
    SELECT
        '5',
        "kod"
    FROM
        "Typ_vybaveni"
    WHERE
        "nazev_typu" = 'Nožík';

INSERT INTO "Typ_zlocinu_vyzaduje_typ_vybaveni"
    SELECT
        '4',
        "kod"
    FROM
        "Typ_vybaveni"
    WHERE
        "nazev_typu" = 'Auto';


INSERT INTO "Vybaveni" (
    "nazev",
    "popis",
    "kod_typu"
) VALUES (
    'Nožík na batoh',
    'Nožík na proříznutí batohu',
    '1'
);

INSERT INTO "Vybaveni" (
    "nazev",
    "popis",
    "kod_typu"
) VALUES (
    'Nůž',
    'Obyčejný nůž',
    '1'
);

INSERT INTO "Vybaveni" (
    "nazev",
    "popis",
    "kod_typu"
) VALUES (
    'Puška',
    'AK-47',
    '2'
);

INSERT INTO "Vybaveni" (
    "nazev",
    "popis",
    "kod_typu"
) VALUES (
    'Puška',
    'AKM',
    '2'
);

INSERT INTO "Vybaveni" (
    "nazev",
    "popis",
    "kod_typu"
) VALUES (
    'Vysílačka',
    'Obyčejna vysílačka',
    '3'
);

INSERT INTO "Zlodej_vlastni_vybaveni_v_dobe" (
    "RC_zlodeje",
    "kod_vybaveni",
    "zacatek",
    "konec"
) VALUES (
    450123124,
    1,
    TO_DATE('2020-12-01', 'YYYY-MM-DD'),
    TO_DATE('2024-12-01', 'YYYY-MM-DD')
);

INSERT INTO "Zlodej_vlastni_vybaveni_v_dobe" (
    "RC_zlodeje",
    "kod_vybaveni",
    "zacatek",
    "konec"
) VALUES (
    700413098,
    2,
    TO_DATE('2013-10-12', 'YYYY-MM-DD'),
    TO_DATE('2017-10-12', 'YYYY-MM-DD')
);

INSERT INTO "Zlodej_vlastni_vybaveni_v_dobe" (
    "RC_zlodeje",
    "kod_vybaveni",
    "zacatek",
    "konec"
) VALUES (
    9910050040,
    3,
    TO_DATE('2015-02-24', 'YYYY-MM-DD'),
    TO_DATE('2018-02-24', 'YYYY-MM-DD')
);

INSERT INTO "Zlodej_vlastni_vybaveni_v_dobe" (
    "RC_zlodeje",
    "kod_vybaveni",
    "zacatek"
) VALUES (
    540312113,
    3,
    TO_DATE('2022-06-29', 'YYYY-MM-DD')
);
INSERT INTO "Zlodej_vlastni_vybaveni_v_dobe" (
    "RC_zlodeje",
    "kod_vybaveni",
    "zacatek"
) VALUES (
    450123124,
    5,
    TO_DATE('2024-03-22', 'YYYY-MM-DD')
);

--SELECT--

--vybírá zloděje, kteří aktuálně vzbavení vlastní, takže ještě nebylo vráceno => "Zlodej_vlastni_vybaveni_v_dobe"."konec" IS NULL (2 tabulky)
SELECT DISTINCT "prezdivka" FROM "Zlodej", "Zlodej_vlastni_vybaveni_v_dobe"
WHERE "Zlodej"."rodne_cislo" = "Zlodej_vlastni_vybaveni_v_dobe"."RC_zlodeje"
AND "Zlodej_vlastni_vybaveni_v_dobe"."zacatek" >= TO_DATE('2004-01-01', 'YYYY-MM-DD')
AND "Zlodej_vlastni_vybaveni_v_dobe"."konec" IS NULL;

--vypíše seznam vybavení typu nožík
SELECT "nazev" FROM "Vybaveni", "Typ_vybaveni"
WHERE "Vybaveni"."kod_typu" = "Typ_vybaveni"."kod" AND "Typ_vybaveni"."nazev_typu" = 'Nožík';

--vybírá zloděje, kteří umí ukrást kufr (3 tabulky)
SELECT "prezdivka" FROM "Zlodej", "Zlodej_byl_proskolen_pro_typ_zlocinu", "Typ_zlocinu"
WHERE "Zlodej"."rodne_cislo" = "Zlodej_byl_proskolen_pro_typ_zlocinu"."RC_zlodeje" AND "Zlodej_byl_proskolen_pro_typ_zlocinu"."kod_typu_zlocinu" = "Typ_zlocinu"."kod"
AND "Typ_zlocinu"."nazev_typu" = 'Krádež kufru';

--vybírá jokou maximální kořist zloděj získal za své zločiny, pokud nějaké prováděl (GROUP BY)
SELECT "prezdivka", MAX("korist") AS "maximalni_korist"
FROM "Zlodej", "Zlodej_provedl_zlocin", "Zlocin"
WHERE "Zlodej"."rodne_cislo" = "Zlodej_provedl_zlocin"."RC_zlodeje" AND "Zlodej_provedl_zlocin"."kod_zlocinu" = "Zlocin"."kod"
GROUP BY "prezdivka"
ORDER BY "maximalni_korist" DESC;

--vybírá počet zločinů, provedených v každem rajoně, ve kterém kapacita_zlodeju je minimálně 15 (GROUP BY)
SELECT "nazev", COUNT(*) AS "pocet_zlocinu"
FROM "Rajon", "Zlocin_byl_proveden_v_rajone"
WHERE "Rajon"."kod" = "Zlocin_byl_proveden_v_rajone"."kod_rajonu" AND "Rajon"."kapacita_zlodeju" >= 15
GROUP BY "nazev"
ORDER BY "pocet_zlocinu" DESC;

--vybírá zloděje, kteří neprovedli žádný zločin (EXISTS)
SELECT "prezdivka", "rodne_cislo" FROM "Zlodej" WHERE NOT EXISTS (SELECT * FROM "Zlodej_provedl_zlocin" WHERE "RC_zlodeje" = "Zlodej"."rodne_cislo" );

--vybírá zloděje, kteří umí ukrást kufr a řadí v rajoně z kapacitou menší než 20 (IN)
SELECT DISTINCT "prezdivka", "rodne_cislo" FROM "Zlodej", "Zlodej_byl_proskolen_pro_typ_zlocinu", "Typ_zlocinu"
WHERE "Zlodej"."rodne_cislo" = "Zlodej_byl_proskolen_pro_typ_zlocinu"."RC_zlodeje" AND "Zlodej_byl_proskolen_pro_typ_zlocinu"."kod_typu_zlocinu" = "Typ_zlocinu"."kod"
AND "Typ_zlocinu"."nazev_typu" = 'Krádež kufru' AND "Zlodej"."rodne_cislo" IN (SELECT "RC_zlodeje" FROM "Zlodej_v_rajone", "Rajon"
WHERE "Zlodej_v_rajone"."kod_rajonu" = "Rajon"."kod" AND "RC_zlodeje" = "Zlodej"."rodne_cislo" AND "Rajon"."kapacita_zlodeju" < 20);

---------------------------------------------------------------------------------------------------------
--Procedury

-- procedura pro vypis dob vlastnictví vybavení zločinci v sestupném pořadí
CREATE OR REPLACE PROCEDURE Vybaveni_statistika(vybaveni_id IN INT)
IS
    CURSOR cursor_zlodej_vybaveni IS
        SELECT vlastnictví."RC_zlodeje",
               vlastnictví."kod_vybaveni",
               vlastnictví."zacatek",
               NVL(vlastnictví."konec", SYSDATE) AS konec,
               SYSDATE AS dnes
        FROM "Zlodej_vlastni_vybaveni_v_dobe" vlastnictví
        WHERE vlastnictví."kod_vybaveni" = vybaveni_id
        ORDER BY konec - vlastnictví."zacatek" DESC;

    zlodej_rc "Zlodej"."rodne_cislo"%TYPE;
    vybaveni_kod "Vybaveni"."kod"%TYPE;
    zacatek "Zlodej_vlastni_vybaveni_v_dobe"."zacatek"%TYPE;
    konec "Zlodej_vlastni_vybaveni_v_dobe"."konec"%TYPE;
    dnes DATE;
BEGIN
    OPEN cursor_zlodej_vybaveni;

    LOOP
        FETCH cursor_zlodej_vybaveni INTO zlodej_rc, vybaveni_kod, zacatek, konec, dnes;
        EXIT WHEN cursor_zlodej_vybaveni%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Rodne_cislo: ' || zlodej_rc || ', Doba vlastnictví: ' || TRUNC(konec - zacatek));
    END LOOP;

    CLOSE cursor_zlodej_vybaveni;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Chyba: ' || SQLERRM);
END;
/

SET SERVEROUTPUT ON;

DECLARE
  vybaveni_id INT := 3;
BEGIN
  Vybaveni_statistika(vybaveni_id);
END;
/


/*procedura pro tisk žebříčku zlodějů podle jejich uspešnosti
- uspešnost za jednotlivé zločiny se počítá jako poměr získané kořisti k obtížnosti zločinu a počtu účastníků
    uspesnost = korist / (mira_obtiznosti * pocet_ucastniku)
- uspešnost za všechny zločiny se počítá jako průměr uspešností za jednotlivé zločiny
    uspesnostSUM = SUM(uspesnost)
- výstupem procedury je žebříček zlodějů seřazený podle uspešnosti
*/
CREATE OR REPLACE PROCEDURE Zlodej_zebricek
IS
    CURSOR cursor_zlodej IS
        SELECT "rodne_cislo", "prezdivka"
        FROM "Zlodej";

    TYPE zlodej_uspesnost_tab IS TABLE OF VARCHAR2(100) INDEX BY BINARY_INTEGER;
    pole_zlodeju zlodej_uspesnost_tab;

    TYPE Thief_Record IS RECORD (
        prezdivka "Zlodej"."prezdivka"%TYPE,
        uspesnostSUM NUMBER
    );

    TYPE Thief_Table IS TABLE OF Thief_Record;

    thieves_table Thief_Table := Thief_Table();

    zlodej_rc "Zlodej"."rodne_cislo"%TYPE;
    zlodej_prezdivka "Zlodej"."prezdivka"%TYPE;
    zlocin_kod "Zlocin"."kod"%TYPE;
    korist "Zlocin"."korist"%TYPE;
    obtiznost "Zlocin"."mira_obtiznosti"%TYPE;
    pocet_ucastniku NUMBER;
    uspesnost NUMBER;
    uspesnostSUM NUMBER := 0;
BEGIN
    OPEN cursor_zlodej;

    LOOP
        FETCH cursor_zlodej INTO zlodej_rc, zlodej_prezdivka;
        EXIT WHEN cursor_zlodej%NOTFOUND;

        FOR zlocin IN (SELECT "kod", "korist", "mira_obtiznosti" FROM "Zlocin", "Zlodej_provedl_zlocin"
                       WHERE "Zlocin"."kod" = "Zlodej_provedl_zlocin"."kod_zlocinu" AND "RC_zlodeje" = zlodej_rc)
        LOOP
            zlocin_kod := zlocin."kod";
            korist := zlocin."korist";
            obtiznost := zlocin."mira_obtiznosti";

            SELECT COUNT(*)
            INTO pocet_ucastniku
            FROM "Zlodej_provedl_zlocin"
            WHERE "kod_zlocinu" = zlocin_kod;

            IF korist IS NULL THEN
                uspesnost := 0;
            ELSE
                uspesnost := korist / (obtiznost * pocet_ucastniku);
            END IF;

            uspesnostSUM := uspesnostSUM + uspesnost;
        END LOOP;

        pole_zlodeju(pole_zlodeju.COUNT + 1) := uspesnostSUM;

        thieves_table.EXTEND;
        thieves_table(thieves_table.LAST) := Thief_Record(zlodej_prezdivka, uspesnostSUM);

        uspesnostSUM := 0;
    END LOOP;

    FOR i IN 1..thieves_table.COUNT - 1 LOOP
        FOR j IN i + 1..thieves_table.COUNT LOOP
            IF thieves_table(i).uspesnostSUM < thieves_table(j).uspesnostSUM THEN
                DECLARE
                    temp_thief Thief_Record;    
                BEGIN
                    temp_thief := thieves_table(i);
                    thieves_table(i) := thieves_table(j);
                    thieves_table(j) := temp_thief; 
                END;
            END IF;
        END LOOP;
    END LOOP;

    FOR i IN 1..thieves_table.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Prezdivka: ' || thieves_table(i).prezdivka || ', Uspesnost: ' || thieves_table(i).uspesnostSUM);
    END LOOP;

    CLOSE cursor_zlodej;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Chyba: ' || SQLERRM);
END;
/

EXECUTE Zlodej_zebricek;

------------------------------------------------------------------------------------------------------------------------------
 
-- TRIGGER - vytvoření triggeru, který zkontroluje, zda zlodej je proškolen pro typ vybavení, které chce pujčit
CREATE OR REPLACE TRIGGER check_education_before_insert_vybaveni
BEFORE INSERT OR UPDATE ON "Zlodej_vlastni_vybaveni_v_dobe"
FOR EACH ROW
DECLARE
    proskolen NUMBER;
BEGIN
    SELECT 1
    INTO proskolen
    FROM "Zlodej_byl_proskolen_pro_typ_vybaveni"
    WHERE "RC_zlodeje" = :new."RC_zlodeje" AND "kod_typu_vybaveni" = :new."kod_vybaveni"
    AND ROWNUM = 1;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Zloděj nebyl proškolen pro toto vybavení.');
END;
/

-- UKAZKOVÝ TRIGGER - Zlodej RC_zlodeje 540312113 byl proškolen pro typ Puška
SELECT * FROM "Zlodej_vlastni_vybaveni_v_dobe";
INSERT INTO "Zlodej_vlastni_vybaveni_v_dobe" (
    "RC_zlodeje",
    "kod_vybaveni",
    "zacatek"
) VALUES (
    540312113,
    2,
    TO_DATE('2020-12-01', 'YYYY-MM-DD')
);
SELECT * FROM "Zlodej_vlastni_vybaveni_v_dobe";

-- Zlodej RC_zlodeje 540312113 nebyl proškolen pro typ Nožík
BEGIN
    INSERT INTO "Zlodej_vlastni_vybaveni_v_dobe" (
        "RC_zlodeje",
        "kod_vybaveni",
        "zacatek"
    ) VALUES (
        540312113,
        1,
        TO_DATE('2020-12-01', 'YYYY-MM-DD')
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Zloděj nebyl proškolen pro toto vybavení.');
END;
/

--TRIGGER - predtím, než zloděj ziská povoleni na určitý typ zločinu,
-- musí být pro tento typ proškolen
CREATE OR REPLACE TRIGGER check_education_before_insert
BEFORE INSERT OR UPDATE ON "Zlodej_ziskal_povoleni"
FOR EACH ROW
DECLARE
    proskolen NUMBER;
BEGIN
    SELECT 1
    INTO proskolen
    FROM "Zlodej_byl_proskolen_pro_typ_zlocinu"
    WHERE "RC_zlodeje" = :new."RC_zlodeje" AND "kod_typu_zlocinu" = :new."kod_typu"
    AND ROWNUM = 1;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Zloděj nebyl proškolen pro tento typ zločinu.');
END;
/

-- UKAZKOVÝ TRIGGER - Zlodej RC_zlodeje 450123124 byl proškolen pro typ Krádež peněženky
SELECT * FROM "Zlodej_ziskal_povoleni";
INSERT INTO "Zlodej_ziskal_povoleni" (
    "RC_zlodeje",
    "kod_povoleni",
    "kod_typu"
) VALUES (
    450123124,
    1,
    1
);
SELECT * FROM "Zlodej_ziskal_povoleni";

-- Zlodej RC_zlodeje 540312113 nebyl proškolen pro typ Krádež peněženky
BEGIN
    INSERT INTO "Zlodej_ziskal_povoleni" (
        "RC_zlodeje",
        "kod_povoleni",
        "kod_typu"
    ) VALUES (
        540312113,
        1,
        1
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Zloděj nebyl proškolen pro tento typ zločinu.');
END;
/

SELECT * FROM "Zlodej_ziskal_povoleni";
------------------------------------------------------------------------------------------------------------
-- Index and explain plan

-- Vytvoření indexu pro sloupcу 'datum' a 'kod' v tabulce 'Zlocin'
-- kde rok je 2024
-- pro dotaz "Kdo v roce 2024 spáchal alespoň jeden zločin"
-- pro sledování aktuálně pracujících zlodějů
CREATE INDEX zlocin_datum_index ON "Zlocin" ("datum", "kod");
EXPLAIN PLAN FOR
SELECT DISTINCT "Zlodej"."rodne_cislo", "Zlodej"."prezdivka"
FROM "Zlodej"
JOIN "Zlodej_provedl_zlocin" ON "Zlodej"."rodne_cislo" = "Zlodej_provedl_zlocin"."RC_zlodeje"
JOIN "Zlocin" ON "Zlodej_provedl_zlocin"."kod_zlocinu" = "Zlocin"."kod"
WHERE EXTRACT(YEAR FROM "Zlocin"."datum") = 2024
GROUP BY "Zlodej"."rodne_cislo", "Zlodej"."prezdivka"
HAVING COUNT(*) >= 1;

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

DROP INDEX zlocin_datum_index;

--explain plan bez indexu
EXPLAIN PLAN FOR
SELECT DISTINCT "Zlodej"."rodne_cislo", "Zlodej"."prezdivka"
FROM "Zlodej"
JOIN "Zlodej_provedl_zlocin" ON "Zlodej"."rodne_cislo" = "Zlodej_provedl_zlocin"."RC_zlodeje"
JOIN "Zlocin" ON "Zlodej_provedl_zlocin"."kod_zlocinu" = "Zlocin"."kod"
WHERE EXTRACT(YEAR FROM "Zlocin"."datum") = 2024
GROUP BY "Zlodej"."rodne_cislo", "Zlodej"."prezdivka"
HAVING COUNT(*) >= 1;

SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

------------------------------------------------------------------------------------------------------------
-- Přístupová práva

GRANT ALL ON "Zlodej" TO xantsi00;
GRANT ALL ON "Rajon" TO xantsi00;
GRANT ALL ON "Zlodej_v_rajone" TO xantsi00;
GRANT ALL ON "Typ_zlocinu" TO xantsi00;
GRANT ALL ON "Zlodej_byl_proskolen_pro_typ_zlocinu" TO xantsi00;
GRANT ALL ON "Zlocin" TO xantsi00;
GRANT ALL ON "Povoleni" TO xantsi00;
GRANT ALL ON "Zlodej_ziskal_povoleni" TO xantsi00;
GRANT ALL ON "Zlodej_provedl_zlocin" TO xantsi00;
GRANT ALL ON "Zlocin_byl_proveden_v_rajone" TO xantsi00;
GRANT ALL ON "Typ_vybaveni" TO xantsi00;
GRANT ALL ON "Zlodej_byl_proskolen_pro_typ_vybaveni" TO xantsi00;
GRANT ALL ON "Typ_zlocinu_vyzaduje_typ_vybaveni" TO xantsi00;
GRANT ALL ON "Vybaveni" TO xantsi00;
GRANT ALL ON "Zlodej_vlastni_vybaveni_v_dobe" TO xantsi00;

GRANT EXECUTE ON Vybaveni_statistika TO xantsi00;
GRANT EXECUTE ON Zlodej_zebricek TO xantsi00;

--------------------------------------------------------------------------------------------------------------

-- vytvoření materializovaného pohledu na zlodeje a počet zločinů, které spáchal seřazené podle počtu zločinů s pouzitim joinu
CREATE MATERIALIZED VIEW Zlodej_zlociny_pocet AS
SELECT "Zlodej"."rodne_cislo", "Zlodej"."prezdivka", COUNT("Zlodej_provedl_zlocin"."kod_zlocinu") AS "pocet_zlocinu"
FROM "Zlodej"
LEFT JOIN "Zlodej_provedl_zlocin" ON "Zlodej"."rodne_cislo" = "Zlodej_provedl_zlocin"."RC_zlodeje"
GROUP BY "Zlodej"."rodne_cislo", "Zlodej"."prezdivka"
ORDER BY "pocet_zlocinu" DESC;

GRANT ALL ON Zlodej_zlociny_pocet TO xantsi00;
SELECT * FROM Zlodej_zlociny_pocet;
DROP MATERIALIZED VIEW Zlodej_zlociny_pocet;
------------------------------------------------------------------------------------------------
-- vytvoření klasifikace zlodejů podle proškolení pro typ zločinu a typ vybavení
WITH klasifikace_podle_skoleni AS (
    SELECT 
        z."rodne_cislo",
        COUNT(DISTINCT zs."kod_typu_zlocinu") AS pocet_skoleni_zlocinu,
        COUNT(DISTINCT zv."kod_typu_vybaveni") AS pocet_skoleni_vybaveni
    FROM 
        "Zlodej" z
    LEFT JOIN 
        "Zlodej_byl_proskolen_pro_typ_zlocinu" zs ON z."rodne_cislo" = zs."RC_zlodeje"
    LEFT JOIN 
        "Zlodej_byl_proskolen_pro_typ_vybaveni" zv ON z."rodne_cislo" = zv."RC_zlodeje"
    GROUP BY 
        z."rodne_cislo"
)
SELECT 
    "rodne_cislo",
    CASE
        WHEN pocet_skoleni_zlocinu + pocet_skoleni_vybaveni >= 4 THEN 'dobře vydělaný'
        WHEN pocet_skoleni_zlocinu + pocet_skoleni_vybaveni >= 2 THEN 'středně vzdělaný'
        ELSE 'nevzdělaný'
    END AS klasifikace
FROM 
    klasifikace_podle_skoleni;




 





 
 



