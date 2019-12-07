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

#=================#
#    Parametry    #
#=================#
param proporcje_surowca_do_polproduktow {SUROWCE_POLPRODUKTY};
param max_ton_surowcow {SUROWCE};
param cena_sprzedazy {WYROBY};
param progi_kosztow_surowca {PROGI_SUROWCE};
param max_wyrobow {WYROBY};
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

#==============#
#    Zmienne   #
#==============#

# SUROWCE
var u1 binary; # zmienna binarna dla pierwszego progu surowca 1
var u2 binary; # zmienna binarna dla drugiego progu surowca 1
var liczba_surowcow_przygotowalnia {SUROWCE};
var liczba_surowcow_obrobka_cieplna {SUROWCE};
var surowce_na_polprodukty {SUROWCE_POLPRODUKTY} >= 0 integer; 
var zakupione_surowce_kazdego_progu {PROGI_SUROWCE};
var koszt_zakupionych_surowcow = sum {(p, s) in PROGI_SUROWCE} zakupione_surowce_kazdego_progu[p, s] * progi_kosztow_surowca[p, s];
var liczba_zakupionych_surowcow {s in SUROWCE} = sum {p in PROGI_3} zakupione_surowce_kazdego_progu[p, s];

# TRANSPORT
var koszt_transportu_S1 = ceil(liczba_surowcow_przygotowalnia['S1']/ladownosc_na_wagon)*koszt_wagonu + ceil(liczba_surowcow_przygotowalnia['S1']/ladownosc_na_wagon/max_liczba_wagonow)*koszt_lokomotywy;
var koszt_transportu_S2 = ceil((liczba_surowcow_przygotowalnia['S2']+liczba_surowcow_obrobka_cieplna['S2'])/ladownosc_ciezarowki)*koszt_ciezarowki;
var koszty_transportu = koszt_transportu_S1 + koszt_transportu_S2;

# PRZYGOTOWALNIA
var liczba_pracownikow_przygotowalni  = liczba_pracownikow_na_jednostke_przerobowa * sum {s in SUROWCE} liczba_surowcow_przygotowalnia[s] / liczba_ton_surowca_na_jednostke_przerobowa;
var koszt_pracy_przygotowalni = liczba_pracownikow_przygotowalni * koszt_pracownika;
var liczba_polprodoktow {POLPRODUKTY} = sum {(s, p) in SUROWCE_POLPRODUKTY} (proporcje_surowca_do_polproduktow[s, p] *  surowce_na_polprodukty[s, p]);

# OBROBKA CIEPLNA
var obrobka_progi {PROGI_3} binary;
var koszt_obrobki_cieplnej = obrobka_progi['P2']*10000 + obrobka_progi['P3']*40000;

# WYROBY KONCOWE
# var liczba_wyrobow_koncowych {WYROBY} = {p in POLPRODUKTY} liczba_polprodoktow[p] + {s in SUROWCE} liczba_surowcow_obrobka_cieplna[s];
# var liczba_wyrobow_koncowych {w in WYROBY} = liczba_polprodoktow[w] + liczba_surowcow_obrobka_cieplna[w];
# var dochod_z_wyrobow = sum {w in WYROBY} liczba_wyrobow_koncowych[w] * cena_sprzedazy[w];  

#===================#
#   Funkcja Celu    #
#===================#
minimize koszty: koszt_zakupionych_surowcow + koszty_transportu + koszt_pracy_przygotowalni + koszt_obrobki_cieplnej;


#===================#
#   Ograniczenia    #
#===================#

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