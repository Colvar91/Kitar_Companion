local _, addon = ...

-- Die Befehle stammen aus SH_Animations. Sie werden absichtlich unverändert
-- an den Chat übergeben, damit server- oder projektbezogene Slash-Befehle
-- weiterhin funktionieren.
addon.AnimationCategories = {
    {
        name = "Alltag",
        actions = {
            { "Winken", "/wave" }, { "Verbeugen", "/bow" },
            { "Salutieren", "/salute" }, { "Knien", "/kneel" },
            { "Sitzen", "/sit" }, { "Klatschen", "/clap" },
            { "Jubeln", "/cheer" }, { "Danken", "/thanks" },
            { "Zeigen", "/point" }, { "Brüllen", "/roar" },
            { "Umarmen", "/hug" }, { "Lachen", "/laugh" },
            { "Ja", "/yes" }, { "Nein", "/no" },
        },
    },
    {
        name = "Allgemein",
        actions = {
            { "Arbeiten", "/arbeiten" }, { "Hämmern", "/haemmern", disabledFlags = 9 },
            { "Werfenbereit", "/werfenbereit" }, { "Looten", "/looten" },
            { "Kampfschrei", "/kampfschrei" }, { "Werfen", "/werfen" },
            { "Benutzen / Craften", "/craften" }, { "Angeln", "/angeln" },
            { "Mund öffnen", "/mundoeffnen" }, { "Boden schrubben", "/bodenschrubben", disabledFlags = 10 },
        },
    },
    {
        name = "Haltung",
        actions = {
            { "Ersticken", "/ersticken" }, { "Ersticken kniend", "/erstickenkniend" },
            { "Verwundet gehen", "/vgehen" }, { "Verstohlen", "/verstohlen" },
            { "Schleichen", "/schleichen" }, { "Benommen", "/benommen" },
            { "Hände hoch 1", "/haendehoch1" }, { "Hände hoch 2", "/haendehoch2" },
            { "Hände hoch 3", "/haendehoch3" }, { "Preisen", "/preisen" },
            { "Sitzend schlafen", "/sitzendschlafen" }, { "Wache halten 1", "/wachehalten1", disabledFlags = 10 },
            { "Wache halten 2", "/wachehalten2", disabledFlags = 10 }, { "Wache halten 3", "/wachehalten3", disabledFlags = 10 },
            { "Gefesselte Hände", "/gefesseltehaende" }, { "Ruderstand 1", "/ruderstand1", disabledFlags = 11 },
            { "Ruderstand 2", "/ruderstand2", disabledFlags = 11 }, { "Waffe über Schulter", "/waffeueberdierechteschulter" },
            { "Fackel rechts", "/fackelhaltenrechts" }, { "Fackel links", "/fackelhaltenlinks", disabledFlags = 10 },
            { "Salutieren kniend", "/salutierendakniend" }, { "Salutieren locker", "/salutierendalocker" },
            { "Ängstlich", "/aengstlichda" }, { "Ängstlich stark", "/aengstlichdastark" },
            { "Ängstlich kniend", "/aengstlichdakniend" },
            { "Salutieren dauerhaft stramm", "/salutierendastramm", disabledFlags = 6 },
        },
    },
    {
        name = "Nahrungsmittel",
        actions = {
            { "Phiole trinken", "/phioletrinken" }, { "Krug trinken", "/krugtrinken" },
            { "Brot essen", "/brotessen" }, { "Keule essen", "/keulessen" },
            { "Kaugummiblase", "/kaugummiblase" },
        },
    },
    {
        name = "Kampf",
        actions = {
            { "Bogenschießen", "/bogenschiessen" }, { "Gewehrschießen", "/gewehrschiessen" },
            { "Einhändig", "/angriff1h" }, { "Einhändig Spezial", "/angriff1hspezial" },
            { "Einhändig Schmettern", "/angriff1hschmettern" }, { "Einhändig Stechen", "/angriff1hstechen" },
            { "Einhändig Hieb", "/angriff1hhieb" }, { "Zweihändig", "/angriff2h" },
            { "Zweihändig Spezial", "/angriff2hspezial" }, { "Zweihändig Stechen", "/angriff2hstechen" },
            { "Unbewaffnet", "/angriffunb" }, { "Nebenhand", "/angriffnebenhand" },
            { "Nebenhand unbewaffnet", "/angriffnebenhandunb" }, { "Parieren einhändig", "/parieren1h" },
            { "Parieren unbewaffnet", "/parierenunb" }, { "Getroffen", "/getroffen" },
            { "Getroffen kritisch", "/getroffenkrit" }, { "Knockdown", "/knockdown" },
            { "Blocken", "/blocken" }, { "Schildschlag", "/schildschlag" },
            { "Rundumschlag", "/rundumschlag" }, { "Ausweichen", "/ausweichen" },
            { "Tritt", "/tritt" }, { "Totstellen", "/totstellen" },
        },
    },
    {
        name = "Kampfhaltungen",
        actions = {
            { "Gewehr bereit", "/gewehrbereit" }, { "Gewehr zielen", "/gewehrzielen" },
            { "Bogen bereit", "/bogenbereit" }, { "Bogen zielen", "/bogenzielen" },
            { "Schwert Einhand", "/schwert1h" }, { "Schwert Zweihand 1", "/schwert2h1" },
            { "Schwert Zweihand 2", "/schwert2h2" }, { "Unbewaffnet", "/unbewaffnet" },
        },
    },
    {
        name = "Gegenstände",
        actions = {
            { "Fass tragen 2", "/objektfasstragen2" }, { "Kiste tragen 1", "/objektkistetragen1" },
            { "Kiste tragen 2", "/objektkistetragen2" }, { "Bild tragen", "/objektbildtragen", disabledFlags = 11 },
            { "Riesen-Ei tragen", "/objektrieseneitragen" }, { "In Buch schreiben", "/objektbuchschreiben" },
            { "Bauplan lesen", "/objektbauplanlesen" }, { "Buch lesen", "/objektbuchlesen" },
            { "Magisches Buch lesen", "/objektmagiebuchlesen" }, { "Eimer tragen 1", "/objekteineimertragen1" },
            { "Eimer tragen 2", "/objekteineimertragen2", disabledFlags = 11 }, { "Zwei Wassereimer", "/objektzweiwassereimertragen" },
            { "Korb tragen", "/objekteinkorbtragen" }, { "Zwei Körbe", "/objektzweikoerbetragen" },
            { "Helm auf dem Kopf", "/objekthelmaufdemkopf" }, { "Sack tragen", "/objektsacktragen" },
            { "Harfe spielen 1", "/objektharfespielen1" }, { "Harfe spielen 2", "/objektharfespielen2" },
            { "Flöte spielen", "/objektfloetespielen", disabledFlags = 5 },
            { "Servierer 1", "/objektservierer1", disabledFlags = 11 },
            { "Servierer 2", "/objektservierer2", disabledFlags = 11 },
            { "Servierer 3", "/objektservierer3", disabledFlags = 11 },
        },
    },
    {
        name = "Kanalisieren ohne Magie",
        actions = {
            { "Nach vorne 1", "/kanalvorne1" }, { "Nach vorne 2", "/kanalvorne2" },
            { "Nach vorne 3", "/kanalvorne3" }, { "Nach oben 1", "/kanaloben1" },
            { "Nach oben 2", "/kanaloben2" }, { "Zauberbereit 1", "/zauberbereit1" },
            { "Zauberbereit 2", "/zauberbereit2" }, { "Zauberbereit 3", "/zauberbereit3" },
            { "Zauberbereit 4", "/zauberbereit4" }, { "Zauberbereit 5", "/zauberbereit5" },
        },
    },
    {
        name = "Feuermagie",
        actions = {
            { "Feuerball", "/feuerball" }, { "Pyroschlag", "/pyroschlag" },
            { "Feuerschlag", "/feuerschlag" }, { "Kanalisieren", "/feuerkanalisieren" },
        },
    },
    {
        name = "Arkanmagie",
        actions = {
            { "Arkane Geschosse", "/arkgeschosse" }, { "Arkanbeschuss", "/arkbeschuss" },
            { "Hervorrufung", "/arkhervorrufung" }, { "Arkanschlag", "/arkschlag" },
            { "Bücher levitieren", "/arkbuecherlevitieren" }, { "Kanalisieren", "/arkkanalisieren" },
        },
    },
    {
        name = "Frostmagie",
        actions = {
            { "Eislanze", "/eislanze" }, { "Frostblitz", "/frostblitz" },
            { "Eisblock", "/eisblock" }, { "Kanalisieren", "/eiskanalisieren" },
        },
    },
    {
        name = "Lichtmagie",
        actions = {
            { "Erneuerung", "/heiligerneuerung" }, { "Heiliges Feuer", "/heiligesfeuer" },
            { "Läutern", "/heiliglaeutern" }, { "Richturteil", "/heiligrichturteil" },
            { "Kanalisieren", "/heiligkanalisieren" },
        },
    },
    {
        name = "Schattenmagie",
        actions = {
            { "Schattenblitz", "/schattenblitz" }, { "Dämonenblitz", "/daemonenblitz" },
            { "Gedankenschinden", "/gedankenschinden" }, { "Kanalisieren", "/schattenkanalisieren" },
        },
    },
    {
        name = "Naturmagie",
        actions = {
            { "Verjüngung", "/naturveruengung" }, { "Nachwachsen", "/naturnachwachsen" },
            { "Wiederbelebung", "/naturwiederbelebung" }, { "Wucherwurzeln", "/naturwucherwurzeln" },
            { "Kanalisieren", "/naturkanalisieren" },
        },
    },
    {
        name = "Elementarmagie",
        actions = {
            { "Blitzschlag", "/elementarblitzschlag" }, { "Erdschock", "/elementarerdschock" },
            { "Heilender Regen", "/elementarregen" }, { "Lavaeruption", "/elementarlavaeruption" },
            { "Kanalisieren", "/elementarkanalisieren" },
        },
    },
}
