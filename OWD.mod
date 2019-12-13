# Maciej Lenard  #
# OWD		     #
# zadanie 21     #

#==============#
#    Zbiory    #
#==============#

set SUROWCE;
set POLPRODUKTY;
set WYROBY;
set SUROWCE_POLPRODUKTY within {SUROWCE, POLPRODUKTY};
set PROGI_3;
set PROGI_SUROWCE within {PROGI_3, SUROWCE};
set SUROWCE_NA_WYROBY within {SUROWCE, WYROBY};
set POLPRODUKTY_NA_WYROBY within {POLPRODUKTY, WYROBY};

#=================#
#    Parametry    #
#=================#
param proporcje_surowca_do_polproduktow {SUROWCE_POLPRODUKTY};
param max_ton_surowcow {SUROWCE};
param cena_sprzedazy {WYROBY};
param progi_kosztow_surowca {PROGI_SUROWCE};
param progi_liczby_surowcow {PROGI_SUROWCE};
param przepustowosc_przygotowalnia ;
param koszt_lokomotywy;
param koszt_wagonu;
param koszt_ciezarowki;
param ladownosc_ciezarowki;
param max_liczba_wagonow;
param ladownosc_na_wagon;
param koszt_pracownika;
param liczba_pracownikow_na_jednostke_przerobowa;
param liczba_ton_surowca_na_jednostke_przerobowa;
param progi_obrobka_cieplna {PROGI_3};
param min_liczba_wyrobow {WYROBY};
param przetworzenie_surowce_na_wyroby {SUROWCE_NA_WYROBY};
param przetworzenie_polprodukty_na_wyroby {POLPRODUKTY_NA_WYROBY};

#==============#
#    Zmienne   #
#==============#

# SUROWCE
var u1 binary; # zmienna binarna dla pierwszego progu surowca 1
var u2 binary; # zmienna binarna dla drugiego progu surowca 1
var liczba_surowcow_przygotowalnia {SUROWCE} >= 0 integer;
var liczba_surowcow_obrobka_cieplna {SUROWCE} >= 0 integer;
var surowce_na_polprodukty {SUROWCE_POLPRODUKTY} >= 0 integer; 
var zakupione_surowce_kazdego_progu {PROGI_SUROWCE} >= 0 integer;
var liczba_zakupionych_surowcow {s in SUROWCE} = sum {p in PROGI_3} zakupione_surowce_kazdego_progu[p, s];
var koszt_zakupionych_surowcow = sum {(p, s) in PROGI_SUROWCE} (zakupione_surowce_kazdego_progu[p, s] * progi_kosztow_surowca[p, s]);

# TRANSPORT
var c1 integer >= 0; # reszta pomocnicza w liczeniu wagonow
var c2 integer >= 0; # reszta pomocnicza w liczeniu lokomotyw
var c3 integer >= 0; # reszta pomocnicza w liczeniu ciezarowek
var liczba_potrzebnych_lokomotyw integer >= 0;
var liczba_potrzebnych_ciezarowek integer >= 0;
var liczba_potrzebnych_wagonow integer >=0;

var koszt_transportu_S1 = (liczba_potrzebnych_wagonow * koszt_wagonu) + (liczba_potrzebnych_lokomotyw * koszt_lokomotywy);
var koszt_transportu_S2 = liczba_potrzebnych_ciezarowek * koszt_ciezarowki;
var koszty_transportu = koszt_transportu_S1 + koszt_transportu_S2;

# PRZYGOTOWALNIA
var liczba_pracownikow_przygotowalni  = liczba_pracownikow_na_jednostke_przerobowa * sum {s in SUROWCE} liczba_surowcow_przygotowalnia[s] / liczba_ton_surowca_na_jednostke_przerobowa;
var koszt_pracy_przygotowalni = liczba_pracownikow_przygotowalni * koszt_pracownika;
var liczba_polprodoktow {POLPRODUKTY} >= 0 integer;

# OBROBKA CIEPLNA
var obrobka_progi_binary {PROGI_3} binary;
var koszt_obrobki_cieplnej = obrobka_progi_binary['P2']*10000 + obrobka_progi_binary['P3']*40000;

# WYROBY KONCOWE
var liczba_wyrobow_koncowych {w in WYROBY} = sum {d in POLPRODUKTY} (liczba_polprodoktow[d] * przetworzenie_polprodukty_na_wyroby[d, w]) + sum {s in SUROWCE} (liczba_surowcow_obrobka_cieplna[s] * przetworzenie_surowce_na_wyroby[s, w]);
var niedobory_produktow = sum {w in WYROBY} (min_liczba_wyrobow[w] - liczba_wyrobow_koncowych[w]);
var dochod_z_wyrobow = sum {w in WYROBY} (liczba_wyrobow_koncowych[w] * cena_sprzedazy[w]);  


#===================#
#   Funkcja Celu    #
#===================#
# minimize koszty:  koszt_obrobki_cieplnej + koszt_pracy_przygotowalni + koszt_zakupionych_surowcow + koszty_transportu + niedobory_produktow;
# minimize koszty: koszt_obrobki_cieplnej + koszt_pracy_przygotowalni + koszt_zakupionych_surowcow + koszty_transportu + niedobory_produktow;
# minimize koszty: koszty_transportu;
maximize dochod: dochod_z_wyrobow - koszt_pracy_przygotowalni - koszt_zakupionych_surowcow - koszt_obrobki_cieplnej - koszty_transportu;


#===================#
#   Ograniczenia    #
#===================#

# Wyroby koncowe
s.t. OgrLiczbaWyrobowMIN {w in WYROBY}: liczba_wyrobow_koncowych[w] >= min_liczba_wyrobow[w];
s.t. OgrLiczbaWyrobowMAX : sum {w in WYROBY} liczba_wyrobow_koncowych[w] <= sum {s in SUROWCE} max_ton_surowcow[s];

# transport
s.t. WyliczenieLiczbyWagonow: liczba_zakupionych_surowcow['S1'] = liczba_potrzebnych_wagonow * ladownosc_na_wagon - c1;
s.t. WyliczenieLiczbyLokomotyw: liczba_potrzebnych_wagonow = liczba_potrzebnych_lokomotyw * max_liczba_wagonow - c2;
s.t. WyliczenieLiczbyCiezarowek: liczba_zakupionych_surowcow['S2'] = liczba_potrzebnych_ciezarowek * ladownosc_ciezarowki - c3;

# Surowce
s.t. MaksWykorzystaniaSurowcow {s in SUROWCE}: sum {d in POLPRODUKTY} surowce_na_polprodukty[s, d] + liczba_surowcow_obrobka_cieplna[s] <= sum {p in PROGI_3} zakupione_surowce_kazdego_progu[p, s];  

# Polprodukty
s.t. OgrPrzepustowoscPrzygotowalnia: sum {s in SUROWCE} liczba_surowcow_przygotowalnia[s] <= przepustowosc_przygotowalnia;
s.t. OgrPrzepustowoscPrzygotowalnia2 {s in SUROWCE}: liczba_surowcow_przygotowalnia[s] <= sum {p in PROGI_3} zakupione_surowce_kazdego_progu[p, s];
s.t. OgrPolprodukty2 {s in SUROWCE} : sum {d in POLPRODUKTY} surowce_na_polprodukty[s, d] <= liczba_surowcow_przygotowalnia[s];
s.t. OgrMaxIlosc {s in SUROWCE}: liczba_surowcow_przygotowalnia[s] + liczba_surowcow_obrobka_cieplna[s] <= max_ton_surowcow[s]; 

s.t. asf {d in POLPRODUKTY}: liczba_polprodoktow[d] <= sum {s in SUROWCE} (proporcje_surowca_do_polproduktow[s, d] *  surowce_na_polprodukty[s, d]);

# Obrobka cieplna
s.t. OgrObrobkaC: liczba_surowcow_obrobka_cieplna['S1'] <= 0;
s.t. OgrObrobkaC3: liczba_surowcow_obrobka_cieplna['S2'] >= 0;
s.t. OgrObrobkaP1min: sum {s in SUROWCE} liczba_surowcow_obrobka_cieplna[s] >= obrobka_progi_binary['P1'] * 0;
s.t. OgrObrobkaP2min: sum {s in SUROWCE} liczba_surowcow_obrobka_cieplna[s] >= obrobka_progi_binary['P2'] * (progi_obrobka_cieplna['P1'] + 1);
s.t. OgrObrobkaP3min: sum {s in SUROWCE} liczba_surowcow_obrobka_cieplna[s] >= obrobka_progi_binary['P3'] * (progi_obrobka_cieplna['P2'] + 1);
s.t. OgrObrobkaP3max: sum {s in SUROWCE} liczba_surowcow_obrobka_cieplna[s] <= obrobka_progi_binary['P3'] * progi_obrobka_cieplna['P3'];

# Kupno surowcow S1
s.t. kupno_p1s1_min: zakupione_surowce_kazdego_progu['P1','S1'] >= 0;
s.t. kupno_p1s1_max: zakupione_surowce_kazdego_progu['P1','S1'] <= progi_liczby_surowcow['P2', 'S1'] - progi_liczby_surowcow['P1', 'S1'];
s.t. kupno_p2s1_min: zakupione_surowce_kazdego_progu['P2','S1'] >= 0;
s.t. kupno_p2s1_max: zakupione_surowce_kazdego_progu['P2','S1'] <= progi_liczby_surowcow['P3', 'S1'] - progi_liczby_surowcow['P2', 'S1'];
s.t. kupno_p3s1_min: zakupione_surowce_kazdego_progu['P3','S1'] >= 0;
s.t. kupno_p3s1_max: zakupione_surowce_kazdego_progu['P2','S1'] <= max_ton_surowcow['S1'] - progi_liczby_surowcow['P3', 'S1'];

s.t. kupno_p1s1_binary1: zakupione_surowce_kazdego_progu['P1','S1'] >= u1*(progi_liczby_surowcow['P2', 'S1'] - progi_liczby_surowcow['P1', 'S1']);
s.t. kupno_p2s1_binary1: zakupione_surowce_kazdego_progu['P2','S1'] <= u1*(progi_liczby_surowcow['P3', 'S1'] - progi_liczby_surowcow['P2', 'S1']);
s.t. kupno_p2s1_binary2: zakupione_surowce_kazdego_progu['P2','S1'] >= u2*(progi_liczby_surowcow['P3', 'S1'] - progi_liczby_surowcow['P2', 'S1']);
s.t. kupno_p3s1_binary2: zakupione_surowce_kazdego_progu['P3','S1'] <= u2*(max_ton_surowcow['S1'] - progi_liczby_surowcow['P3', 'S1']);

# Kupno surowcow S2
s.t. kupno_p1s2_min: zakupione_surowce_kazdego_progu['P1','S2'] >= 0;
s.t. kupno_p1s2_max: zakupione_surowce_kazdego_progu['P1','S2'] <= progi_liczby_surowcow['P2', 'S2'] - progi_liczby_surowcow['P1', 'S2'];
s.t. kupno_p2s2_min: zakupione_surowce_kazdego_progu['P2','S2'] >= 0;
s.t. kupno_p2s2_max: zakupione_surowce_kazdego_progu['P2','S2'] <= progi_liczby_surowcow['P3', 'S2'] - progi_liczby_surowcow['P2', 'S2'];
s.t. kupno_p3s2_min: zakupione_surowce_kazdego_progu['P3','S2'] >= 0;
s.t. kupno_p3s2_max: zakupione_surowce_kazdego_progu['P3','S2'] <= max_ton_surowcow['S2'] - progi_liczby_surowcow['P3', 'S2'];