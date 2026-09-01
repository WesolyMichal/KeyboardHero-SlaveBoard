# Keyboard Hero (Płytka Slave)

*Raport z projektu, v.1.0.1 (Data: 01.09.2026)*

**Autorzy:** Jakub Suder (JS), Michał Wesołowski (MW)  
**Kurs / Przedmiot:** MTM UEC2  

---

## 1. Repozytorium Git
* [KeyboardHero-SlaveBoard](https://github.com/WesolyMichal/KeyboardHero-SlaveBoard)
* [KeyboardHero-SlaveBoard](https://github.com/WesolyMichal/KeyboardHero-MasterBoard)
---

## 2. Wstęp
Projekt stanowi implementację gry rytmicznej zbliżonej do Guitar Hero, zrealizowaną z wykorzystaniem dwóch płytek Basys3. 
Płytka **Slave** w tej architekturze odpowiada wyłącznie za wyświetlanie obrazu rozgrywki na podłączonym monitorze.

---

## 3. Architektura (Slave)
* **Osoba odpowiedzialna:** Jakub Suder (JS)
* **Porty:** System korzysta z portu wejściowego `uart_rx` do odbioru danych z linii szeregowej UART oraz z portu wyjściowego `vga` komunikującego się z ekranem.
* **Interfejsy wewnętrzne:** Zaimplementowano interfejs `vga_if` do przesyłu sygnału wideo oraz `enable_bgs` służący do sterowania generatorami tła w zależności od etapu gry.
* **Rozprowadzenie zegara:** Główny zegar `clk100MHz` jest konwertowany na sygnał `clk65MHz` przez blok `clk_wiz_0`, a następnie kierowany do modułów komunikacyjnych, kontrolnych i toru VGA.

---

## 4. Implementacja i Zasoby (Slave)

### 4.1. Wykorzystanie zasobów (`top_slave_basys3`)
* **Slice LUTs:** 3706
* **Slice Registers:** 1282
* **F7 Muxes:** 100
* **F8 Muxes:** 9
* **Slice:** 1115

### 4.2. Marginesy czasowe
* **WNS (Worst Negative Slack):** 1.285 ns
* **WHS (Worst Hold Slack):** 0.022 ns

---

## 5. Konfiguracja sprzętu
1. **Połączenie płytek:** Dwie zworki łączące obie płytki:
   * Masa (GND) z masą (GND).
   * Pin `JA1` z pinem `JA1`.
2. **Wyświetlanie (Wideo):** Monitor podłączony jest do portu VGA płytki **SLAVE**.
