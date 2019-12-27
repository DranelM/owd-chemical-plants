# Maciej Lenard  #
# OWD		     #
# zadanie 21     #

#==============#
#    Zbiory    #
#==============#

set SUROWCE; # Zbiór surowców S1 S2
set POLPRODUKTY; # Zbiór półproduktów D1 D2
set WYROBY; # Zbiór wyrobów W1 W2
set SUROWCE_POLPRODUKTY within {SUROWCE, POLPRODUKTY}; # Zbiór łączony z surowców i półproduktów S1 S2 D1 D2
set PROGI_3; # Zbiór progów wykorzystywanych do wyznaczenia cen surowców, oraz obróbki cieplnej P1 P2 P3
set PROGI_SUROWCE within {PROGI_3, SUROWCE}; # Zbiór łączony z progów i surowców P1 P2 P3 S1 S2
set SUROWCE_NA_WYROBY within {SUROWCE, WYROBY}; # Zbiór łączony z surowców oraz progów S1 S2 W1 W2
set POLPRODUKTY_NA_WYROBY within {POLPRODUKTY, WYROBY}; # Zbiór łączony z półproduktów i wyrobów D1 D2 W1 W2

#=================#
#    Parametry    #
#=================#
param proporcje_surowca_do_polproduktow {SUROWCE_POLPRODUKTY};  # Wagi przekrztałceń surowców na półpdorukty w przygotowalni
param max_ton_surowcow {SUROWCE}; # Maksimum dziennej produkcji surowców
param cena_sprzedazy {WYROBY}; # Cena sprzedarzy wyprodukowanych wyrobów 
param progi_kosztow_surowca {PROGI_SUROWCE}; # Ceny dla każdego progu kosztów surowca
param progi_liczby_surowcow {PROGI_SUROWCE}; # ilość surowca dla każdego progu kosztów surowca
param przepustowosc_przygotowalnia ; # maksywalna ilość surowców przetworzonych w przygotowalni na dzień
param koszt_lokomotywy; # cena wynajęcia jednej lokomotywy
param koszt_wagonu; # cena wynajęcia jednego wagonu
param koszt_ciezarowki; # cena wynajęcia jednej ciężarówki
param ladownosc_ciezarowki; # ładowność jednej cuężarówki
param max_liczba_wagonow; # maksymalna liczba wagonów podpiętych pod lokomotywę
param ladownosc_na_wagon; # ładowność jednego wagonu
param koszt_pracownika; # koszt jednego pracownika
param liczba_pracownikow_na_jednostke_przerobowa; # minimalna liczba pracowników potrzebna do przygotowalni 
param liczba_ton_surowca_na_jednostke_przerobowa; # liczba ton surowców na minimalną liczbe pracowników w przygotowalni
param progi_obrobka_cieplna {PROGI_3}; # progi cen w obróbce cieplnej 
param min_liczba_wyrobow {WYROBY}; # minimalna liczba wyrobów wymagana przez kontrahentów do dostarczenia
param przetworzenie_surowce_na_wyroby {SUROWCE_NA_WYROBY}; # pomocnicza macierz do zamiany surowców na wyroby
param przetworzenie_polprodukty_na_wyroby {POLPRODUKTY_NA_WYROBY}; # pomocnicza macierz do zamiany półproduktów na wyroby

#==============#
#    Zmienne   #
#==============#

# SUROWCE
var u1 binary; # zmienna binarna dla pierwszego progu surowca 1
var u2 binary; # zmienna binarna dla drugiego progu surowca 1
var liczba_surowcow_przygotowalnia {SUROWCE} >= 0 integer;  # liczba surowców transportowanych do przygotowalni
var liczba_surowcow_obrobka_cieplna {SUROWCE} >= 0 integer; # liczba surowców transportowanych do obróbki cieplnej
var zakupione_surowce_kazdego_progu {PROGI_SUROWCE} >= 0 integer; # liczba zakupionych surowców każdego progu
var liczba_zakupionych_surowcow {s in SUROWCE} = sum {p in PROGI_3} zakupione_surowce_kazdego_progu[p, s]; # liczba zakupionych surowców
var koszt_zakupionych_surowcow = sum {(p, s) in PROGI_SUROWCE} (zakupione_surowce_kazdego_progu[p, s] * progi_kosztow_surowca[p, s]); # pełny koszt zakupionych surowców


# TRANSPORT
var liczba_potrzebnych_lokomotyw integer >= 0; # liczba lokomotyw potrzebnych do przewozu zakupionych surowców
var liczba_potrzebnych_ciezarowek integer >= 0; # liczba ciężarówek potrzebnych do przewozu zakupionych surowców
var liczba_potrzebnych_wagonow integer >=0; # liczba wagonów potrzebnych do przewozu zakupionych surowców

var koszt_transportu_S1 = (liczba_potrzebnych_wagonow * koszt_wagonu) + (liczba_potrzebnych_lokomotyw * koszt_lokomotywy); # koszt transportu surowca S1
var koszt_transportu_S2 = liczba_potrzebnych_ciezarowek * koszt_ciezarowki; # koszt transportu surowca S2
var koszty_transportu = koszt_transportu_S1 + koszt_transportu_S2; # sumaryczny koszt całego transportu

# PRZYGOTOWALNIA
var liczba_pracownikow_przygotowalni  = liczba_pracownikow_na_jednostke_przerobowa * sum {s in SUROWCE} liczba_surowcow_przygotowalnia[s] / liczba_ton_surowca_na_jednostke_przerobowa; # liczba osób pracujących w przygotowalni przy zakupionych surowcach
var koszt_pracy_przygotowalni = liczba_pracownikow_przygotowalni * koszt_pracownika; # koszt pracy przygotowalni
var liczba_polprodoktow {POLPRODUKTY} >= 0 integer; # liczba półproduktów stworzonych z zakupionych surowców

# OBROBKA CIEPLNA
var obrobka_progi_binary {PROGI_3} binary; # progi kosztu działania obróbki cieplnej
var koszt_obrobki_cieplnej = obrobka_progi_binary['P2']*10000 + obrobka_progi_binary['P3']*40000; # całkowity koszt obróbki cieplnej

# WYROBY KONCOWE
var liczba_wyrobow_koncowych {w in WYROBY} = sum {d in POLPRODUKTY} (liczba_polprodoktow[d] * przetworzenie_polprodukty_na_wyroby[d, w]) + sum {s in SUROWCE} (liczba_surowcow_obrobka_cieplna[s] * przetworzenie_surowce_na_wyroby[s, w]); # liczba wyrobów końcowych stworzonych z zakupionych surowców oraz przetworzonych półproduktów 
var dochod_z_wyrobow = sum {w in WYROBY} (liczba_wyrobow_koncowych[w] * cena_sprzedazy[w]);   # całkowity dochód ze sprzedaży wyprodukowanych wyrobów
var niedobory_kazdego_wyrobu {WYROBY}  >= 0 integer; # niedobory dla każdego wyrobu
var niedobory_suma = sum {w in WYROBY} niedobory_kazdego_wyrobu[w]; # całkowity niedobór wszystkich wyrobów

#===================#
#   Funkcja Celu    #
#===================#
minimize koszty:  koszt_zakupionych_surowcow + koszty_transportu + koszt_obrobki_cieplnej + koszt_pracy_przygotowalni + niedobory_suma;
# maximize dochod: dochod_z_wyrobow - koszt_zakupionych_surowcow - koszty_transportu - koszt_obrobki_cieplnej - koszt_pracy_przygotowalni;

#===================#
#   Ograniczenia    #
#===================#

# Surowce
s.t. MaksWykorzystaniaSurowcow {s in SUROWCE}: liczba_surowcow_przygotowalnia[s] + liczba_surowcow_obrobka_cieplna[s] = liczba_zakupionych_surowcow[s]; # liczba surowców w przygotowalni i obróbce cieplnej musi być równa liczbie zakupionych surowców
s.t. OgrMaxIlosc {s in SUROWCE}: liczba_zakupionych_surowcow[s] <= max_ton_surowcow[s]; # liczba zakupionych surowców nie może przekroczyć wartości maksymalnej

# Kupno surowcow S1
s.t. kupno_p1s1_min: zakupione_surowce_kazdego_progu['P1','S1'] >= 0; # ograniczenie dolne progu 1 dla surowca 1
s.t. kupno_p1s1_max: zakupione_surowce_kazdego_progu['P1','S1'] <= progi_liczby_surowcow['P2', 'S1'] - progi_liczby_surowcow['P1', 'S1']; # ograniczenie górne progu 1 dla surowca 1
s.t. kupno_p2s1_min: zakupione_surowce_kazdego_progu['P2','S1'] >= 0; # ograniczenie dolne progu 2 dla surowca 1
s.t. kupno_p2s1_max: zakupione_surowce_kazdego_progu['P2','S1'] <= progi_liczby_surowcow['P3', 'S1'] - progi_liczby_surowcow['P2', 'S1']; # ograniczenie górne progu 2 dla surowca 1
s.t. kupno_p3s1_min: zakupione_surowce_kazdego_progu['P3','S1'] >= 0; # ograniczenie dolne progu 3 dla surowca 1
s.t. kupno_p3s1_max: zakupione_surowce_kazdego_progu['P3','S1'] <= max_ton_surowcow['S1'] - progi_liczby_surowcow['P3', 'S1']; # ograniczenie górne progu 3 dla surowca 1

s.t. kupno_p1s1_binary1: zakupione_surowce_kazdego_progu['P1','S1'] >= u1*(progi_liczby_surowcow['P2', 'S1'] - progi_liczby_surowcow['P1', 'S1']); # dolne ograniczenie liczby surowców S1 dla kosztu pierwszego progu
s.t. kupno_p2s1_binary1: zakupione_surowce_kazdego_progu['P2','S1'] <= u1*(progi_liczby_surowcow['P3', 'S1'] - progi_liczby_surowcow['P2', 'S1']); # górne ograniczenie liczby surowców S1 dla kosztu drugiego progu
s.t. kupno_p2s1_binary2: zakupione_surowce_kazdego_progu['P2','S1'] >= u2*(progi_liczby_surowcow['P3', 'S1'] - progi_liczby_surowcow['P2', 'S1']); # dolne ograniczenie liczby surowców S1 dla kosztu drugiego progu
s.t. kupno_p3s1_binary2: zakupione_surowce_kazdego_progu['P3','S1'] <= u2*(max_ton_surowcow['S1'] - progi_liczby_surowcow['P3', 'S1']); # górne ograniczenie liczby surowców S1 dla kosztu trzeciego progu

# Kupno surowcow S2
s.t. kupno_p1s2_min: zakupione_surowce_kazdego_progu['P1','S2'] >= 0; # ograniczenie dolne progu 1 dla surowca 2
s.t. kupno_p1s2_max: zakupione_surowce_kazdego_progu['P1','S2'] <= progi_liczby_surowcow['P2', 'S2'] - progi_liczby_surowcow['P1', 'S2']; # ograniczenie górne progu 1 dla surowca 2
s.t. kupno_p2s2_min: zakupione_surowce_kazdego_progu['P2','S2'] >= 0; # ograniczenie dolne progu 2 dla surowca 2
s.t. kupno_p2s2_max: zakupione_surowce_kazdego_progu['P2','S2'] <= progi_liczby_surowcow['P3', 'S2'] - progi_liczby_surowcow['P2', 'S2']; # ograniczenie górne progu 2 dla surowca 2
s.t. kupno_p3s2_min: zakupione_surowce_kazdego_progu['P3','S2'] >= 0; # ograniczenie dolne progu 3 dla surowca 2
s.t. kupno_p3s2_max: zakupione_surowce_kazdego_progu['P3','S2'] <= max_ton_surowcow['S2'] - progi_liczby_surowcow['P3', 'S2']; # ograniczenie górne progu 3 dla surowca 2

# Transport
s.t. WyliczenieLiczbyWagonow: liczba_zakupionych_surowcow['S1'] <= liczba_potrzebnych_wagonow * ladownosc_na_wagon; # liczba wagonów musi odpowiadać liczbie surowców podzielonej przez ładowność wagonów
s.t. WyliczenieLiczbyLokomotyw: liczba_potrzebnych_wagonow <= liczba_potrzebnych_lokomotyw * max_liczba_wagonow ; # każda lokomotywa może mieć określoną maksymalną liczbe wagonów
s.t. WyliczenieLiczbyCiezarowek: liczba_zakupionych_surowcow['S2'] <= liczba_potrzebnych_ciezarowek * ladownosc_ciezarowki; # liczba ciężarówek względem zakupionych surowców i ładowności pojazdu

# Polprodukty
s.t. OgrPrzepustowoscPrzygotowalnia: sum {s in SUROWCE} liczba_surowcow_przygotowalnia[s] <= przepustowosc_przygotowalnia; # przygotowalnia ma określoną maksymalną przepustowość
s.t. OgrPrzepustowoscPrzygotowalnia2 {s in SUROWCE}: liczba_surowcow_przygotowalnia[s] <= sum {p in PROGI_3} zakupione_surowce_kazdego_progu[p, s]; # liczba zakupionych surowców nie może być większa niż liczba surowców dostarczonych do przygotowalni
s.t. OgrLiczbyPolproduktow {d in POLPRODUKTY}: liczba_polprodoktow[d] <= sum {s in SUROWCE} (proporcje_surowca_do_polproduktow[s, d] * liczba_surowcow_przygotowalnia[s]); # przekształcenie surowców w półprodukty na podstawie tabeli w poleceniu

# Obrobka cieplna
s.t. OgrObrobkaS1: liczba_surowcow_obrobka_cieplna['S1'] <= 0; # Obróbka cieplna nie obsługuje surowca S1
s.t. OgrObrobkaS2: liczba_surowcow_obrobka_cieplna['S2'] >= 0; # Ograniczenie dolne liczby surowców S2 w soróbce cieplnej
s.t. OgrObrobkaP1min: sum {s in SUROWCE} liczba_surowcow_obrobka_cieplna[s] >= obrobka_progi_binary['P1'] * 0; # ograniczenie dolne dla pierwszego progu kosztu obróbki cieplnej
s.t. OgrObrobkaP2min: sum {s in SUROWCE} liczba_surowcow_obrobka_cieplna[s] >= obrobka_progi_binary['P2'] * (progi_obrobka_cieplna['P1'] + 1); # ograniczenie dolne dla drugiego progu kosztu obróbki cieplnej
s.t. OgrObrobkaP3min: sum {s in SUROWCE} liczba_surowcow_obrobka_cieplna[s] >= obrobka_progi_binary['P3'] * (progi_obrobka_cieplna['P2'] + 1); # ograniczenie dolne dla trzeciego progu kosztu obróbki cieplnej
s.t. OgrObrobkaP3max: sum {s in SUROWCE} liczba_surowcow_obrobka_cieplna[s] <= obrobka_progi_binary['P3'] * progi_obrobka_cieplna['P3']; # ograniczenie górne dla trzeciego progu kosztu obróbki cieplnej


# Wyroby koncowe
s.t. OgrLiczbaWyrobowMIN {w in WYROBY}: liczba_wyrobow_koncowych[w] >= min_liczba_wyrobow[w]; # minimalna liczba wyrobów do wyprodukowania 
s.t. OgrLiczbaWyrobowMAX : sum {w in WYROBY} liczba_wyrobow_koncowych[w] <= sum {s in SUROWCE} max_ton_surowcow[s]; # liczba wyrobów nie może przekraczać liczby zakupionych surowców
s.t. OgrNiedobory {w in WYROBY}:  min_liczba_wyrobow[w] - liczba_wyrobow_koncowych[w] <= niedobory_kazdego_wyrobu[w]; # wyliczenie niedoborów wyprodukowanych wyrobów

# TODO: 
	# metoda punktu odniesienia 