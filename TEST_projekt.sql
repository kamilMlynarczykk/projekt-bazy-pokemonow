set serveroutput on;

BEGIN
    DodajTrenera(1, 'Ash Ketchum', 100, 'Pocz¹tkuj¹cy', 0); -- ID, nazwa, ilosc waluty, ranking, wygrane
    DodajTrenera(2, 'Ash Ketchum2', 100, 'Pocz¹tkuj¹cy', 0);
    DodajTrenera(3, 'Ash Ketchum3', 100, 'Pocz¹tkuj¹cy', 0);
    DodajTrenera(4, 'Ash Ketchum4', 100, 'Pocz¹tkuj¹cy', 0);
    DodajTrenera(5, 'Ash Ketchum5', 100, 'Pocz¹tkuj¹cy', 0);
    DBMS_OUTPUT.PUT_LINE('Trener zosta³ dodany pomyœlnie.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wyst¹pi³ b³¹d: ' || SQLERRM);
END;
/

EXEC wyswietlwszystkichtrenerow();

BEGIN
    DodajPokemona(1, 'Pikachu', 35, 5, 55, 40, 50, 50, 90, 'Common', 'Electric', 1);
    DodajPokemona(2, 'Bulbasaur', 45, 57, 49, 49, 65, 65, 45, 'Common', 'Grass', 1);
    DodajPokemona(3, 'Charmander', 39, 6, 52, 43, 60, 50, 65, 'Common', 'Fire', 2);
    DodajPokemona(4, 'Squirtle', 44, 7, 48, 65, 50, 64, 43, 'Common', 'Water', 2);
    DodajPokemona(5, 'Caterpie', 45, 3, 30, 35, 20, 20, 45, 'Common', 'Bug', 3);
    DodajPokemona(6, 'Weedle', 40, 3, 35, 30, 20, 20, 50, 'Common', 'Bug', 3);
    DodajPokemona(7, 'Pidgey', 40, 3, 45, 40, 35, 35, 56, 'Common', 'Flying', 4);
    DodajPokemona(8, 'Rattata', 30, 3, 56, 35, 25, 35, 72, 'Common', 'Normal', 4);
    DodajPokemona(9, 'Spearow', 40, 3, 60, 30, 31, 31, 70, 'Common', 'Flying', 5);
    DodajPokemona(10, 'Ekans', 35, 3, 60, 44, 40, 54, 55, 'Common', 'Poison', 5);
    DodajPokemona(11, 'Sandshrew', 50, 4, 75, 85, 20, 30, 40, 'Common', 'Ground', -1);
    DodajPokemona(12, 'Nidoran?', 55, 5, 47, 52, 40, 40, 41, 'Common', 'Poison', -1);
    DodajPokemona(13, 'Nidoran?', 46, 5, 57, 40, 40, 40, 50, 'Common', 'Poison', -1);
    DodajPokemona(14, 'Clefairy', 70, 6, 45, 48, 60, 65, 35, 'Common', 'Fairy', -1);
    DodajPokemona(15, 'Vulpix', 38, 4, 41, 40, 50, 65, 65, 'Common', 'Fire', -1);
    DodajPokemona(16, 'Jigglypuff', 115, 5, 45, 20, 45, 25, 20, 'Common', 'Normal', -1);
    DBMS_OUTPUT.PUT_LINE('Pokemon zosta³ dodany pomyœlnie.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wyst¹pi³ b³¹d: ' || SQLERRM);
END;
/

EXEC wyswietlwszystkiepokemony();

BEGIN
    DodajSklep(1, 'PokeMart Central_1');
    DodajSklep(2, 'PokeMart Central_2');
    DodajSklep(3, 'PokeMart Central_3');
    DBMS_OUTPUT.PUT_LINE('Sklep zosta³ dodany pomyœlnie.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wyst¹pi³ b³¹d: ' || SQLERRM);
END;
/

EXEC wyswietlwszystkiesklepy();

BEGIN
    DodajPokemonaDoSklepu(1, 11); -- -- ID sklepu, ID pokemona
    DodajPokemonaDoSklepu(1, 12); 
    
    DodajPokemonaDoSklepu(2, 13);
    DodajPokemonaDoSklepu(2, 14);
    
    DodajPokemonaDoSklepu(3, 15);
    DodajPokemonaDoSklepu(3, 16);
    DBMS_OUTPUT.PUT_LINE('Pokemon zosta³ dodany do sklepu pomyœlnie.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wyst¹pi³ b³¹d: ' || SQLERRM);
END;
/

EXEC wyswietlsklepyipokemony;
BEGIN
    BuyPokemon(1, 1,12);
    DBMS_OUTPUT.PUT_LINE('Pokemon zosta³ dodany do trenera pomyœlnie.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wyst¹pi³ b³¹d: ' || SQLERRM);
END;
/

EXEC wyswietltrenerzyipokemony;
EXEC wyswietlsklepyipokemony;
BEGIN
    DodajRezerwacje(1, 1, 11, TO_DATE('2024-03-01 14:00', 'YYYY-MM-DD HH24:MI')); -- trener, sklep, pokemon, data 
    DodajRezerwacje(1, 2, 14, TO_DATE('2024-03-01 13:00', 'YYYY-MM-DD HH24:MI')); -- trener, sklep, pokemon, data   
    DodajRezerwacje(2, 3, 15, TO_DATE('2024-03-02 15:00', 'YYYY-MM-DD HH24:MI')); -- trener, sklep, pokemon, data   
    DodajRezerwacje(2, 3, 16, TO_DATE('2024-03-03 10:00', 'YYYY-MM-DD HH24:MI')); -- trener, sklep, pokemon, data   

    DBMS_OUTPUT.PUT_LINE('Test 1 zakoñczony sukcesem.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Test 1 zakoñczony b³êdem: ' || SQLERRM);
END;

EXEC wyswietlrezerwacjesklepu(1);
EXEC wyswietlrezerwacjesklepu(2);
EXEC wyswietlrezerwacjesklepu(3);
EXEC wyswietlrezerwacjetrenera(1);
EXEC wyswietlrezerwacjetrenera(2);
EXEC wyswietlrezerwacjetrenera(3);

EXEC displaystrongestpokemons(1);
EXEC wyswietltrenerzyipokemony;