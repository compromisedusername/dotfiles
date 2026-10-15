# Poradnik: Neovim pod DevOps

Ten plik otworzysz w każdej chwili skrótem **`<leader>H`**.

Interfejs configu (opisy skrótów w which-key, menu, komunikaty) jest po angielsku -
ten poradnik opisuje go po polsku i cytuje nazwy pozycji menu tak, jak widać je w edytorze.

---

## 0. Jak czytać skróty

| Zapis | Znaczy |
|---|---|
| `<leader>` | **Spacja** |
| `<C-h>` | Ctrl+h |
| `<A-j>` / `<M-j>` | Alt+j |
| `<S-l>` | Shift+l |
| `<CR>` | Enter |
| `<leader>ff` | spacja, potem `f`, potem `f` (po kolei, nie razem) |

**Najważniejsza rzecz:** wciśnij **spację** i poczekaj chwilę. **which-key** pokaże
wszystkie dostępne skróty pogrupowane tematycznie (`a` Claude, `f` szukanie, `g` git, `c` kod...).
Tak samo działa po `g`, `]`, `[`, `z`, `"`.

Inne ściągawki w samym edytorze:

- `<leader>fk` - przeszukaj **wszystkie** skróty (wpisz np. „git” albo „debug”)
- `<leader>?` - skróty dostępne w bieżącym buforze
- `:Tutor` - interaktywny kurs podstaw Vima (~30 min, warto raz przejść)
- `:help <temat>` lub `<leader>fh` - dokumentacja

---

## 1. Szybki start: typowy dzień pracy

```
cd ~/repos/infra && nvim .        # otwiera projekt z drzewem plików
<leader><space>                   # znajdź plik po nazwie (fuzzy)
<leader>fg                        # znajdź tekst w całym projekcie
gd / gr / K                       # definicja / użycia / dokumentacja symbolu
<leader>ca                        # „żarówka” - szybkie poprawki od LSP
:w                                # zapis + automatyczne formatowanie
]h / <leader>ghp                  # przejdź do zmiany git / podejrzyj ją
<leader>gg                        # lazygit: commit, push, rebase
<leader>ac                        # Claude Code obok kodu
<leader>qs                        # jutro: przywróć sesję (otwarte pliki, układ)
```

---

## 2. Okna, bufory, układ

| Skrót | Akcja |
|---|---|
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | przejdź do okna w lewo/dół/górę/prawo (drzewo ↔ kod ↔ Claude ↔ terminal; w tmuxie także do paneli tmuxa) |
| `<C-Left/Right/Up/Down>` | zmień rozmiar okna |
| `:vsp` / `:sp` | podziel okno pionowo / poziomo |
| `<C-w>q` lub `:q` | zamknij okno |
| `<C-w>=` | wyrównaj rozmiary okien |
| `<S-h>` / `<S-l>` | poprzedni / następny bufor (zakładki u góry) |
| `<leader>fb` | lista otwartych buforów (fuzzy) |
| `<leader>bd` | zamknij bufor (okno zostaje) |
| `<leader>bo` | zamknij wszystkie inne bufory |
| `<leader>bp` | przypnij bufor (nie zostanie zamknięty przez `bo`/`bl`/`br`) |
| `<leader>bl` / `<leader>br` | zamknij bufory po lewej / prawej |
| `<leader>z` | tryb zen (tylko bieżący plik, bez rozpraszaczy) |
| `<C-s>` | zapisz (działa też w trybie insert) |
| `<leader>qq` | wyjdź (zapyta o niezapisane pliki) |

---

## 3. Pliki

### neo-tree: drzewo z boku

`<leader>e` - pokaż/ukryj, `<leader>o` - przejdź do drzewa. Drzewo podąża za otwartym plikiem.

| W drzewie | Akcja |
|---|---|
| `<CR>` lub `l` | otwórz plik / rozwiń katalog |
| `h` | zwiń katalog |
| `s` / `S` / `t` | otwórz w pionowym / poziomym splicie / nowej karcie |
| `P` | podgląd pliku w okienku (bez otwierania) |
| `a` | **nowy plik** (zakończ nazwę `/`, żeby utworzyć katalog; `a/b/c.tf` tworzy całą ścieżkę) |
| `A` | nowy katalog |
| `r` / `b` | zmień nazwę / zmień nazwę bez rozszerzenia |
| `c` / `m` | kopiuj / przenieś (podajesz ścieżkę docelową) |
| `y` `x` `p` | kopiuj / wytnij / wklej (schowek drzewa, można zaznaczyć kilka przez `<Tab>`) |
| `T` | **do kosza** (bezpieczniej) - `d` usuwa na stałe |
| `Y` | kopiuj **pełną ścieżkę** do schowka systemowego |
| `H` | pokaż/ukryj pliki ukryte |
| `/` | szukaj w drzewie (fuzzy), `<C-x>` czyści filtr |
| `.` / `<BS>` | ustaw katalog jako root / idź katalog wyżej |
| `z` | zwiń wszystko |
| `<` `>` | przełącz źródło: Files / Buffers / Git |
| `i` | szczegóły pliku (rozmiar, daty) |
| `?` | pomoc ze wszystkimi klawiszami |

Inne widoki: `<leader>ge` - zmiany git jako drzewo, `<leader>be` - bufory jako drzewo.

### oil: katalog jak plik tekstowy

Idealne do **masowych operacji** (np. zmiana nazw 20 plików na raz).

- `-` - otwórz katalog bieżącego pliku (w oil `-` idzie katalog wyżej)
- `<leader>-` - oil w pływającym oknie
- Edytujesz listę jak zwykły tekst: zmień nazwę linii = zmiana nazwy pliku, usuń linię =
  usunięcie (do kosza), dopisz linię = nowy plik (`nazwa/` = katalog), `dd` + `p` w innym
  katalogu = przeniesienie. Możesz używać makr, `:s///`, wielu kursorów przez `<C-v>`.
- **`:w` zatwierdza** - oil pokaże listę operacji do potwierdzenia.
- `<CR>` otwórz, `<C-v>` otwórz w pionowym splicie, `gy` kopiuj ścieżkę, `g.` ukryte pliki,
  `<C-r>` odśwież, `q` zamknij, `g?` pomoc.

Przykład: zmień `*.yml` na `*.yaml` w katalogu: `-`, potem `:%s/\.yml$/.yaml/`, `:w`, potwierdź.

---

## 4. Szukanie (snacks picker)

| Skrót | Szuka |
|---|---|
| `<leader><space>` | pliki - „smart” (ostatnie + projekt) |
| `<leader>ff` | pliki w projekcie (też ukryte, np. `.gitlab-ci.yml`) |
| `<leader>fg` | **tekst w całym projekcie** (ripgrep) |
| `<leader>fw` | słowo pod kursorem / zaznaczenie w projekcie |
| `<leader>f/` | linie w bieżącym pliku |
| `<leader>fr` | ostatnio otwierane pliki |
| `<leader>fb` | bufory |
| `<leader>fd` | diagnostyka (błędy/ostrzeżenia) |
| `<leader>ft` | komentarze TODO/FIXME/HACK |
| `<leader>fp` | **rejestry / historia schowka** |
| `<leader>fu` | historia undo (drzewo zmian - cofnij do dowolnego momentu) |
| `<leader>fk` | skróty klawiszowe |
| `<leader>fh` | pomoc |
| `<leader>fn` | historia powiadomień |
| `<leader>fc` | pliki tego configu |
| `<leader>fR` | wznów ostatnie wyszukiwanie |

**W oknie wyszukiwania:**

| Klawisz | Akcja |
|---|---|
| `<C-j>` / `<C-k>` | góra / dół na liście |
| `<CR>` | otwórz |
| `<C-v>` / `<C-s>` / `<C-t>` | otwórz w pionowym / poziomym splicie / karcie |
| `<Tab>` | zaznacz wiele (potem `<CR>` otwiera wszystkie) |
| `<C-q>` | **wyślij wyniki do listy quickfix** (patrz niżej) |
| `<A-h>` / `<A-i>` | pokaż pliki ukryte / ignorowane przez git |
| `<A-p>` | podgląd wł./wył. |
| `<C-f>` / `<C-b>` | przewijanie podglądu |
| `<C-g>` | (grep) przełącz tryb na żywo / filtrowanie wyników |
| `?` | pomoc ze wszystkimi klawiszami |
| `<Esc>` | zamknij |

**Wyszukiwanie we wszystkich plikach + zamiana:** `<leader>fg` → wpisz frazę → `<C-q>`
(wyniki trafiają do quickfix) → `:cdo s/stare/nowe/g | update` - zamienia we wszystkich
znalezionych miejscach i zapisuje.

---

## 5. Edycja

### Schowek

- `y` kopiuje **do schowka systemowego** - wklejasz w Windows przez Ctrl+V.
- `p` wkleja ze schowka (to, co skopiowałeś w przeglądarce, też).
- `d`, `dd` też trafiają do schowka (to „wytnij”).
- `c`, `x` **nie** nadpisują schowka; wklejenie na zaznaczenie (`vp`) też nie.
- `<leader>fp` - historia rejestrów, gdy potrzebujesz czegoś skopiowanego wcześniej.

### Ruch i skoki

- **`s` + 2 litery** (flash) - skok w dowolne widoczne miejsce: wciśnij `s`, wpisz dwa
  znaki z miejsca docelowego, potem pokazaną literkę-etykietę. Działa też z operatorami: `ds` +
  skok usuwa tekst do tego miejsca.
- `S` (flash treesitter) - zaznacz cały blok kodu (funkcję, resource, argument) etykietą.
- `]]` / `[[` - następne/poprzednie wystąpienie słowa pod kursorem.
- `<C-o>` / `<C-i>` - wróć / naprzód po historii skoków (np. po `gd`).
- `%` - skok do pasującego nawiasu.
- `S` w trybie visual / po operatorze (np. `yS`, `dS`) - wybierz etykietą blok składni do
  zaznaczenia/skopiowania/usunięcia (wyraz, argument, wywołanie, cały `resource {}`).

### Text objects (mini.ai): operator + `i`/`a` + obiekt

`i` = wewnątrz, `a` = razem z otoczeniem. Operator: `d` usuń, `c` zmień, `y` kopiuj, `v` zaznacz.

| Przykład | Robi |
|---|---|
| `ci"` | zmień tekst w cudzysłowie (działa nawet gdy kursor jest przed cudzysłowem) |
| `da(` / `di{` / `ci[` | usuń nawias z zawartością / zawartość klamr / zmień w kwadratowych |
| `vaf` / `dif` | zaznacz funkcję / usuń ciało funkcji |
| `cia` / `daa` | zmień / usuń argument funkcji |
| `yiq` | kopiuj zawartość dowolnego cudzysłowu (`q` = ', " lub \`) |
| `vib` | zaznacz zawartość dowolnego nawiasu (`b` = ( [ {) |
| `cin"` / `cil"` | zmień w **następnym** / **poprzednim** cudzysłowie |

### Otaczanie (mini.surround): `gs` + akcja

| Przykład | Robi |
|---|---|
| `gsaiw"` | otocz słowo cudzysłowem: `foo` → `"foo"` |
| `gsa` (w visual) + `)` | otocz zaznaczenie nawiasem |
| `gsd"` | usuń otaczające `"` |
| `gsr"'` | zamień `"` na `'` |
| `gsr({` | zamień `( )` na `{ }` |

### Komentarze, linie, wcięcia

- `gcc` - zakomentuj/odkomentuj linię; `gc` + ruch (np. `gcap` - akapit) lub `gc` w visual.
- `<A-j>` / `<A-k>` - przesuń linię lub zaznaczenie w dół/górę (`<A-h>`/`<A-l>` w bok).
- Visual: `J`/`K` - przesuń zaznaczone linie, `>`/`<` - wcięcie (zaznaczenie zostaje).
- Nawiasy i cudzysłowy domykają się same (mini.pairs).

### Autouzupełnianie (blink.cmp)

| Klawisz | Akcja |
|---|---|
| `<Tab>` / `<S-Tab>` | następna / poprzednia podpowiedź; w snippecie - skok do następnego pola |
| `<CR>` | zatwierdź |
| `<C-space>` | otwórz podpowiedzi ręcznie / pokaż dokumentację |
| `<C-e>` | zamknij menu |
| `<C-b>` / `<C-f>` | przewiń dokumentację |

**Snippety:** wpisz początek skrótu i wybierz z menu (oznaczone jako Snippet), potem `<Tab>`
skacze między polami do uzupełnienia:

- **Terraform:** `tf-variable`, `tf-output`, `tf-module`, `tf-` + nazwa zasobu (np.
  `tf-aws_s3_bucket`, `tf-kubernetes_namespace`); argumenty zasobów podpowiada też terraformls.
- **Kubernetes (YAML):** `k-deployment`, `k-service`, `k-ingress`, `k-configmap`, `k-secret`,
  `k-cronjob`, `k-statefulset`, `k-pvc`, `k-namespace`, `k-kustomization`.
- **Python:** `def`, `class`, `ifmain`, `try`, `with`; **bash:** `if`, `for`, `case`, `func`.

### Undo

- `u` cofnij, `<C-r>` ponów. Historia zostaje **po zamknięciu pliku** (persistent undo).
- `<leader>fu` - drzewo całej historii z podglądem, możesz wrócić do dowolnej wersji.

---

## 6. LSP - inteligencja kodu

Serwery języka uruchamiają się same po otwarciu pliku. Aktywne widać w pasku statusu na dole.

| Skrót | Akcja |
|---|---|
| `K` | dokumentacja symbolu (np. opis argumentu zasobu Terraform) - `K` ponownie wchodzi do okienka |
| `gd` | idź do definicji (np. do `variable`, modułu, funkcji) |
| `gr` | lista wszystkich użyć |
| `gI` / `gy` / `gD` | implementacje / definicja typu / deklaracja |
| `<leader>ca` | **akcje kodu** (szybkie poprawki, importy, generowanie) |
| `<leader>cr` | zmiana nazwy we wszystkich plikach projektu |
| `<leader>cs` / `<leader>cS` | symbole w pliku / w projekcie (np. wszystkie `resource`) |
| `<leader>uh` | podpowiedzi typów inline wł./wył. |
| `gx` | otwórz link pod kursorem w przeglądarce (Windows) |
| `<leader>ci` | stan LSP (gdy coś nie działa) |

### Diagnostyka (błędy, ostrzeżenia)

| Skrót | Akcja |
|---|---|
| `]d` / `[d` | następny / poprzedni problem (z okienkiem opisu) |
| `<leader>cd` | opis problemu w bieżącej linii |
| `<leader>xx` | **Trouble**: lista problemów w całym projekcie |
| `<leader>xX` | problemy tylko w tym pliku |
| `<leader>xq` | lista quickfix w Trouble |
| `<leader>xt` | wszystkie TODO/FIXME w projekcie |
| `<leader>ud` | diagnostyka wł./wył. |

---

## 7. Formatowanie i lintery

- **Zapis (`:w`) formatuje automatycznie**: Terraform (`terraform fmt`), Python (ruff + sortowanie
  importów), bash (shfmt), Lua (stylua), JSON (jq), YAML (yamlls).
  Helm i Ansible są pomijane (formatowanie mogłoby zepsuć szablony).
- `<leader>cf` - formatuj ręcznie (w visual: tylko zaznaczenie).
- `<leader>uf` - format przy zapisie wł./wył. globalnie, `<leader>uF` - tylko w tym pliku.
- `:ConformInfo` - który formater działa dla bieżącego pliku.
- Lintery działają w tle: shellcheck (bash), tflint (Terraform), ruff + pyright (Python),
  hadolint (Dockerfile), `zsh -n` (zsh).

---

## 8. Git

### W edytorze (gitsigns)

Kolorowe paski przy numerach linii: dodane / zmienione / usunięte.

| Skrót | Akcja |
|---|---|
| `]h` / `[h` | następna / poprzednia zmiana (hunk) |
| `<leader>ghp` | podgląd zmiany inline (co było przed) |
| `<leader>ghs` / `<leader>ghr` | stage / cofnij zmianę (w visual: tylko zaznaczone linie) |
| `<leader>ghS` / `<leader>ghR` | stage / cofnij cały plik |
| `<leader>ghd` | diff pliku z indeksem |
| `<leader>gb` | blame linii (kto, kiedy, który commit) |
| `<leader>gB` | otwórz plik/linię w GitLabie w przeglądarce |

### lazygit: `<leader>gg`

Pełny klient git w pływającym oknie. Najważniejsze klawisze w lazygit:

- `<Space>` stage/unstage pliku, `a` stage wszystko, `<CR>` wejdź w plik i stage'uj pojedyncze linie
- `c` commit, `A` amend, `P` push, `p` pull, `f` fetch
- `b` gałęzie (w panelu gałęzi: `<Space>` checkout, `n` nowa, `r` rebase, `M` merge)
- `s` stash, `z` undo ostatniej operacji
- `[` / `]` przełączaj zakładki paneli, `?` pomoc, `q` wyjdź
- W commitach: `i` interaktywny rebase (`s` squash, `f` fixup, `d` drop, `e` edit)

Inne: `<leader>gs` - status jako lista, `<leader>gl` - log z podglądem diffów.

---

## 9. Terminal

| Skrót | Akcja |
|---|---|
| `<C-\>` | terminal na dole wł./wył. (działa też z wnętrza terminala) |
| `<leader>tt` | terminal na dole |
| `<leader>tf` | terminal pływający |
| `<leader>tk` / `<leader>k9` | **k9s** na pełnym ekranie (więcej: rozdział Kubernetes) |
| `<Esc><Esc>` | z terminala do trybu normalnego (przewijanie, kopiowanie); `i` wraca |
| `<C-h/j/k/l>` | z terminala do sąsiedniego okna |

`KUBE_EDITOR=nvim` - `kubectl edit deploy/x` otwiera manifest w nvimie z walidacją schematu K8s.

---

## 9a. Kubernetes (`<leader>k`)

Własny moduł (`lua/kube/init.lua`) oparty tylko na `kubectl` i `helm` - działa z Twoim kubeconfigiem.
Na dole w pasku statusu widać **⎈ kontekst/namespace** - na **czerwono** na produkcji. Produkcja to
nazwa, w której jest osobne słowo `prod`, `prd` lub `production` (np. `acme-prod-eu`, `db-prd`);
`nonprod`, `non-prod` i `preprod` produkcją **nie** są. Listę słów zmienisz w `M.prod_words`
(moduł), `PROD_WORDS` (`kcfg-info`) i `POWERLEVEL9K_KUBECONTEXT_CLASSES` (`~/.p10k.zsh`). Ten sam
kontekst na czerwono z `⚠ PROD` pokazuje prompt zsh przy `kubectl`/`k`/`helm`/`k9s`/`stern`.

### Bezpieczeństwo

- Każda operacja zmieniająca klaster (apply, delete, edit, restart, undo, exec, cordon, drain) **pyta
  o potwierdzenie** i pokazuje kontekst i namespace.
- Na **produkcji** trzeba **wpisać nazwę kontekstu** - samo Enter nie wystarczy.
- Operacja wykonuje się z jawnym `--context` - tym, który potwierdziłeś.
- Bufor edycji zasobu **odmówi zapisu**, jeśli w międzyczasie zmieniłeś kontekst (np. w innym terminalu).
- Odkodowane Secrety są tylko w pamięci (bez pliku, swapa i historii undo). Nie zaznaczaj ich
  zawartości, gdy Claude jest podłączony - zaznaczenie trafia do jego kontekstu.

### Kubeconfigi: jeden plik na klaster

Każdy klaster to osobny plik w **`~/.kube/configs/<nazwa>.yaml`** (uprawnienia `600`, poza repo
dotfiles - zawierają dane dostępowe). `~/.kube/config` to symlink do pliku **domyślnego** dla nowych
terminali. Wybór kubeconfiga ustawia `$KUBECONFIG` **tylko w bieżącym terminalu / nvimie** - inne
okna zostają na swoim klastrze.

W zsh:

| Polecenie | Akcja |
|---|---|
| `kcfg` | wybierz kubeconfig dla **tego terminala** (fzf; podgląd: serwer, namespace, tożsamość, ostrzeżenia) |
| `kcfg <nazwa>` | od razu użyj `~/.kube/configs/<nazwa>.yaml` (Tab podpowiada nazwy) |
| `kcfg -l` | tabela: nazwa, kontekst, namespace, serwer, typ uwierzytelnienia, tożsamość, data wygaśnięcia (`*` aktywny, `D` domyślny, `P` produkcja, `!` ostrzeżenia) |
| `kcfg -r` | wróć do domyślnego w tym terminalu |
| `kcfg -d [nazwa]` | ustaw domyślny dla nowych terminali (przestawia symlink `~/.kube/config`) |
| `kcfg-add <plik> [nazwa]` | **dodaj nowy klaster**: pokazuje serwer, tożsamość i ostrzeżenia, pyta o zgodę, kopiuje z `600` |
| `kcfg-info --show <plik>` | szczegóły dowolnego pliku kubeconfig (bez wypisywania sekretów) |

W nvimie: **`<leader>kf`** - ta sama tabela co `kcfg` (nagłówek kolumn u góry, produkcja na
czerwono, aktywny na zielono) i panel szczegółów pod spodem; `j`/`k` ruch, `/` szukanie, `Enter`
wybór, `r` powrót do domyślnego, `q` zamknięcie; wybór działa tylko w tej instancji nvima (terminale, k9s i logi otwarte z nvima go
dziedziczą). Pasek statusu pokazuje
`⎈ plik › kontekst/namespace`, gdy nazwa pliku różni się od kontekstu.

**Tożsamość** jest odczytywana lokalnie z pliku: dla tokenów - konto serwisowe (`SA namespace/nazwa`)
i data wygaśnięcia, dla certyfikatów - `CN`/`O` i data ważności, dla wtyczek `exec` (EKS/GKE/AKS) -
uruchamiane polecenie. Sam token nigdy nie jest wyświetlany, a wtyczki `exec` nie są uruchamiane.

**Ostrzeżenia `!`:** wtyczka `exec` (uruchamia polecenie przy każdym `kubectl` - sprawdź, czy to
znane narzędzie, np. `aws eks get-token`), `insecure-skip-tls-verify`, wygasły token, złe
uprawnienia pliku.

Okno potwierdzenia operacji w nvimie (apply, delete, edit, restart...) pokazuje teraz **plik
kubeconfig, kontekst, namespace, serwer i tożsamość**. Za produkcję uznawany jest też plik, którego
nazwa zawiera słowo `prod`/`prd`/`production` - warto tak nazywać pliki produkcyjne (np. `acme-prod-eu.yaml`).

Typowo:

```sh
kcfg-add ~/Downloads/kubeconfig-acme-prod.yaml acme-prod-eu   # nowy klaster
kcfg acme-prod-eu        # ten terminal → produkcja (czerwony prompt)
nvim .                   # nvim w tym terminalu też widzi produkcję
kcfg -r                  # z powrotem na domyślny
```

`kind` i `minikube` przy tworzeniu klastra dopisują go do `~/.kube/config` (czyli do pliku
domyślnego). Lepiej od razu do osobnego pliku:
`kind create cluster --name test --kubeconfig ~/.kube/configs/kind-test.yaml`.

### Kontekst i namespace

| Skrót | Akcja |
|---|---|
| `<leader>kf` | przełącz **kubeconfig** (tylko w tym nvimie) |
| `<leader>kc` | przełącz kontekst w aktywnym kubeconfigu (produkcyjne oznaczone ⚠) |
| `<leader>kn` | przełącz namespace (zapisuje się w kubeconfigu, działa też w terminalu) |

### Praca z manifestami

| Skrót | Akcja |
|---|---|
| `K` | **`kubectl explain`** dla pola pod kursorem, np. na `limits` w kontenerze → dokumentacja `deployment.spec.template.spec.containers.resources.limits`. Działa też dla CRD (dane z klastra). Bez dostępu do klastra - zwykła dokumentacja ze schematu |
| `<leader>kd` | **diff** pliku (lub zaznaczenia w visual) z tym, co jest w klastrze - przed każdym apply |
| `<leader>ka` | **apply** pliku lub zaznaczenia (także niezapisanych zmian) |
| `<leader>kD` | delete zasobów opisanych w pliku/zaznaczeniu |
| `<leader>kv` | walidacja: **kubeconform** (schemat K8s + CRD) i **kube-linter** (dobre praktyki) |
| `<leader>kS` | dodaj na górze pliku schemat dla yamlls - podpowiedzi i walidacja także dla CRD (ArgoCD `Application`, cert-manager `Certificate`, Istio...) |
| `<leader>kh` | **helm template** wykresu, w którym jesteś (w pliku `values-*.yaml` - z tymi wartościami) |
| `<leader>kH` | helm lint + walidacja wyrenderowanego wykresu (kubeconform + kube-linter) |
| `<leader>kk` | **kustomize build** bieżącego katalogu |

Walidacja działa też **automatycznie**: po otwarciu i zapisie manifestu błędy schematu (literówka
w kluczu, zły typ, brak wymaganego pola) i ostrzeżenia kube-linter (brak limitów, root, `latest`,
brak sond) pojawiają się w diagnostyce - `]d`, `<leader>xx`. Schematy pobierają się raz i są
trzymane w cache.

Typowy cykl: edytujesz manifest → `<leader>kd` (co się zmieni) → `<leader>ka` (apply) → `<leader>kl` (logi).

### Klaster

| Skrót | Akcja |
|---|---|
| `<leader>kg` | **przeglądaj zasoby**: typ → obiekt → `describe` / `yaml` / **`edit`** / `events` / `logs` / `exec` / `delete` |
| `<leader>kl` | **logi** poda na żywo (wybór poda i kontenera) |
| `<leader>kx` | **exec** - powłoka w kontenerze (bash, a gdy go brak - sh) |
| `<leader>ke` | **zdarzenia** (`current namespace` / `all namespaces`) - pierwsze miejsce przy „czemu pod nie wstaje” |
| `<leader>kt` | `kubectl top` węzłów i podów (wymaga metrics-server) |
| `<leader>kr` | **rollout**: `status (live)` / `history` / `restart` / `undo` |
| `<leader>ks` | **Secret** z odkodowanymi wartościami |
| `<leader>kp` | **port-forward**: uruchom nowy (usługa/pod + porty) albo zatrzymaj działający |
| `<leader>kN` | **węzły**: describe / top / cordon / uncordon / drain |
| `<leader>k9` | **k9s** na pełnym ekranie (`:` + typ zasobu, `/` filtr, `l` logi, `s` shell, `d` describe, `?` pomoc) |

**Edycja zasobu** (`<leader>kg` → obiekt → `edit`): YAML z klastra otwiera się w buforze z
walidacją yamlls. `:w` wysyła zmiany (`kubectl replace`) po potwierdzeniu, potem bufor odświeża
się aktualną wersją. Jeśli ktoś zmienił obiekt w międzyczasie, klaster odrzuci zapis (konflikt
wersji) - nic się nie nadpisze.

### Narzędzia w terminalu

- **stern** - logi z wielu podów naraz, kolorowane:
  `stern -n app api-` (wszystkie pody zaczynające się od `api-`), `stern -l app=web --since 10m`,
  `stern . -n app --exclude-container istio-proxy`.
- **kubeconform** - walidacja w CI lub ręcznie: `kubeconform -summary -strict k8s/`.
- **kube-linter** - `kube-linter lint k8s/` albo cały wykres: `kube-linter lint ./chart`.
- **k9s** - `k9s` (albo `<leader>k9` w nvimie), `k9s --context <ctx> -n <ns>`.
- Wtyczki **krew** (instalujesz sam, każda to osobny program z dostępem do klastra - sprawdź przed
  instalacją): `neat` (czysty YAML), `tree` (drzewo właścicieli), `who-can` / `rbac-tool` (audyt
  RBAC), `resource-capacity`, `images`, `df-pv`. Instalacja: `kubectl krew install <nazwa>`.

## 10. Claude Code (`<leader>a`)

| Skrót | Akcja |
|---|---|
| `<leader>ac` | otwórz/zamknij Claude w panelu po prawej |
| `<leader>af` | przejdź do panelu Claude |
| `<leader>as` | (visual) wyślij zaznaczony kod jako kontekst; (w neo-tree) dodaj plik/katalog |
| `<leader>ab` | dodaj bieżący plik do kontekstu |
| `<leader>aa` / `<leader>ad` | **zaakceptuj / odrzuć** zmianę zaproponowaną przez Claude |
| `<leader>ar` | wznów wcześniejszą rozmowę (lista) |
| `<leader>aC` | kontynuuj ostatnią rozmowę |
| `<leader>am` | wybierz model |

**Jak to działa:**

1. Claude **widzi aktualny plik i zaznaczenie** - nie musisz nic wklejać.
2. Gdy Claude chce zmienić plik, otwiera się **diff obok siebie**. Możesz go jeszcze poprawić
   ręcznie, a potem `<leader>aa` (lub `:w`) akceptuje, `<leader>ad` odrzuca.
3. Claude czyta też **diagnostykę LSP**: „napraw błędy tflint w tym pliku”, „czemu pyright tu
   krzyczy” działa bez kopiowania komunikatów.
4. Zaznacz fragment (`V` + ruch) → `<leader>as` → zapytaj „co tu się dzieje?” / „dodaj obsługę błędów”.
5. Pliki zmienione przez Claude odświeżają się w buforach automatycznie.

Dobre prośby w DevOps:

- „Dodaj zmienną `environment` do tego modułu i użyj jej w tagach wszystkich zasobów.”
- „Przepisz ten Deployment tak, żeby miał readinessProbe, limity i securityContext non-root.”
- „Dlaczego ten pipeline `.gitlab-ci.yml` nie uruchamia joba na tagach?”
- „Napisz test pytest dla tej funkcji” → potem `<leader>Tt`, żeby go od razu uruchomić.
- „Zrób z tego skryptu bash wersję odporną na błędy (set -euo pipefail, walidacja argumentów).”

Claude uruchomiony w zwykłym terminalu w tym samym katalogu też połączy się z nvimem: wpisz w nim `/ide`.

---

## 11. Python: venv, testy, debugger

### Wirtualne środowisko

Jeśli w katalogu projektu jest `.venv/` lub `venv/`, pyright, testy i debugger używają go
**automatycznie** (podpowiedzi z zainstalowanych bibliotek, właściwy pytest). Aktywowany
`VIRTUAL_ENV` (np. `source .venv/bin/activate` przed `nvim`) ma pierwszeństwo.

```sh
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt pytest
```

### Testy (neotest + pytest) - `<leader>T`

| Skrót | Akcja |
|---|---|
| `<leader>Tt` | uruchom test pod kursorem |
| `<leader>Tf` | wszystkie testy w pliku |
| `<leader>Ta` | wszystkie testy w projekcie |
| `<leader>Tl` | powtórz ostatnie uruchomienie |
| `<leader>Td` | **debuguj** test pod kursorem (zatrzyma się na breakpointach) |
| `<leader>Ts` | drzewo testów z wynikami (`r` uruchom, `o` wynik, `i` przejdź do testu, `<CR>` rozwiń) |
| `<leader>To` | wynik testu pod kursorem (asercje, traceback) |
| `<leader>TO` | panel z pełnym wyjściem |
| `]T` / `[T` | następny / poprzedni **nieudany** test |
| `<leader>TS` | zatrzymaj |

Wyniki widać przy kodzie: ✓ / ✗ obok każdego testu.

### Debugger (nvim-dap + debugpy) - `<leader>d` i klawisze F

| Skrót | Akcja |
|---|---|
| `<F9>` lub `<leader>db` | breakpoint wł./wył. |
| `<leader>dB` | breakpoint warunkowy (np. `i == 42`) |
| `<F5>` lub `<leader>dc` | **start** (wybierz konfigurację, np. „file”) / kontynuuj |
| `<F10>` / `<F11>` / `<F12>` | krok dalej / wejdź do funkcji / wyjdź z funkcji |
| `<leader>dC` | uruchom do kursora |
| `<leader>de` | wartość wyrażenia pod kursorem / zaznaczenia |
| `<leader>dv` | panel debuggera (zmienne, stos, breakpointy, watch) |
| `<leader>dr` | REPL - wykonuj kod Pythona w kontekście zatrzymanego programu |
| `<leader>dl` | powtórz ostatnią sesję |
| `<leader>dt` | zakończ |
| `<leader>dm` / `<leader>dk` | debuguj metodę / klasę testową |

Wartości zmiennych pokazują się na szaro obok kodu podczas debugowania. Panel otwiera się
i zamyka sam.

---

## 12. DevOps: co działa per technologia

### Terraform / HCL

- `K` na nazwie zasobu lub argumentu - dokumentacja providera.
- `gd` na `var.x`, `module.y`, `local.z` - skok do definicji (także między plikami).
- Podpowiedzi argumentów zasobów, nazw zasobów, wartości enum.
- tflint pokazuje błędy na bieżąco (np. nieistniejący typ instancji, nieużywane zmienne).
- Zapis = `terraform fmt`.
- `<leader>tt` → `terraform plan` w terminalu obok; `<leader>fg` → szukanie np. wszystkich
  użyć modułu.

### Kubernetes / YAML

- yamlls waliduje pliki wg **SchemaStore** (GitLab CI, GitHub Actions, docker-compose,
  Chart.yaml, kustomization, Ansible...) - błędy i podpowiedzi kluczy z dokumentacją (`K`).
- Manifesty K8s w katalogach `k8s/`, `kubernetes/`, `manifests/` - schemat Kubernetes automatycznie;
  w każdym innym pliku i dla CRD: `<leader>kS`. Do tego kubeconform i kube-linter w tle.
- Dla dowolnego innego pliku dodaj na górze:
  ```yaml
  # yaml-language-server: $schema=https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.33.0-standalone-strict/all.json
  ```
- `gO` / `<leader>cs` - spis kluczy dokumentu (szybka nawigacja po dużych YAML-ach).

### Helm

- Pliki w `templates/` wewnątrz katalogu z `Chart.yaml` → typ `helm`: helm_ls podpowiada
  `.Values.*` (z `values.yaml`), funkcje szablonów, `gd` skacze do wartości w `values.yaml`.
- `<leader>tt` → `helm template . | less` / `helm lint`.

### Ansible

- Pliki w `playbooks/`, `roles/*/tasks|handlers/`, `group_vars/`, `host_vars/` → ansiblels:
  podpowiedzi modułów i parametrów, `K` = dokumentacja modułu, walidacja.

### Docker

- Dockerfile: dockerls (podpowiedzi instrukcji) + **hadolint** (dobre praktyki, np. przypinanie
  wersji w `apt-get install`).
- `docker-compose.yml` / `compose.yaml`: walidacja i podpowiedzi usług.

### Bash / zsh

- Bash: bashls + **shellcheck** na bieżąco (brak cudzysłowów, niezainicjalizowane zmienne...),
  `K` na komendzie = jej opis, zapis = shfmt.
- zsh (`.zshrc`, `*.zsh`): podświetlanie + sprawdzanie składni `zsh -n`.

### JSON, Markdown

- JSON: walidacja schematów (np. `package.json`, `tsconfig`), zapis formatuje przez `jq`.
- Markdown: renderowany w buforze (nagłówki, tabele, checkboxy); w trybie insert widać surowy
  tekst. `<leader>um` przełącza.

---

## 13. Sesje, przełączniki, inne

| Skrót | Akcja |
|---|---|
| `<leader>qs` | przywróć sesję dla bieżącego katalogu (pliki, układ okien) |
| `<leader>ql` | przywróć ostatnią sesję |
| `<leader>qd` | nie zapisuj sesji przy wyjściu |
| `<leader>uw` | zawijanie linii wł./wył. |
| `<leader>ur` | numeracja względna wł./wył. (przydatna do `5j`, `3dd`) |
| `<leader>un` | ukryj powiadomienia |
| `]t` / `[t` | następny / poprzedni komentarz TODO/FIXME |
| `<Esc>` | wyczyść podświetlenie wyszukiwania |

Ekran startowy (`nvim` bez argumentów): `f` plik, `g` grep, `r` ostatnie, `s` sesja, `c` config.

---

## 14. Utrzymanie configu

| Komenda | Do czego |
|---|---|
| `:Lazy` | wtyczki: `U` aktualizuj, `S` synchronizuj z lockfile, `L` log zmian, `X` wyczyść |
| `:Mason` (`<leader>cm`) | serwery LSP / formatery / lintery: `i` instaluj, `u` aktualizuj, `X` usuń |
| `:checkhealth` | diagnostyka całego środowiska |
| `:checkhealth vim.lsp` | stan serwerów języka |
| `:ConformInfo` | formatery dla bieżącego pliku |
| `:TSUpdate` | aktualizacja parserów składni |

**Aktualizacje (bezpiecznie):** `:Lazy update` → przejrzyj `L` (log) → sprawdź, czy wszystko
działa → zacommituj `lazy-lock.json`:

```sh
cd ~/dotfiles && git add -A && git commit -m "nvim: update plugins" && git push
```

Coś się zepsuło po aktualizacji? `git checkout nvim/.config/nvim/lazy-lock.json` i w nvimie
`:Lazy restore` - wraca do poprzednich wersji.

### Dodawanie rzeczy

- **Nowa wtyczka:** nowy plik `lua/plugins/<nazwa>.lua`:
  ```lua
  return {
    "autor/wtyczka.nvim",
    event = "VeryLazy",            -- albo ft = "python", cmd = "Komenda", keys = {...}
    opts = {},
    keys = { { "<leader>xy", "<cmd>Komenda<cr>", desc = "Opis do which-key" } },
  }
  ```
  Przed dodaniem sprawdź repo (gwiazdki, aktywność, czy nie pobiera binarek).
- **Nowy język:** serwer do `servers` w `lua/plugins/lsp.lua`, parser do `ensure_installed` w
  `treesitter.lua`, formater do `formatters_by_ft` w `formatting.lua`.
- **Wyłączenie wtyczki:** dopisz `enabled = false` w jej specyfikacji.
- **Gotowe dodatki:** `lua/plugins/extras.lua` (np. GitHub Copilot).

### tmux (opcjonalnie)

Ctrl+h/j/k/l przechodzi z nvima do paneli tmuxa automatycznie. Żeby działało też **z tmuxa do
nvima**, dopisz do `~/.tmux.conf`:

```tmux
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
bind-key -n C-h if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n C-j if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n C-k if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n C-l if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'
```

---

## 15. Plan nauki

1. **Tydzień 1:** `:Tutor`, `<leader>e`, `<leader><space>`, `<leader>fg`, `gd`/`K`, `y`/`p`,
   `<C-h>`/`<C-l>`, `<leader>gg`. Na każdą wątpliwość - spacja i czekaj na which-key.
2. **Tydzień 2:** text objects (`ci"`, `daa`, `vif`), `s` (flash), `gcc`, `]d` + `<leader>ca`,
   `<leader>xx`.
3. **Tydzień 3:** Claude (`<leader>ac`, `<leader>as`, akceptowanie diffów), testy (`<leader>Tt`),
   debugger (`<F9>`, `<F5>`).
4. **Potem:** oil do masowych zmian, `<C-q>` + `:cdo`, makra (`qa` ... `q`, `@a`), surround.
