CREATE OR REPLACE TYPE Trener AS OBJECT (
    ID NUMBER,
    Name VARCHAR2(100),
    Pokedollars NUMBER,
    Ranking VARCHAR2(50),
    Wins NUMBER
);
/
CREATE TABLE Trenerzy OF Trener (
    PRIMARY KEY (ID)
);
/
CREATE OR REPLACE TYPE Pokemon AS OBJECT (
    ID NUMBER,
    Name VARCHAR2(100),
    HP NUMBER,
    Lvl Number,
    Attack NUMBER,
    Defense NUMBER,
    Sp_Atk NUMBER,
    Sp_Def NUMBER,
    Speed NUMBER,
    Rarity VARCHAR2(50),
    Type VARCHAR2(50),
    Trainer_Ref REF Trener -- Reference to Trener
);
/
CREATE TABLE Pokemons OF Pokemon (
    PRIMARY KEY (ID)
);
/
CREATE OR REPLACE TYPE Pokemon_List AS TABLE OF Pokemon;
/

CREATE OR REPLACE TYPE Wizyta AS OBJECT (
    TrenerID NUMBER,
    PokemonID NUMBER,
    DataWizyty DATE
);
/
CREATE OR REPLACE TYPE Wizyta_List AS TABLE OF Wizyta;
/
CREATE OR REPLACE TYPE Sklep AS OBJECT (
    ID NUMBER,
    Name VARCHAR2(100),
    AvailablePokemons Pokemon_List,
    Rezerwacje Wizyta_List
);
/
CREATE TABLE Sklepy OF Sklep (
    PRIMARY KEY (ID)
) NESTED TABLE AvailablePokemons STORE AS AvailablePokemons_nt,
  NESTED TABLE Rezerwacje STORE AS Rezerwacje_nt;
/