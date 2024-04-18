CREATE OR REPLACE PACKAGE POKEMONY AS
    -- Deklaracja funkcji
    FUNCTION ObliczCenePokemona(p_PokemonID IN NUMBER) RETURN NUMBER;
    FUNCTION CalculatePokemonPower(pokemonID IN NUMBER) RETURN NUMBER;
    FUNCTION WalkaTrenerow(trainer1ID NUMBER, trainer2ID NUMBER) RETURN VARCHAR2;

    -- Deklaracja procedur
    PROCEDURE DodajTrenera(p_ID IN Trenerzy.ID%TYPE, p_Name IN Trenerzy.Name%TYPE, p_Pokedollars IN Trenerzy.Pokedollars%TYPE, p_Ranking IN Trenerzy.Ranking%TYPE, p_Wins IN Trenerzy.Wins%TYPE);
    PROCEDURE DodajPokemona(p_ID IN Pokemons.ID%TYPE, p_Name IN Pokemons.Name%TYPE, p_HP IN Pokemons.HP%TYPE, p_Lvl IN Pokemons.Lvl%TYPE, p_Attack IN Pokemons.Attack%TYPE, p_Defense IN Pokemons.Defense%TYPE, p_Sp_Atk IN Pokemons.Sp_Atk%TYPE, p_Sp_Def IN Pokemons.Sp_Def%TYPE, p_Speed IN Pokemons.Speed%TYPE, p_Rarity IN Pokemons.Rarity%TYPE, p_Type IN Pokemons.Type%TYPE, p_TrainerID IN Trenerzy.ID%TYPE);
    PROCEDURE DodajSklep(p_ID IN Sklepy.ID%TYPE, p_Name IN Sklepy.Name%TYPE);
    PROCEDURE DodajPokemonaDoSklepu(p_SklepID IN Sklepy.ID%TYPE, p_PokemonID IN Pokemons.ID%TYPE);
    PROCEDURE DodajPokemonaDoTrenera(p_TrenerID IN Trenerzy.ID%TYPE, p_PokemonID IN Pokemons.ID%TYPE);
    PROCEDURE WyswietlWszystkieSklepy;
    PROCEDURE WyswietlWszystkiePokemony;
    PROCEDURE WyswietlSklepyIPokemony;
    PROCEDURE WyswietlTrenerzyIPokemony;
    PROCEDURE WyswietlWszystkichTrenerow;
    PROCEDURE WyswietlPokemonyWSklepie(p_SklepID IN NUMBER);
    PROCEDURE KupPokemona(p_TrenerID IN NUMBER, p_SklepID IN NUMBER, p_PokemonID IN NUMBER);
    PROCEDURE DodajRezerwacje(p_TrenerID IN NUMBER, p_SklepID IN NUMBER, p_PokemonID IN NUMBER, p_DataWizyty IN DATE);
    PROCEDURE WyswietlRezerwacjeSklepu(p_SklepID IN NUMBER);
    PROCEDURE WyswietlRezerwacjeTrenera(p_TrenerID IN NUMBER);
    PROCEDURE CleanOldReservations;
    PROCEDURE DisplayStrongestPokemons(trainerID NUMBER);
    PROCEDURE UsunPokemona(pokemonID IN NUMBER);
    PROCEDURE DeletePokemonFromShop(pokemonID IN NUMBER, shopID IN NUMBER);
    PROCEDURE UsunTrenera(p_trenerID IN NUMBER);
    PROCEDURE UsunSklep(p_sklepID IN NUMBER);
    PROCEDURE UsunPokemonaZeSklepu(p_SklepID IN Sklepy.ID%TYPE, p_PokemonID IN Pokemons.ID%TYPE);
    PROCEDURE UsunRezerwacje(p_SklepID IN NUMBER, p_TrenerID IN NUMBER, p_DataWizyty IN DATE);
END POKEMONY;
/
CREATE OR REPLACE PACKAGE BODY POKEMONY AS

    FUNCTION ObliczCenePokemona(p_PokemonID IN NUMBER) RETURN NUMBER IS
    v_Pokemon Pokemon;
    v_CenaBase NUMBER;
    v_CenaFinal NUMBER;
BEGIN
    -- Pobranie pokemona
    SELECT VALUE(p) INTO v_Pokemon FROM Pokemons p WHERE p.ID = p_PokemonID;
    
    -- Obliczenie ceny bazowej
    v_CenaBase := (v_Pokemon.HP + v_Pokemon.Attack + v_Pokemon.Defense + v_Pokemon.Sp_Atk + v_Pokemon.Sp_Def + v_Pokemon.Speed) * 0.1;
    
    -- Modyfikacja ceny bazowej na podstawie rzadkoœci
    CASE v_Pokemon.Rarity
        WHEN 'Common' THEN v_CenaFinal := v_CenaBase * 1;
        WHEN 'Rare' THEN v_CenaFinal := v_CenaBase * 1.3;
        WHEN 'Epic' THEN v_CenaFinal := v_CenaBase * 1.7;
        WHEN 'Legendary' THEN v_CenaFinal := v_CenaBase * 2.5;
        ELSE v_CenaFinal := v_CenaBase; -- Domyœlnie, je¿eli nie rozpoznano rzadkoœci
    END CASE;
    
    RETURN round(v_CenaFinal);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Pokemon o podanym ID nie istnieje.');
    WHEN OTHERS THEN
        RAISE;
END;

FUNCTION CalculatePokemonPower(pokemonID IN NUMBER) RETURN NUMBER AS
    p_hp NUMBER;
    p_attack NUMBER;
    p_defense NUMBER;
    p_sp_atk NUMBER;
    p_sp_def NUMBER;
    p_speed NUMBER;
    p_power NUMBER;
    number_of_found NUMBER;
BEGIN
    SELECT COUNT(*) INTO number_of_found FROM Pokemons p WHERE p.ID = pokemonID;

    IF number_of_found = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Pokemon with the provided ID not found');
    END IF;

    SELECT HP, Attack, Defense, Sp_Atk, Sp_Def, Speed
    INTO p_hp, p_attack, p_defense, p_sp_atk, p_sp_def, p_speed
    FROM Pokemons
    WHERE ID = pokemonID;

    -- Calculate the power of the Pokemon
    p_power := p_hp + p_attack + p_defense + p_sp_atk + p_sp_def + p_speed;

    RETURN p_power;
END;

FUNCTION WalkaTrenerow(trainer1ID NUMBER, trainer2ID NUMBER) RETURN VARCHAR2 IS
    winnerID NUMBER;
    TYPE TypeMultiplier IS TABLE OF NUMBER INDEX BY VARCHAR2(20);
    multiplier TypeMultiplier;
    
    FUNCTION DoIMultiply(type1 VARCHAR2, type2 VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        CASE type1
            WHEN 'Grass' THEN
                RETURN type2 IN ('Water', 'Ground');
            WHEN 'Poison' THEN
                RETURN type2 = 'Grass';
            WHEN 'Water' THEN
                RETURN type2 IN ('Fire', 'Ground');
            WHEN 'Fire' THEN
                RETURN type2 IN ('Grass', 'Ice');
            WHEN 'Electric' THEN
                RETURN type2 = 'Water';
            WHEN 'Ice' THEN
                RETURN type2 IN ('Grass', 'Ground');
            WHEN 'Ground' THEN
                RETURN type2 IN ('Fire', 'Electric');
            WHEN 'Dark' THEN
                RETURN TRUE; -- Dark jest skuteczny przeciwko wszystkim
            ELSE
                RETURN FALSE;
        END CASE;
    END DoIMultiply;

BEGIN
    DECLARE
        trainer1 Trener;
        trainer2 Trener;
        maxPokemonCount NUMBER;
        trainer1Power NUMBER;
        trainer2Power NUMBER;
        lvlIncrease NUMBER;
        battleCount NUMBER := 0;
        
        CURSOR trainer1PokemonCursor IS
        SELECT * FROM (SELECT p.* FROM Pokemons p WHERE DEREF(p.Trainer_Ref).ID = trainer1ID ORDER BY CalculatePokemonPower(p.ID) DESC) WHERE ROWNUM <= 3;
        CURSOR trainer2PokemonCursor IS
        SELECT * FROM (SELECT p.* FROM Pokemons p WHERE DEREF(p.Trainer_Ref).ID = trainer2ID ORDER BY CalculatePokemonPower(p.ID) DESC) WHERE ROWNUM <= 3;
    
    
BEGIN
    FOR i IN trainer1PokemonCursor LOOP
        FOR j IN trainer2PokemonCursor LOOP
            trainer1Power := CalculatePokemonPower(i.ID);
            trainer2Power := CalculatePokemonPower(j.ID);

            IF DoIMultiply(i.Type, j.Type) THEN
                trainer1Power := trainer1Power * 1.20;
            END IF;

            IF DoIMultiply(j.Type, i.Type) THEN
                trainer2Power := trainer2Power * 1.20;
            END IF;

            -- Aktualizacja po wygranej walce
            IF trainer1Power > trainer2Power THEN
                battleCount := battleCount + 1;
                lvlIncrease := GREATEST(1, j.Lvl - i.Lvl);
                UPDATE Pokemons SET
                    Lvl = Lvl + lvlIncrease,
                    Attack = Attack * POWER(1.05,lvlIncrease),
                    Defense = Defense * POWER(1.05,lvlIncrease),
                    Speed = Speed * POWER(1.05,lvlIncrease),
                    Sp_Atk = Sp_Atk * POWER(1.05,lvlIncrease),
                    Sp_Def = Sp_Def * POWER(1.05,lvlIncrease)
                WHERE ID = i.ID;
            ELSIF trainer2Power > trainer1Power THEN
                battleCount := battleCount - 1;
                lvlIncrease := GREATEST(1, i.Lvl - j.Lvl);
                UPDATE Pokemons SET
                    Lvl = Lvl + lvlIncrease,
                    Attack = Attack * POWER(1.05,lvlIncrease),
                    Defense = Defense * POWER(1.05,lvlIncrease),
                    Speed = Speed * POWER(1.05,lvlIncrease),
                    Sp_Atk = Sp_Atk * POWER(1.05,lvlIncrease),
                    Sp_Def = Sp_Def * POWER(1.05,lvlIncrease)
                WHERE ID = j.ID;
            END IF;
        END LOOP;
    END LOOP;
        
        -- Logika okreœlaj¹ca zwyciêzcê i zakoñczenie funkcji
        IF battleCount > 0 THEN
            winnerID := trainer1ID;
            trainer1.Wins := trainer1.Wins + 1;
            trainer1.Pokedollars := trainer1.Pokedollars + ROUND(0.2 * trainer2.Pokedollars);
        ELSIF battleCount < 0 THEN
            winnerID := trainer2ID;
            trainer2.Wins := trainer2.Wins + 1;
            trainer2.Pokedollars := trainer2.Pokedollars + ROUND(0.2 * trainer1.Pokedollars);
        ELSE
            -- Remis
            RETURN 'Remis! Brak zwyciêzcy.';
        END IF;

        COMMIT;
        RETURN 'Wygra³ trener o ID: ' || winnerID;
    END;
END WalkaTrenerow;

PROCEDURE DodajTrenera (
    p_ID IN Trenerzy.ID%TYPE,
    p_Name IN Trenerzy.Name%TYPE,
    p_Pokedollars IN Trenerzy.Pokedollars%TYPE,
    p_Ranking IN Trenerzy.Ranking%TYPE,
    p_Wins IN Trenerzy.Wins%TYPE
) AS
BEGIN
    INSERT INTO Trenerzy (ID, Name, Pokedollars, Ranking, Wins)
    VALUES (p_ID, p_Name, p_Pokedollars, p_Ranking, p_Wins);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

PROCEDURE DodajPokemona (
    p_ID IN Pokemons.ID%TYPE,
    p_Name IN Pokemons.Name%TYPE,
    p_HP IN Pokemons.HP%TYPE,
    p_Lvl IN Pokemons.Lvl%TYPE,
    p_Attack IN Pokemons.Attack%TYPE,
    p_Defense IN Pokemons.Defense%TYPE,
    p_Sp_Atk IN Pokemons.Sp_Atk%TYPE,
    p_Sp_Def IN Pokemons.Sp_Def%TYPE,
    p_Speed IN Pokemons.Speed%TYPE,
    p_Rarity IN Pokemons.Rarity%TYPE,
    p_Type IN Pokemons.Type%TYPE,
    p_TrainerID IN Trenerzy.ID%TYPE
) AS
    v_TrainerRef REF Trener := NULL; -- Domyœlnie NULL
BEGIN
    -- SprawdŸ, czy ID trenera jest ró¿ne od -1 przed prób¹ znalezienia referencji
    IF p_TrainerID != -1 THEN
        BEGIN
            SELECT REF(t) INTO v_TrainerRef FROM Trenerzy t WHERE t.ID = p_TrainerID;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20001, 'Trener o podanym ID nie istnieje.');
        END;
    END IF;

    INSERT INTO Pokemons (ID, Name, HP, Lvl, Attack, Defense, Sp_Atk, Sp_Def, Speed, Rarity, Type, Trainer_Ref)
    VALUES (p_ID, p_Name, p_HP, p_Lvl, p_Attack, p_Defense, p_Sp_Atk, p_Sp_Def, p_Speed, p_Rarity, p_Type, v_TrainerRef);
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

PROCEDURE DodajSklep (
    p_ID IN Sklepy.ID%TYPE,
    p_Name IN Sklepy.Name%TYPE
) AS
BEGIN
    INSERT INTO Sklepy (ID, Name, AvailablePokemons, Rezerwacje)
    VALUES (p_ID, p_Name, Pokemon_List(), Wizyta_List());
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

PROCEDURE DodajPokemonaDoSklepu (
    p_SklepID IN Sklepy.ID%TYPE,
    p_PokemonID IN Pokemons.ID%TYPE
) AS
    v_Pokemon Pokemon;
    v_AvailablePokemons Pokemon_List; -- tymczasowa lista pokémonów
    v_Count NUMBER;
BEGIN
    SELECT VALUE(p) INTO v_Pokemon FROM Pokemons p WHERE p.ID = p_PokemonID;

    -- Sprawdzanie, czy Pokemon jest ju¿ przypisany do innego sklepu
    SELECT COUNT(*)
    INTO v_Count
    FROM Sklepy s, TABLE(s.AvailablePokemons) ap
    WHERE ap.ID = p_PokemonID;

    IF v_Count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Pokemon jest ju¿ przypisany do innego sklepu.');
    END IF;

    -- Sprawdzanie, czy Pokemon jest przypisany do trenera
    SELECT COUNT(*)
    INTO v_Count
    FROM Pokemons p
    WHERE p.ID = p_PokemonID AND p.Trainer_Ref IS NOT NULL;

    IF v_Count > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Pokemon jest ju¿ przypisany do trenera.');
    END IF;

    SELECT s.AvailablePokemons INTO v_AvailablePokemons FROM Sklepy s WHERE s.ID = p_SklepID FOR UPDATE;
    
    -- Rozszerzenie kolekcji o 1
    v_AvailablePokemons.EXTEND;
    v_AvailablePokemons(v_AvailablePokemons.LAST) := v_Pokemon;
    
    -- Aktualizacja kolekcji w bazie danych
    UPDATE Sklepy SET AvailablePokemons = v_AvailablePokemons WHERE ID = p_SklepID;
    
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Pokemon lub Sklep o podanym ID nie istnieje.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

PROCEDURE DodajPokemonaDoTrenera (
    p_TrenerID IN Trenerzy.ID%TYPE,
    p_PokemonID IN Pokemons.ID%TYPE
) AS
BEGIN
    DECLARE
        v_TrainerRef REF Trener;
    BEGIN
        SELECT REF(t) INTO v_TrainerRef FROM Trenerzy t WHERE t.ID = p_TrenerID;
        UPDATE Pokemons p SET p.Trainer_Ref = v_TrainerRef WHERE p.ID = p_PokemonID;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Trener lub Pokemon o podanym ID nie istnieje.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END;
END;

PROCEDURE WyswietlWszystkieSklepy IS
CURSOR SklepyCursor IS SELECT * FROM Sklepy;
r SklepyCursor%ROWTYPE;
BEGIN
    OPEN SklepyCursor;
    LOOP
        FETCH SklepyCursor INTO r;
        EXIT WHEN SklepyCursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || r.ID || ', Nazwa: ' || r.Name);
    END LOOP;
    CLOSE SklepyCursor;
END;

PROCEDURE WyswietlWszystkiePokemony IS
CURSOR PokemonsCursor IS SELECT * FROM Pokemons;
r PokemonsCursor%ROWTYPE;
BEGIN
    OPEN PokemonsCursor;
    LOOP
        FETCH PokemonsCursor INTO r;
        EXIT WHEN PokemonsCursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || r.ID || ', Nazwa: ' || r.Name || ', Rodzaj: ' || r.Type || ', Rzadkoœæ: ' || r.Rarity);
    END LOOP;
    CLOSE PokemonsCursor;
END;

PROCEDURE WyswietlSklepyIPokemony IS
CURSOR SklepyCursor IS SELECT * FROM Sklepy;
sklepRec SklepyCursor%ROWTYPE;

CURSOR PokemonsCursor(sklepID NUMBER) IS
    SELECT p.* FROM TABLE(
                (SELECT s.AvailablePokemons
                 FROM Sklepy s
                 WHERE s.ID = sklepID)
            ) p;

pokemonRec PokemonsCursor%ROWTYPE;
BEGIN
    OPEN SklepyCursor;
    LOOP
        FETCH SklepyCursor INTO sklepRec;
        EXIT WHEN SklepyCursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Sklep ID: ' || sklepRec.ID || ', Nazwa: ' || sklepRec.Name);
        
        OPEN PokemonsCursor(sklepRec.ID);
        LOOP
            FETCH PokemonsCursor INTO pokemonRec;
            EXIT WHEN PokemonsCursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('    Pokemon: ' || pokemonRec.Name || ', ID: ' || pokemonRec.ID || ', Lvl: ' || pokemonRec.Lvl);
        END LOOP;
        CLOSE PokemonsCursor;
        
        DBMS_OUTPUT.PUT_LINE('----------------------------------');
    END LOOP;
    CLOSE SklepyCursor;
END;

PROCEDURE WyswietlTrenerzyIPokemony AS
    -- Cursor for trainers
    CURSOR trenerzy_cursor IS SELECT * FROM Trenerzy;

    -- Cursor for Pokémon of a specific trainer
    CURSOR pokemons_cursor (v_trainer_id NUMBER) IS
        SELECT p.*
        FROM Pokemons p
        WHERE DEREF(p.Trainer_Ref).ID = v_trainer_id;

    -- Variables for each field in the Trener type
    v_id NUMBER;
    v_name VARCHAR2(100);
    v_pokedollars NUMBER;
    v_ranking VARCHAR2(50);
    v_wins NUMBER;

BEGIN
    -- Opening the cursor for trainers
    OPEN trenerzy_cursor;

    -- Loop for each trainer
    LOOP
        FETCH trenerzy_cursor INTO v_id, v_name, v_pokedollars, v_ranking, v_wins;
        EXIT WHEN trenerzy_cursor%NOTFOUND;

        -- Display information about the trainer
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id);
        DBMS_OUTPUT.PUT_LINE('Name: ' || v_name);
        DBMS_OUTPUT.PUT_LINE('Pokedollars: ' || v_pokedollars);
        DBMS_OUTPUT.PUT_LINE('Ranking: ' || v_ranking);
        DBMS_OUTPUT.PUT_LINE('Wins: ' || v_wins);

        -- Loop for each Pokémon of the current trainer
        FOR pokemon_rec IN pokemons_cursor(v_id) LOOP
            DBMS_OUTPUT.PUT_LINE('  Pokemon: ');
            DBMS_OUTPUT.PUT_LINE('    ID: ' || pokemon_rec.ID);
            DBMS_OUTPUT.PUT_LINE('    Name: ' || pokemon_rec.Name);
            -- Displaying other Pokémon details...
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('-------------------');
    END LOOP;

    -- Closing the cursor for trainers
    CLOSE trenerzy_cursor;
END WyswietlTrenerzyIPokemony;

PROCEDURE KupPokemona(
    p_TrenerID IN NUMBER,
    p_SklepID IN NUMBER,
    p_PokemonID IN NUMBER
) AS
    v_Trener Trener;
    v_Sklep Sklep;
    current_pokemons Pokemon_List;
    v_CenaPokemona NUMBER;
    v_IloscPokemonow NUMBER;
    v_CurrentHour NUMBER;
    v_PokemonDostepny BOOLEAN := FALSE;
    v_PokemonIndex NUMBER;
BEGIN
    -- Pobranie aktualnej godziny
    SELECT EXTRACT(HOUR FROM SYSTIMESTAMP) INTO v_CurrentHour FROM DUAL;

    -- Sprawdzenie, czy zakup odbywa siê poza godzinami pracy sklepu
    IF v_CurrentHour > 17 OR v_CurrentHour < 0 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Zakup mo¿liwy tylko w godzinach pracy sklepu od 17:00 do 22:00.');
    END IF;

    -- Sprawdzenie czy trener istnieje
    SELECT VALUE(t) INTO v_Trener FROM Trenerzy t WHERE t.ID = p_TrenerID;
    
    -- Sprawdzenie czy sklep istnieje i pobranie dostêpnych pokemonów
    SELECT VALUE(s), s.AvailablePokemons INTO v_Sklep, current_pokemons FROM Sklepy s WHERE s.ID = p_SklepID;
    
    -- Obliczenie ceny pokemona
    v_CenaPokemona := ObliczCenePokemona(p_PokemonID);
    -- Sprawdzenie czy pokemon w sklepie istnieje i usuwanie go z listy
    FOR i IN 1..current_pokemons.COUNT LOOP
        
        IF current_pokemons(i).ID = p_PokemonID THEN
            v_PokemonDostepny := TRUE;
            v_PokemonIndex := i;
            EXIT;
        END IF;
    END LOOP;

    IF NOT v_PokemonDostepny THEN
        RAISE_APPLICATION_ERROR(-20008, 'Pokemon nie jest dostêpny w sklepie.');
    ELSE
        current_pokemons.DELETE(v_PokemonIndex);
    END IF;

    -- Sprawdzenie czy trener ma mniej ni¿ 15 pokemonów
    SELECT COUNT(*) INTO v_IloscPokemonow FROM Pokemons WHERE Trainer_Ref = (SELECT REF(t) FROM Trenerzy t WHERE t.ID = p_TrenerID);
    IF v_IloscPokemonow >= 15 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Trener posiada ju¿ maksymaln¹ liczbê pokemonów.');
    END IF;
    
    -- Sprawdzenie czy trener ma wystarczaj¹co pokedollarów
    IF v_Trener.Pokedollars < v_CenaPokemona THEN
        RAISE_APPLICATION_ERROR(-20005, 'Trener nie posiada wystarczaj¹cej iloœci pokedollarów.');
    END IF;
    
    -- Aktualizacja trenera (odejmowanie pokedollarów)
    UPDATE Trenerzy SET Pokedollars = Pokedollars - v_CenaPokemona WHERE ID = p_TrenerID;
    
    UPDATE Pokemons SET Trainer_Ref = (SELECT REF(t) FROM Trenerzy t WHERE t.ID = p_TrenerID)
    WHERE ID = p_PokemonID;
    
    -- Aktualizacja sklepu (usuwanie pokemona)
    UPDATE Sklepy SET AvailablePokemons = current_pokemons WHERE ID = p_SklepID;
    
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20006, 'Pokemon, Trener lub Sklep o podanym ID nie istnieje.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

PROCEDURE DodajRezerwacje(
    p_TrenerID IN NUMBER,
    p_SklepID IN NUMBER,
    p_PokemonID IN NUMBER,
    p_DataWizyty IN DATE
) AS
    v_trenerExists NUMBER;
    v_sklepExists NUMBER;
    v_pokemonExists NUMBER;
    v_rezerwacjaExists NUMBER;
    v_trenerRezerwacjaExists NUMBER;
    v_currentTime DATE := SYSDATE;
BEGIN
    -- Sprawdzenie istnienia trenera, sklepu i pokemona
    SELECT COUNT(*) INTO v_trenerExists FROM Trenerzy WHERE ID = p_TrenerID;
    SELECT COUNT(*) INTO v_sklepExists FROM Sklepy WHERE ID = p_SklepID;
    SELECT COUNT(*) INTO v_pokemonExists
    FROM TABLE(
        SELECT AvailablePokemons
        FROM Sklepy
        WHERE ID = p_SklepID
    ) ap
    WHERE ap.ID = p_PokemonID;

    IF v_trenerExists = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Trener o podanym ID nie istnieje.');
    END IF;
    IF v_sklepExists = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Sklep o podanym ID nie istnieje.');
    END IF;
    IF v_pokemonExists = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Pokemon o podanym ID nie istnieje.');
    END IF;

    -- Sprawdzenie, czy data i godzina s¹ prawid³owe
    IF p_DataWizyty <= v_currentTime THEN
        RAISE_APPLICATION_ERROR(-20004, 'Data wizyty nie mo¿e byæ w przesz³oœci.');
    END IF;
    -- Sprawdzenie, czy zakup odbywa siê poza godzinami pracy sklepu
    IF EXTRACT(HOUR FROM CAST(p_DataWizyty AS TIMESTAMP)) < 8 OR EXTRACT(HOUR FROM CAST(p_DataWizyty AS TIMESTAMP)) >= 18 OR EXTRACT(MINUTE FROM CAST(p_DataWizyty AS TIMESTAMP)) != 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Godzina wizyty musi byæ pe³na i w zakresie od 8:00 do 18:00.');
    END IF;


    -- Sprawdzenie, czy na tê godzinê nie ma ju¿ innej wizyty na tego pokemona
    SELECT COUNT(*) INTO v_rezerwacjaExists
    FROM TABLE(SELECT s.Rezerwacje FROM Sklepy s WHERE s.ID = p_SklepID)
    WHERE PokemonID = p_PokemonID AND DataWizyty = p_DataWizyty;

    IF v_rezerwacjaExists > 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Na tê godzinê istnieje ju¿ rezerwacja na tego pokemona.');
    END IF;

    -- Sprawdzenie, czy ten sam trener nie umówi³ ju¿ wizyty na innego pokemona w tym samym czasie
    SELECT COUNT(*) INTO v_trenerRezerwacjaExists
    FROM TABLE(SELECT s.Rezerwacje FROM Sklepy s WHERE s.ID = p_SklepID)
    WHERE TrenerID = p_TrenerID AND DataWizyty = p_DataWizyty;

    IF v_trenerRezerwacjaExists > 0 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Ten sam trener nie mo¿e umówiæ siê na zobaczenie innego pokemona na tê sam¹ godzinê.');
    END IF;

    -- Dodanie rezerwacji
    DECLARE
        v_Rezerwacje Wizyta_List;
    BEGIN
        SELECT s.Rezerwacje INTO v_Rezerwacje FROM Sklepy s WHERE s.ID = p_SklepID FOR UPDATE;
        v_Rezerwacje.EXTEND;
        v_Rezerwacje(v_Rezerwacje.LAST) := Wizyta(p_TrenerID, p_PokemonID, p_DataWizyty);
        UPDATE Sklepy s SET s.Rezerwacje = v_Rezerwacje WHERE s.ID = p_SklepID;
    END;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

PROCEDURE WyswietlRezerwacjeSklepu(p_SklepID IN NUMBER) AS
  CURSOR c_rezerwacje IS
    SELECT TrenerID, PokemonID, DataWizyty
    FROM TABLE(SELECT Rezerwacje FROM Sklepy WHERE ID = p_SklepID);
  v_rezerwacja c_rezerwacje%ROWTYPE;
  v_sklepExists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_sklepExists FROM Sklepy WHERE ID = p_SklepID;
  IF v_sklepExists = 0 THEN
    RAISE_APPLICATION_ERROR(-20010, 'Sklep o podanym ID nie istnieje.');
  END IF;

  OPEN c_rezerwacje;
  LOOP
    FETCH c_rezerwacje INTO v_rezerwacja;
    EXIT WHEN c_rezerwacje%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('TrenerID: ' || v_rezerwacja.TrenerID || 
                         ', PokemonID: ' || v_rezerwacja.PokemonID || 
                         ', DataWizyty: ' || TO_CHAR(v_rezerwacja.DataWizyty, 'YYYY-MM-DD HH24:MI'));
  END LOOP;
  CLOSE c_rezerwacje;
EXCEPTION
  WHEN OTHERS THEN
    IF c_rezerwacje%ISOPEN THEN
      CLOSE c_rezerwacje;
    END IF;
    RAISE;
END;

PROCEDURE WyswietlRezerwacjeTrenera(p_TrenerID IN NUMBER) AS
  CURSOR c_rezerwacje IS
    SELECT s.ID AS SklepID, t.TrenerID, t.PokemonID, t.DataWizyty
    FROM Sklepy s, TABLE(s.Rezerwacje) t
    WHERE t.TrenerID = p_TrenerID;
  v_rezerwacja c_rezerwacje%ROWTYPE;
  v_trenerExists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_trenerExists FROM Trenerzy WHERE ID = p_TrenerID;
  IF v_trenerExists = 0 THEN
    RAISE_APPLICATION_ERROR(-20011, 'Trener o podanym ID nie istnieje.');
  END IF;

  OPEN c_rezerwacje;
  LOOP
    FETCH c_rezerwacje INTO v_rezerwacja;
    EXIT WHEN c_rezerwacje%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('TrenerID: ' || v_rezerwacja.TrenerID ||
                        ', SklepID: ' || v_rezerwacja.SklepID || 
                         ', PokemonID: ' || v_rezerwacja.PokemonID || 
                         ', DataWizyty: ' || TO_CHAR(v_rezerwacja.DataWizyty, 'YYYY-MM-DD HH24:MI'));
  END LOOP;
  CLOSE c_rezerwacje;
EXCEPTION
  WHEN OTHERS THEN
    IF c_rezerwacje%ISOPEN THEN
      CLOSE c_rezerwacje;
    END IF;
    RAISE;
END;

PROCEDURE CleanOldReservations AS
BEGIN
    FOR eachStore IN (SELECT ID FROM Sklepy) LOOP
        DELETE FROM TABLE(SELECT s.Rezerwacje FROM Sklepy s WHERE s.ID = eachStore.ID)
        WHERE DataWizyty < SYSDATE - 30;
    END LOOP;
    COMMIT;
END;

PROCEDURE DisplayStrongestPokemons(trainerID NUMBER) IS
BEGIN
    FOR pokemonRecord IN (
        SELECT * 
        FROM (SELECT p.*, CalculatePokemonPower(p.ID) AS Power FROM Pokemons p WHERE DEREF(p.Trainer_Ref).ID = trainerID ORDER BY Power DESC) 
        WHERE ROWNUM <= 6
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Pokemon ID: ' || pokemonRecord.ID || 
                             ', Nazwa: ' || pokemonRecord.Name || 
                             ', Typ: ' || pokemonRecord.Type || 
                             ', Poziom: ' || pokemonRecord.Lvl);
    END LOOP;
END DisplayStrongestPokemons;

PROCEDURE UsunPokemona (pokemonID IN NUMBER) AS
  v_count NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO v_count
  FROM Pokemons
  WHERE ID = pokemonID;
  
  IF v_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Pokemon with ID ' || pokemonID || ' does not exist.');
  ELSE
    DELETE FROM Pokemons WHERE ID = pokemonID;
    DBMS_OUTPUT.PUT_LINE('Pokemon with ID ' || pokemonID || ' has been deleted.');
  END IF;
END;

PROCEDURE DeletePokemonFromShop (pokemonID IN NUMBER, shopID IN NUMBER) AS
  v_shop_exists NUMBER;
  v_pokemon_exists NUMBER;
BEGIN
  -- Sprawdzenie, czy sklep istnieje
  SELECT COUNT(*)
  INTO v_shop_exists
  FROM Sklepy
  WHERE ID = shopID;
  
  IF v_shop_exists = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Shop with ID ' || shopID || ' does not exist.');
    RETURN;
  END IF;
  
  -- Sprawdzenie, czy pokemon istnieje w sklepie
  SELECT COUNT(*)
  INTO v_pokemon_exists
  FROM TABLE(SELECT s.AvailablePokemons FROM Sklepy s WHERE s.ID = shopID)
  WHERE ID = pokemonID;
  
  IF v_pokemon_exists = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Pokemon with ID ' || pokemonID || ' is not available in shop with ID ' || shopID);
  ELSE
    -- Usuniêcie pokemona ze sklepu (wymaga bardziej zaawansowanej operacji na kolekcji)
    DELETE FROM TABLE(SELECT s.AvailablePokemons FROM Sklepy s WHERE s.ID = shopID) WHERE ID = pokemonID;
    DBMS_OUTPUT.PUT_LINE('Pokemon with ID ' || pokemonID || ' has been deleted from shop with ID ' || shopID);
  END IF;
END;

PROCEDURE UsunTrenera(p_trenerID IN NUMBER) AS
BEGIN
  DELETE FROM Trenerzy WHERE ID = p_trenerID;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END UsunTrenera;

PROCEDURE UsunSklep(p_sklepID IN NUMBER) AS
BEGIN
  DELETE FROM Sklepy WHERE ID = p_sklepID;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END UsunSklep;

PROCEDURE UsunPokemonaZeSklepu (
    p_SklepID IN Sklepy.ID%TYPE,
    p_PokemonID IN Pokemons.ID%TYPE
) AS
    v_AvailablePokemons Pokemon_List; -- tymczasowa lista pokémonów
    v_Found BOOLEAN := FALSE;
    v_Index NUMBER;
BEGIN
    -- Pobranie aktualnej listy dostêpnych pokemonów dla danego sklepu
    SELECT s.AvailablePokemons INTO v_AvailablePokemons FROM Sklepy s WHERE s.ID = p_SklepID FOR UPDATE;
    
    -- Szukanie pokemona w liœcie i jego usuniêcie
    v_Index := v_AvailablePokemons.FIRST;
    WHILE v_Index IS NOT NULL LOOP
        IF v_AvailablePokemons(v_Index).ID = p_PokemonID THEN
            v_AvailablePokemons.DELETE(v_Index);
            v_Found := TRUE;
            EXIT; -- Przerywamy pêtlê po znalezieniu i usuniêciu pokemona
        END IF;
        v_Index := v_AvailablePokemons.NEXT(v_Index);
    END LOOP;
    
    IF NOT v_Found THEN
        RAISE_APPLICATION_ERROR(-20005, 'Pokemon o podanym ID nie jest dostêpny w tym sklepie.');
    END IF;
    
    -- Aktualizacja listy dostêpnych pokemonów w sklepie
    UPDATE Sklepy SET AvailablePokemons = v_AvailablePokemons WHERE ID = p_SklepID;
    
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Sklep o podanym ID nie istnieje.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END UsunPokemonaZeSklepu;

PROCEDURE UsunRezerwacje(
    p_SklepID IN NUMBER,
    p_TrenerID IN NUMBER,
    p_DataWizyty IN DATE
) AS
    v_Rezerwacje Wizyta_List;
BEGIN
    -- Pobranie aktualnej listy rezerwacji dla danego sklepu
    SELECT s.Rezerwacje INTO v_Rezerwacje FROM Sklepy s WHERE s.ID = p_SklepID FOR UPDATE;

    -- Iteracja przez listê rezerwacji i usuniêcie tych, które odpowiadaj¹ podanej dacie i ID trenera
    DECLARE
        v_Index INTEGER := v_Rezerwacje.FIRST;
    BEGIN
        WHILE v_Index IS NOT NULL LOOP
            IF v_Rezerwacje(v_Index).DataWizyty > p_DataWizyty AND v_Rezerwacje(v_Index).TrenerID = p_TrenerID THEN
                v_Rezerwacje.DELETE(v_Index);
                -- Po usuniêciu elementu indeksy mog¹ siê zmieniæ, wiêc ponownie zaczynamy od pocz¹tku
                v_Index := v_Rezerwacje.FIRST;
            ELSE
                v_Index := v_Rezerwacje.NEXT(v_Index);
            END IF;
        END LOOP;
    END;

    -- Aktualizacja listy rezerwacji w sklepie
    UPDATE Sklepy s SET s.Rezerwacje = v_Rezerwacje WHERE s.ID = p_SklepID;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END UsunRezerwacje;

PROCEDURE WyswietlPokemonyWSklepie(p_SklepID IN NUMBER) IS
BEGIN
    -- Sprawdzenie, czy sklep istnieje
    DECLARE
        v_Exists NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_Exists
        FROM Sklepy
        WHERE ID = p_SklepID;

        IF v_Exists = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Sklep o podanym ID nie istnieje.');
            RETURN;
        END IF;
    END;
    
    -- Wyœwietlenie ID Sklepu
    DBMS_OUTPUT.PUT_LINE('ID Sklepu: ' || p_SklepID);
    
    -- Wyœwietlenie informacji o pokemonach
    FOR v_Record IN (
        SELECT p.ID AS PokemonID, p.Name, p.Lvl, p.Rarity, ObliczCenePokemona(p.ID) AS Cena
        FROM TABLE(SELECT s.AvailablePokemons FROM Sklepy s WHERE s.ID = p_SklepID) p
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Pokemon ID: ' || v_Record.PokemonID || 
                             ', Name: ' || v_Record.Name || 
                             ', Lvl: ' || v_Record.Lvl || 
                             ', Rarity: ' || v_Record.Rarity || 
                             ', Cena: ' || v_Record.Cena);
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nie znaleziono danych.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wyst¹pi³ b³¹d: ' || SQLERRM);
END;

PROCEDURE WyswietlWszystkichTrenerow AS
    -- Cursor for trainers
    CURSOR trenerzy_cursor IS SELECT * FROM Trenerzy;

    -- Cursor for Pokémon of a specific trainer
    CURSOR pokemons_cursor (v_trainer_id NUMBER) IS
        SELECT p.*
        FROM Pokemons p
        WHERE DEREF(p.Trainer_Ref).ID = v_trainer_id;

    -- Variables for each field in the Trener type
    v_id NUMBER;
    v_name VARCHAR2(100);
    v_pokedollars NUMBER;
    v_ranking VARCHAR2(50);
    v_wins NUMBER;

BEGIN
    -- Opening the cursor for trainers
    OPEN trenerzy_cursor;

    -- Loop for each trainer
    LOOP
        FETCH trenerzy_cursor INTO v_id, v_name, v_pokedollars, v_ranking, v_wins;
        EXIT WHEN trenerzy_cursor%NOTFOUND;

        -- Display information about the trainer
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id);
        DBMS_OUTPUT.PUT_LINE('Name: ' || v_name);
        DBMS_OUTPUT.PUT_LINE('Pokedollars: ' || v_pokedollars);
        DBMS_OUTPUT.PUT_LINE('Ranking: ' || v_ranking);
        DBMS_OUTPUT.PUT_LINE('Wins: ' || v_wins);

        -- Loop for each Pokémon of the current trainer
        FOR pokemon_rec IN pokemons_cursor(v_id) LOOP
            DBMS_OUTPUT.PUT_LINE('  Pokemon: ');
            DBMS_OUTPUT.PUT_LINE('    ID: ' || pokemon_rec.ID);
            DBMS_OUTPUT.PUT_LINE('    Name: ' || pokemon_rec.Name);
            -- Displaying other Pokémon details...
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('-------------------');
    END LOOP;

    -- Closing the cursor for trainers
    CLOSE trenerzy_cursor;
END WyswietlWszystkichTrenerow;

END POKEMONY;
/
