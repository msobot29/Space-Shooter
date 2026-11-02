# Windows playtest - GitHub Actions

Workflow: `.github/workflows/windows-build.yml`, samo `workflow_dispatch`.
Godot verzija: **4.7.2 stable**, Windows x86_64 release sa ugrađenim PCK-om.

## Pokretanje i preuzimanje

1. Nakon pregleda i odobrenja, uraditi push pripremljenog commita na `main`.
   GitHub Actions koristi isključivo commit sa GitHub-a, ne lokalne izmene.
2. Otvoriti https://github.com/msobot29/Space-Shooter/actions/workflows/windows-build.yml
3. Kliknuti **Run workflow**, izabrati **main**, pa **Run workflow**.
4. Otvoriti nov run i proveriti SHA commita. Sačekati zeleni **Success**.
5. U odeljku **Artifacts** preuzeti **AdriaticUprising_Playtest_Win64**.
6. Raspakovati GitHub artifact arhivu. Unutra je
   `AdriaticUprising_Playtest_Win64.zip`; to je paket za playtestera.
7. Raspakovati taj ZIP i pokrenuti `AdriaticUprising_Playtest.exe`.
   Pročitati `README.txt`; eventualni `.pck` mora ostati pored EXE-a.

Artefakt se čuva 30 dana. GitHub nalog sa pristupom repozitorijumu je potreban
za preuzimanje. Na Summary stranici su SHA commita, veličina i SHA256 ZIP-a.
Ne slati neuspešan ili nepotpun build playtesteru.

## Šta pipeline radi

- Preuzima zvanični Godot editor 4.7.2 i export templates iste verzije;
  instalira oba Windows x86_64 šablona. Greška preuzimanja prekida build.
- Priprema izdvojenu kopiju `main.gd`, njegovog UID-a, `main.tscn`, podešavanja
  projekta i export preseta. Gameplay kod se kopira bez izmena.
- Samo u kopiji uklanja Godot AI autoload i editor plugin. Ne kopira addons,
  kredencijale, `.git`, lokalne QA foldere, `main2.gd` niti razvojne alate.
- Proverava 50-level konstante i pokreće Ship Status, Upgrade Toggle,
  Weapon System, Destruction i Reactive Armor regresione testove.
- Izvozi release, pa pokreće kopirani EXE headless iz privremenog foldera
  izvan checkout-a. Ovo proverava startup bez izvornog projekta.
- Pakuje samo x86_64 EXE, README i eventualni odvojeni PCK; proverava PE
  arhitekturu, spisak i integritet ZIP-a. Upload dolazi tek posle svih provera.

`tools/build_playtest.py` koristi Python 3.12 standardnu biblioteku. Nove
resurse igre treba eksplicitno dodati u allowlist; promena zavisnosti prekida
pripremu dok se lista ne pregleda. Pokušaj ponovne pripreme u istom staging
folderu prekida se umesto mešanja sa starim fajlovima; GitHub run ima svež checkout.

## Ograničenja

Uspešan workflow potvrđuje export, regresione testove i headless startup.
Ne potvrđuje interaktivne menije, prikaz na GPU-u, zvuk, fizičke tastere,
diskovni save/load round-trip niti svih 50 nivoa odigranih do kraja.
Playtester treba posebno da proveri pucanje, TAB, bossove, prelazak Hrvatska /
Bosna i Continue. Postojeće debug prečice nisu uklanjane iz gameplay koda.

Lokalni editor ne zahteva instalirane export šablone za ovaj udaljeni build.
Build još nije potvrđen dok konkretan GitHub Actions run ne završi uspešno.
