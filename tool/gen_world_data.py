"""One-shot generator for language, currency, and country catalogs."""
from pathlib import Path

# ISO 639-1 living languages with native names.
LANGS = [
    ("aa", "Afar", "Qafar"), ("ab", "Abkhazian", "Аҧсуа"), ("ae", "Avestan", "Avestan"),
    ("af", "Afrikaans", "Afrikaans"), ("ak", "Akan", "Akan"), ("am", "Amharic", "አማርኛ"),
    ("an", "Aragonese", "Aragonés"), ("ar", "Arabic", "العربية"), ("as", "Assamese", "অসমীয়া"),
    ("av", "Avaric", "Авар"), ("ay", "Aymara", "Aymar"), ("az", "Azerbaijani", "Azərbaycan"),
    ("ba", "Bashkir", "Башҡорт"), ("be", "Belarusian", "Беларуская"), ("bg", "Bulgarian", "Български"),
    ("bh", "Bihari", "भोजपुरी"), ("bi", "Bislama", "Bislama"), ("bm", "Bambara", "Bamanankan"),
    ("bn", "Bengali", "বাংলা"), ("bo", "Tibetan", "བོད་སྐད་"), ("br", "Breton", "Brezhoneg"),
    ("bs", "Bosnian", "Bosanski"), ("ca", "Catalan", "Català"), ("ce", "Chechen", "Нохчийн"),
    ("ch", "Chamorro", "Chamoru"), ("co", "Corsican", "Corsu"), ("cr", "Cree", "ᓀᐦᐃᔭᐍᐏᐣ"),
    ("cs", "Czech", "Čeština"), ("cu", "Church Slavic", "Словѣньскъ"), ("cv", "Chuvash", "Чӑвашла"),
    ("cy", "Welsh", "Cymraeg"), ("da", "Danish", "Dansk"), ("de", "German", "Deutsch"),
    ("dv", "Divehi", "Divehi"), ("dz", "Dzongkha", "Dzongkha"), ("ee", "Ewe", "Eʋegbe"),
    ("el", "Greek", "Ελληνικά"), ("en", "English", "English"), ("eo", "Esperanto", "Esperanto"),
    ("es", "Spanish", "Español"), ("et", "Estonian", "Eesti"), ("eu", "Basque", "Euskara"),
    ("fa", "Persian", "فارسی"), ("ff", "Fulah", "Fulfulde"), ("fi", "Finnish", "Suomi"),
    ("fj", "Fijian", "Vosa Vakaviti"), ("fo", "Faroese", "Føroyskt"), ("fr", "French", "Français"),
    ("fy", "Western Frisian", "Frysk"), ("ga", "Irish", "Gaeilge"), ("gd", "Scottish Gaelic", "Gàidhlig"),
    ("gl", "Galician", "Galego"), ("gn", "Guarani", "Avañe'ẽ"), ("gu", "Gujarati", "ગુજરાતી"),
    ("gv", "Manx", "Gaelg"), ("ha", "Hausa", "Hausa"), ("he", "Hebrew", "עברית"),
    ("hi", "Hindi", "हिन्दी"), ("ho", "Hiri Motu", "Hiri Motu"), ("hr", "Croatian", "Hrvatski"),
    ("ht", "Haitian Creole", "Kreyòl ayisyen"), ("hu", "Hungarian", "Magyar"), ("hy", "Armenian", "Հայերեն"),
    ("hz", "Herero", "Otjiherero"), ("ia", "Interlingua", "Interlingua"), ("id", "Indonesian", "Bahasa Indonesia"),
    ("ie", "Interlingue", "Interlingue"), ("ig", "Igbo", "Igbo"), ("ii", "Sichuan Yi", "ꆈꌠꉙ"),
    ("ik", "Inupiaq", "Iñupiaq"), ("io", "Ido", "Ido"), ("is", "Icelandic", "Íslenska"),
    ("it", "Italian", "Italiano"), ("iu", "Inuktitut", "Inuktitut"), ("ja", "Japanese", "日本語"),
    ("jv", "Javanese", "Basa Jawa"), ("ka", "Georgian", "ქართული"), ("kg", "Kongo", "Kikongo"),
    ("ki", "Kikuyu", "Gĩkũyũ"), ("kj", "Kuanyama", "Kuanyama"), ("kk", "Kazakh", "Қазақша"),
    ("kl", "Kalaallisut", "Kalaallisut"), ("km", "Khmer", "ខ្មែរ"), ("kn", "Kannada", "ಕನ್ನಡ"),
    ("ko", "Korean", "한국어"), ("kr", "Kanuri", "Kanuri"), ("ks", "Kashmiri", "كشميري"),
    ("ku", "Kurdish", "Kurdî"), ("kv", "Komi", "Коми"), ("kw", "Cornish", "Kernewek"),
    ("ky", "Kyrgyz", "Кыргызча"), ("la", "Latin", "Latina"), ("lb", "Luxembourgish", "Lëtzebuergesch"),
    ("lg", "Ganda", "Luganda"), ("li", "Limburgish", "Limburgs"), ("ln", "Lingala", "Lingála"),
    ("lo", "Lao", "ລາວ"), ("lt", "Lithuanian", "Lietuvių"), ("lu", "Luba-Katanga", "Tshiluba"),
    ("lv", "Latvian", "Latviešu"), ("mg", "Malagasy", "Malagasy"), ("mh", "Marshallese", "Kajin M̧ajeļ"),
    ("mi", "Māori", "Māori"), ("mk", "Macedonian", "Македонски"), ("ml", "Malayalam", "മലയാളം"),
    ("mn", "Mongolian", "Монгол"), ("mr", "Marathi", "मराठी"), ("ms", "Malay", "Bahasa Melayu"),
    ("mt", "Maltese", "Malti"), ("my", "Burmese", "မြန်မာ"), ("na", "Nauru", "Dorerin Naoero"),
    ("nb", "Norwegian Bokmål", "Norsk bokmål"), ("nd", "North Ndebele", "isiNdebele"),
    ("ne", "Nepali", "नेपाली"), ("ng", "Ndonga", "Owambo"), ("nl", "Dutch", "Nederlands"),
    ("nn", "Norwegian Nynorsk", "Norsk nynorsk"), ("no", "Norwegian", "Norsk"),
    ("nr", "South Ndebele", "isiNdebele"), ("nv", "Navajo", "Diné bizaad"),
    ("ny", "Chichewa", "Chichewa"), ("oc", "Occitan", "Occitan"), ("oj", "Ojibwa", "Ojibwe"),
    ("om", "Oromo", "Afaan Oromoo"), ("or", "Odia", "ଓଡ଼ିଆ"), ("os", "Ossetian", "Ирон"),
    ("pa", "Punjabi", "ਪੰਜਾਬੀ"), ("pi", "Pali", "पालि"), ("pl", "Polish", "Polski"),
    ("ps", "Pashto", "پښتو"), ("pt", "Portuguese", "Português"), ("qu", "Quechua", "Runa Simi"),
    ("rm", "Romansh", "Rumantsch"), ("rn", "Kirundi", "Ikirundi"), ("ro", "Romanian", "Română"),
    ("ru", "Russian", "Русский"), ("rw", "Kinyarwanda", "Ikinyarwanda"), ("sa", "Sanskrit", "संस्कृतम्"),
    ("sc", "Sardinian", "Sardu"), ("sd", "Sindhi", "سنڌي"), ("se", "Northern Sami", "Davvisámegiella"),
    ("sg", "Sango", "Sängö"), ("si", "Sinhala", "සිංහල"), ("sk", "Slovak", "Slovenčina"),
    ("sl", "Slovenian", "Slovenščina"), ("sm", "Samoan", "Gagana Samoa"), ("sn", "Shona", "chiShona"),
    ("so", "Somali", "Soomaali"), ("sq", "Albanian", "Shqip"), ("sr", "Serbian", "Српски"),
    ("ss", "Swati", "SiSwati"), ("st", "Southern Sotho", "Sesotho"), ("su", "Sundanese", "Basa Sunda"),
    ("sv", "Swedish", "Svenska"), ("sw", "Swahili", "Kiswahili"), ("ta", "Tamil", "தமிழ்"),
    ("te", "Telugu", "తెలుగు"), ("tg", "Tajik", "Тоҷикӣ"), ("th", "Thai", "ไทย"),
    ("ti", "Tigrinya", "ትግርኛ"), ("tk", "Turkmen", "Türkmen"), ("tl", "Filipino", "Filipino"),
    ("tn", "Tswana", "Setswana"), ("to", "Tongan", "Lea faka-Tonga"), ("tr", "Turkish", "Türkçe"),
    ("ts", "Tsonga", "Xitsonga"), ("tt", "Tatar", "Татар"), ("tw", "Twi", "Twi"),
    ("ty", "Tahitian", "Reo Tahiti"), ("ug", "Uyghur", "ئۇيغۇرچە"), ("uk", "Ukrainian", "Українська"),
    ("ur", "Urdu", "اردو"), ("uz", "Uzbek", "Oʻzbek"), ("ve", "Venda", "Tshivenḓa"),
    ("vi", "Vietnamese", "Tiếng Việt"), ("vo", "Volapük", "Volapük"), ("wa", "Walloon", "Walon"),
    ("wo", "Wolof", "Wolof"), ("xh", "Xhosa", "isiXhosa"), ("yi", "Yiddish", "ייִדיש"),
    ("yo", "Yoruba", "Yorùbá"), ("za", "Zhuang", "Vahcuengh"), ("zh", "Chinese", "中文"),
    ("zu", "Zulu", "isiZulu"),
]

# BCP-47 speech locales preferred for STT/TTS.
SPEECH = {
    "af": "af-ZA", "am": "am-ET", "ar": "ar-SA", "az": "az-AZ", "be": "be-BY",
    "bg": "bg-BG", "bn": "bn-IN", "bs": "bs-BA", "ca": "ca-ES", "cs": "cs-CZ",
    "cy": "cy-GB", "da": "da-DK", "de": "de-DE", "el": "el-GR", "en": "en-US",
    "es": "es-ES", "et": "et-EE", "eu": "eu-ES", "fa": "fa-IR", "fi": "fi-FI",
    "fil": "fil-PH", "tl": "fil-PH", "fr": "fr-FR", "ga": "ga-IE", "gl": "gl-ES",
    "gu": "gu-IN", "he": "he-IL", "hi": "hi-IN", "hr": "hr-HR", "hu": "hu-HU",
    "hy": "hy-AM", "id": "id-ID", "is": "is-IS", "it": "it-IT", "ja": "ja-JP",
    "jv": "jv-ID", "ka": "ka-GE", "kk": "kk-KZ", "km": "km-KH", "kn": "kn-IN",
    "ko": "ko-KR", "lo": "lo-LA", "lt": "lt-LT", "lv": "lv-LV", "mk": "mk-MK",
    "ml": "ml-IN", "mn": "mn-MN", "mr": "mr-IN", "ms": "ms-MY", "mt": "mt-MT",
    "my": "my-MM", "nb": "nb-NO", "ne": "ne-NP", "nl": "nl-NL", "nn": "nn-NO",
    "no": "nb-NO", "pa": "pa-IN", "pl": "pl-PL", "pt": "pt-BR", "ro": "ro-RO",
    "ru": "ru-RU", "si": "si-LK", "sk": "sk-SK", "sl": "sl-SI", "sq": "sq-AL",
    "sr": "sr-RS", "sv": "sv-SE", "sw": "sw-KE", "ta": "ta-IN", "te": "te-IN",
    "th": "th-TH", "tr": "tr-TR", "uk": "uk-UA", "ur": "ur-PK", "uz": "uz-UZ",
    "vi": "vi-VN", "zh": "zh-CN", "zu": "zu-ZA",
}

# ISO 4217: code, name, symbol, units per 1 PLN (approx mid-market).
CUR = [
    ("PLN", "Polish złoty", "zł", 1.0, "Europe"),
    ("EUR", "Euro", "€", 0.233, "Europe"),
    ("USD", "United States dollar", "$", 0.255, "Americas"),
    ("GBP", "Pound sterling", "£", 0.201, "Europe"),
    ("CHF", "Swiss franc", "CHF", 0.218, "Europe"),
    ("CZK", "Czech koruna", "Kč", 5.85, "Europe"),
    ("HUF", "Hungarian forint", "Ft", 93.2, "Europe"),
    ("RON", "Romanian leu", "lei", 1.16, "Europe"),
    ("BGN", "Bulgarian lev", "лв", 0.456, "Europe"),
    ("SEK", "Swedish krona", "kr", 2.62, "Europe"),
    ("NOK", "Norwegian krone", "kr", 2.71, "Europe"),
    ("DKK", "Danish krone", "kr", 1.74, "Europe"),
    ("ISK", "Icelandic króna", "kr", 35.1, "Europe"),
    ("UAH", "Ukrainian hryvnia", "₴", 10.5, "Europe"),
    ("RUB", "Russian ruble", "₽", 23.4, "Europe"),
    ("TRY", "Turkish lira", "₺", 8.55, "Europe"),
    ("RSD", "Serbian dinar", "дин", 27.3, "Europe"),
    ("BAM", "Bosnia-Herzegovina convertible mark", "KM", 0.456, "Europe"),
    ("MKD", "Macedonian denar", "ден", 14.3, "Europe"),
    ("ALL", "Albanian lek", "L", 23.1, "Europe"),
    ("MDL", "Moldovan leu", "L", 4.45, "Europe"),
    ("GEL", "Georgian lari", "₾", 0.69, "Europe"),
    ("AMD", "Armenian dram", "֏", 99.0, "Asia"),
    ("AZN", "Azerbaijani manat", "₼", 0.433, "Asia"),
    ("BYN", "Belarusian ruble", "Br", 0.83, "Europe"),
    ("CAD", "Canadian dollar", "$", 0.352, "Americas"),
    ("MXN", "Mexican peso", "$", 4.85, "Americas"),
    ("BRL", "Brazilian real", "R$", 1.41, "Americas"),
    ("ARS", "Argentine peso", "$", 245.0, "Americas"),
    ("CLP", "Chilean peso", "$", 241.0, "Americas"),
    ("COP", "Colombian peso", "$", 1060.0, "Americas"),
    ("PEN", "Peruvian sol", "S/", 0.95, "Americas"),
    ("UYU", "Uruguayan peso", "$", 10.3, "Americas"),
    ("PYG", "Paraguayan guaraní", "₲", 1980.0, "Americas"),
    ("BOB", "Bolivian boliviano", "Bs", 1.76, "Americas"),
    ("VES", "Venezuelan bolívar", "Bs", 9.3, "Americas"),
    ("CRC", "Costa Rican colón", "₡", 131.0, "Americas"),
    ("GTQ", "Guatemalan quetzal", "Q", 1.97, "Americas"),
    ("HNL", "Honduran lempira", "L", 6.32, "Americas"),
    ("NIO", "Nicaraguan córdoba", "C$", 9.37, "Americas"),
    ("PAB", "Panamanian balboa", "B/.", 0.255, "Americas"),
    ("DOP", "Dominican peso", "$", 15.3, "Americas"),
    ("JMD", "Jamaican dollar", "$", 39.8, "Americas"),
    ("TTD", "Trinidad and Tobago dollar", "$", 1.73, "Americas"),
    ("BBD", "Barbadian dollar", "$", 0.51, "Americas"),
    ("BSD", "Bahamian dollar", "$", 0.255, "Americas"),
    ("BZD", "Belize dollar", "$", 0.51, "Americas"),
    ("HTG", "Haitian gourde", "G", 33.5, "Americas"),
    ("CUP", "Cuban peso", "$", 6.12, "Americas"),
    ("GYD", "Guyanese dollar", "$", 53.4, "Americas"),
    ("SRD", "Surinamese dollar", "$", 8.9, "Americas"),
    ("AWG", "Aruban florin", "ƒ", 0.46, "Americas"),
    ("ANG", "Netherlands Antillean guilder", "ƒ", 0.46, "Americas"),
    ("XCD", "East Caribbean dollar", "$", 0.69, "Americas"),
    ("KYD", "Cayman Islands dollar", "$", 0.21, "Americas"),
    ("BMD", "Bermudian dollar", "$", 0.255, "Americas"),
    ("AUD", "Australian dollar", "$", 0.388, "Oceania"),
    ("NZD", "New Zealand dollar", "$", 0.425, "Oceania"),
    ("FJD", "Fijian dollar", "$", 0.57, "Oceania"),
    ("PGK", "Papua New Guinean kina", "K", 1.01, "Oceania"),
    ("WST", "Samoan tālā", "T", 0.70, "Oceania"),
    ("TOP", "Tongan paʻanga", "T$", 0.61, "Oceania"),
    ("SBD", "Solomon Islands dollar", "$", 2.14, "Oceania"),
    ("VUV", "Vanuatu vatu", "VT", 30.4, "Oceania"),
    ("JPY", "Japanese yen", "¥", 38.2, "Asia"),
    ("CNY", "Chinese yuan", "¥", 1.84, "Asia"),
    ("HKD", "Hong Kong dollar", "$", 1.99, "Asia"),
    ("TWD", "New Taiwan dollar", "NT$", 8.15, "Asia"),
    ("KRW", "South Korean won", "₩", 348.0, "Asia"),
    ("INR", "Indian rupee", "₹", 21.4, "Asia"),
    ("PKR", "Pakistani rupee", "₨", 71.2, "Asia"),
    ("BDT", "Bangladeshi taka", "৳", 30.6, "Asia"),
    ("LKR", "Sri Lankan rupee", "Rs", 76.4, "Asia"),
    ("NPR", "Nepalese rupee", "Rs", 34.2, "Asia"),
    ("MVR", "Maldivian rufiyaa", "Rf", 3.93, "Asia"),
    ("IDR", "Indonesian rupiah", "Rp", 4010.0, "Asia"),
    ("MYR", "Malaysian ringgit", "RM", 1.13, "Asia"),
    ("SGD", "Singapore dollar", "$", 0.338, "Asia"),
    ("THB", "Thai baht", "฿", 8.72, "Asia"),
    ("VND", "Vietnamese đồng", "₫", 6450.0, "Asia"),
    ("PHP", "Philippine peso", "₱", 14.6, "Asia"),
    ("KHR", "Cambodian riel", "៛", 1030.0, "Asia"),
    ("LAK", "Lao kip", "₭", 5530.0, "Asia"),
    ("MMK", "Myanmar kyat", "K", 535.0, "Asia"),
    ("BND", "Brunei dollar", "$", 0.338, "Asia"),
    ("MOP", "Macanese pataca", "MOP$", 2.05, "Asia"),
    ("KZT", "Kazakhstani tenge", "₸", 122.0, "Asia"),
    ("UZS", "Uzbekistani soʻm", "soʻm", 3230.0, "Asia"),
    ("KGS", "Kyrgyzstani som", "с", 22.1, "Asia"),
    ("TJS", "Tajikistani somoni", "ЅМ", 2.78, "Asia"),
    ("TMT", "Turkmenistani manat", "m", 0.89, "Asia"),
    ("MNT", "Mongolian tögrög", "₮", 865.0, "Asia"),
    ("AFN", "Afghan afghani", "؋", 18.1, "Asia"),
    ("IRR", "Iranian rial", "﷼", 10700.0, "Asia"),
    ("IQD", "Iraqi dinar", "ع.د", 334.0, "Asia"),
    ("ILS", "Israeli new shekel", "₪", 0.94, "Asia"),
    ("JOD", "Jordanian dinar", "د.ا", 0.181, "Asia"),
    ("LBP", "Lebanese pound", "ل.ل", 22800.0, "Asia"),
    ("SYP", "Syrian pound", "£", 3300.0, "Asia"),
    ("SAR", "Saudi riyal", "﷼", 0.956, "Asia"),
    ("AED", "UAE dirham", "د.إ", 0.937, "Asia"),
    ("QAR", "Qatari riyal", "﷼", 0.928, "Asia"),
    ("KWD", "Kuwaiti dinar", "د.ك", 0.078, "Asia"),
    ("BHD", "Bahraini dinar", ".د.ب", 0.096, "Asia"),
    ("OMR", "Omani rial", "ر.ع.", 0.098, "Asia"),
    ("YER", "Yemeni rial", "﷼", 63.8, "Asia"),
    ("EGP", "Egyptian pound", "E£", 12.4, "Africa"),
    ("MAD", "Moroccan dirham", "د.م.", 2.48, "Africa"),
    ("TND", "Tunisian dinar", "د.ت", 0.79, "Africa"),
    ("DZD", "Algerian dinar", "د.ج", 34.1, "Africa"),
    ("LYD", "Libyan dinar", "ل.د", 1.23, "Africa"),
    ("SDG", "Sudanese pound", "ج.س.", 153.0, "Africa"),
    ("SSP", "South Sudanese pound", "£", 410.0, "Africa"),
    ("ETB", "Ethiopian birr", "Br", 30.8, "Africa"),
    ("ERN", "Eritrean nakfa", "Nfk", 3.82, "Africa"),
    ("SOS", "Somali shilling", "Sh", 146.0, "Africa"),
    ("DJF", "Djiboutian franc", "Fdj", 45.3, "Africa"),
    ("KES", "Kenyan shilling", "KSh", 33.1, "Africa"),
    ("UGX", "Ugandan shilling", "USh", 940.0, "Africa"),
    ("TZS", "Tanzanian shilling", "TSh", 680.0, "Africa"),
    ("RWF", "Rwandan franc", "FRw", 345.0, "Africa"),
    ("BIF", "Burundian franc", "FBu", 745.0, "Africa"),
    ("MGA", "Malagasy ariary", "Ar", 1160.0, "Africa"),
    ("MUR", "Mauritian rupee", "₨", 11.7, "Africa"),
    ("SCR", "Seychellois rupee", "₨", 3.55, "Africa"),
    ("KMF", "Comorian franc", "CF", 114.0, "Africa"),
    ("ZAR", "South African rand", "R", 4.62, "Africa"),
    ("NAD", "Namibian dollar", "$", 4.62, "Africa"),
    ("BWP", "Botswana pula", "P", 3.45, "Africa"),
    ("LSL", "Lesotho loti", "L", 4.62, "Africa"),
    ("SZL", "Swazi lilangeni", "E", 4.62, "Africa"),
    ("ZMW", "Zambian kwacha", "ZK", 6.85, "Africa"),
    ("ZWL", "Zimbabwean dollar", "$", 6.8, "Africa"),
    ("MWK", "Malawian kwacha", "MK", 443.0, "Africa"),
    ("MZN", "Mozambican metical", "MT", 16.3, "Africa"),
    ("AOA", "Angolan kwanza", "Kz", 232.0, "Africa"),
    ("NGN", "Nigerian naira", "₦", 400.0, "Africa"),
    ("GHS", "Ghanaian cedi", "₵", 4.05, "Africa"),
    ("XOF", "West African CFA franc", "CFA", 153.0, "Africa"),
    ("XAF", "Central African CFA franc", "FCFA", 153.0, "Africa"),
    ("XPF", "CFP franc", "₣", 27.8, "Oceania"),
    ("CDF", "Congolese franc", "FC", 730.0, "Africa"),
    ("GMD", "Gambian dalasi", "D", 17.9, "Africa"),
    ("GNF", "Guinean franc", "FG", 2200.0, "Africa"),
    ("LRD", "Liberian dollar", "$", 49.2, "Africa"),
    ("SLL", "Sierra Leonean leone", "Le", 5.8, "Africa"),
    ("SLE", "Sierra Leonean leone", "Le", 5.8, "Africa"),
    ("CVE", "Cape Verdean escudo", "$", 25.7, "Africa"),
    ("STN", "São Tomé and Príncipe dobra", "Db", 5.72, "Africa"),
    ("MRU", "Mauritanian ouguiya", "UM", 10.1, "Africa"),
  ]

# Country: iso2, name, continent, default language, currency
COUNTRIES = [
    ("AF", "Afghanistan", "Asia", "ps", "AFN"), ("AL", "Albania", "Europe", "sq", "ALL"),
    ("DZ", "Algeria", "Africa", "ar", "DZD"), ("AD", "Andorra", "Europe", "ca", "EUR"),
    ("AO", "Angola", "Africa", "pt", "AOA"), ("AG", "Antigua and Barbuda", "Americas", "en", "XCD"),
    ("AR", "Argentina", "Americas", "es", "ARS"), ("AM", "Armenia", "Asia", "hy", "AMD"),
    ("AU", "Australia", "Oceania", "en", "AUD"), ("AT", "Austria", "Europe", "de", "EUR"),
    ("AZ", "Azerbaijan", "Asia", "az", "AZN"), ("BS", "Bahamas", "Americas", "en", "BSD"),
    ("BH", "Bahrain", "Asia", "ar", "BHD"), ("BD", "Bangladesh", "Asia", "bn", "BDT"),
    ("BB", "Barbados", "Americas", "en", "BBD"), ("BY", "Belarus", "Europe", "be", "BYN"),
    ("BE", "Belgium", "Europe", "nl", "EUR"), ("BZ", "Belize", "Americas", "en", "BZD"),
    ("BJ", "Benin", "Africa", "fr", "XOF"), ("BT", "Bhutan", "Asia", "dz", "INR"),
    ("BO", "Bolivia", "Americas", "es", "BOB"), ("BA", "Bosnia and Herzegovina", "Europe", "bs", "BAM"),
    ("BW", "Botswana", "Africa", "en", "BWP"), ("BR", "Brazil", "Americas", "pt", "BRL"),
    ("BN", "Brunei", "Asia", "ms", "BND"), ("BG", "Bulgaria", "Europe", "bg", "BGN"),
    ("BF", "Burkina Faso", "Africa", "fr", "XOF"), ("BI", "Burundi", "Africa", "fr", "BIF"),
    ("CV", "Cabo Verde", "Africa", "pt", "CVE"), ("KH", "Cambodia", "Asia", "km", "KHR"),
    ("CM", "Cameroon", "Africa", "fr", "XAF"), ("CA", "Canada", "Americas", "en", "CAD"),
    ("CF", "Central African Republic", "Africa", "fr", "XAF"), ("TD", "Chad", "Africa", "fr", "XAF"),
    ("CL", "Chile", "Americas", "es", "CLP"), ("CN", "China", "Asia", "zh", "CNY"),
    ("CO", "Colombia", "Americas", "es", "COP"), ("KM", "Comoros", "Africa", "ar", "KMF"),
    ("CG", "Congo", "Africa", "fr", "XAF"), ("CD", "DR Congo", "Africa", "fr", "CDF"),
    ("CR", "Costa Rica", "Americas", "es", "CRC"), ("CI", "Côte d’Ivoire", "Africa", "fr", "XOF"),
    ("HR", "Croatia", "Europe", "hr", "EUR"), ("CU", "Cuba", "Americas", "es", "CUP"),
    ("CY", "Cyprus", "Europe", "el", "EUR"), ("CZ", "Czechia", "Europe", "cs", "CZK"),
    ("DK", "Denmark", "Europe", "da", "DKK"), ("DJ", "Djibouti", "Africa", "fr", "DJF"),
    ("DM", "Dominica", "Americas", "en", "XCD"), ("DO", "Dominican Republic", "Americas", "es", "DOP"),
    ("EC", "Ecuador", "Americas", "es", "USD"), ("EG", "Egypt", "Africa", "ar", "EGP"),
    ("SV", "El Salvador", "Americas", "es", "USD"), ("GQ", "Equatorial Guinea", "Africa", "es", "XAF"),
    ("ER", "Eritrea", "Africa", "ti", "ERN"), ("EE", "Estonia", "Europe", "et", "EUR"),
    ("SZ", "Eswatini", "Africa", "en", "SZL"), ("ET", "Ethiopia", "Africa", "am", "ETB"),
    ("FJ", "Fiji", "Oceania", "en", "FJD"), ("FI", "Finland", "Europe", "fi", "EUR"),
    ("FR", "France", "Europe", "fr", "EUR"), ("GA", "Gabon", "Africa", "fr", "XAF"),
    ("GM", "Gambia", "Africa", "en", "GMD"), ("GE", "Georgia", "Asia", "ka", "GEL"),
    ("DE", "Germany", "Europe", "de", "EUR"), ("GH", "Ghana", "Africa", "en", "GHS"),
    ("GR", "Greece", "Europe", "el", "EUR"), ("GD", "Grenada", "Americas", "en", "XCD"),
    ("GT", "Guatemala", "Americas", "es", "GTQ"), ("GN", "Guinea", "Africa", "fr", "GNF"),
    ("GW", "Guinea-Bissau", "Africa", "pt", "XOF"), ("GY", "Guyana", "Americas", "en", "GYD"),
    ("HT", "Haiti", "Americas", "ht", "HTG"), ("HN", "Honduras", "Americas", "es", "HNL"),
    ("HK", "Hong Kong", "Asia", "zh", "HKD"), ("HU", "Hungary", "Europe", "hu", "HUF"),
    ("IS", "Iceland", "Europe", "is", "ISK"), ("IN", "India", "Asia", "hi", "INR"),
    ("ID", "Indonesia", "Asia", "id", "IDR"), ("IR", "Iran", "Asia", "fa", "IRR"),
    ("IQ", "Iraq", "Asia", "ar", "IQD"), ("IE", "Ireland", "Europe", "en", "EUR"),
    ("IL", "Israel", "Asia", "he", "ILS"), ("IT", "Italy", "Europe", "it", "EUR"),
    ("JM", "Jamaica", "Americas", "en", "JMD"), ("JP", "Japan", "Asia", "ja", "JPY"),
    ("JO", "Jordan", "Asia", "ar", "JOD"), ("KZ", "Kazakhstan", "Asia", "kk", "KZT"),
    ("KE", "Kenya", "Africa", "sw", "KES"), ("KI", "Kiribati", "Oceania", "en", "AUD"),
    ("KP", "North Korea", "Asia", "ko", "KRW"), ("KR", "South Korea", "Asia", "ko", "KRW"),
    ("KW", "Kuwait", "Asia", "ar", "KWD"), ("KG", "Kyrgyzstan", "Asia", "ky", "KGS"),
    ("LA", "Laos", "Asia", "lo", "LAK"), ("LV", "Latvia", "Europe", "lv", "EUR"),
    ("LB", "Lebanon", "Asia", "ar", "LBP"), ("LS", "Lesotho", "Africa", "en", "LSL"),
    ("LR", "Liberia", "Africa", "en", "LRD"), ("LY", "Libya", "Africa", "ar", "LYD"),
    ("LI", "Liechtenstein", "Europe", "de", "CHF"), ("LT", "Lithuania", "Europe", "lt", "EUR"),
    ("LU", "Luxembourg", "Europe", "fr", "EUR"), ("MO", "Macao", "Asia", "zh", "MOP"),
    ("MG", "Madagascar", "Africa", "mg", "MGA"), ("MW", "Malawi", "Africa", "en", "MWK"),
    ("MY", "Malaysia", "Asia", "ms", "MYR"), ("MV", "Maldives", "Asia", "dv", "MVR"),
    ("ML", "Mali", "Africa", "fr", "XOF"), ("MT", "Malta", "Europe", "mt", "EUR"),
    ("MH", "Marshall Islands", "Oceania", "en", "USD"), ("MR", "Mauritania", "Africa", "ar", "MRU"),
    ("MU", "Mauritius", "Africa", "en", "MUR"), ("MX", "Mexico", "Americas", "es", "MXN"),
    ("FM", "Micronesia", "Oceania", "en", "USD"), ("MD", "Moldova", "Europe", "ro", "MDL"),
    ("MC", "Monaco", "Europe", "fr", "EUR"), ("MN", "Mongolia", "Asia", "mn", "MNT"),
    ("ME", "Montenegro", "Europe", "sr", "EUR"), ("MA", "Morocco", "Africa", "ar", "MAD"),
    ("MZ", "Mozambique", "Africa", "pt", "MZN"), ("MM", "Myanmar", "Asia", "my", "MMK"),
    ("NA", "Namibia", "Africa", "en", "NAD"), ("NR", "Nauru", "Oceania", "en", "AUD"),
    ("NP", "Nepal", "Asia", "ne", "NPR"), ("NL", "Netherlands", "Europe", "nl", "EUR"),
    ("NZ", "New Zealand", "Oceania", "en", "NZD"), ("NI", "Nicaragua", "Americas", "es", "NIO"),
    ("NE", "Niger", "Africa", "fr", "XOF"), ("NG", "Nigeria", "Africa", "en", "NGN"),
    ("MK", "North Macedonia", "Europe", "mk", "MKD"), ("NO", "Norway", "Europe", "no", "NOK"),
    ("OM", "Oman", "Asia", "ar", "OMR"), ("PK", "Pakistan", "Asia", "ur", "PKR"),
    ("PW", "Palau", "Oceania", "en", "USD"), ("PS", "Palestine", "Asia", "ar", "ILS"),
    ("PA", "Panama", "Americas", "es", "PAB"), ("PG", "Papua New Guinea", "Oceania", "en", "PGK"),
    ("PY", "Paraguay", "Americas", "es", "PYG"), ("PE", "Peru", "Americas", "es", "PEN"),
    ("PH", "Philippines", "Asia", "tl", "PHP"), ("PL", "Poland", "Europe", "pl", "PLN"),
    ("PT", "Portugal", "Europe", "pt", "EUR"), ("QA", "Qatar", "Asia", "ar", "QAR"),
    ("RO", "Romania", "Europe", "ro", "RON"), ("RU", "Russia", "Europe", "ru", "RUB"),
    ("RW", "Rwanda", "Africa", "rw", "RWF"), ("KN", "Saint Kitts and Nevis", "Americas", "en", "XCD"),
    ("LC", "Saint Lucia", "Americas", "en", "XCD"), ("VC", "Saint Vincent and the Grenadines", "Americas", "en", "XCD"),
    ("WS", "Samoa", "Oceania", "sm", "WST"), ("SM", "San Marino", "Europe", "it", "EUR"),
    ("ST", "São Tomé and Príncipe", "Africa", "pt", "STN"), ("SA", "Saudi Arabia", "Asia", "ar", "SAR"),
    ("SN", "Senegal", "Africa", "fr", "XOF"), ("RS", "Serbia", "Europe", "sr", "RSD"),
    ("SC", "Seychelles", "Africa", "en", "SCR"), ("SL", "Sierra Leone", "Africa", "en", "SLE"),
    ("SG", "Singapore", "Asia", "en", "SGD"), ("SK", "Slovakia", "Europe", "sk", "EUR"),
    ("SI", "Slovenia", "Europe", "sl", "EUR"), ("SB", "Solomon Islands", "Oceania", "en", "SBD"),
    ("SO", "Somalia", "Africa", "so", "SOS"), ("ZA", "South Africa", "Africa", "en", "ZAR"),
    ("SS", "South Sudan", "Africa", "en", "SSP"), ("ES", "Spain", "Europe", "es", "EUR"),
    ("LK", "Sri Lanka", "Asia", "si", "LKR"), ("SD", "Sudan", "Africa", "ar", "SDG"),
    ("SR", "Suriname", "Americas", "nl", "SRD"), ("SE", "Sweden", "Europe", "sv", "SEK"),
    ("CH", "Switzerland", "Europe", "de", "CHF"), ("SY", "Syria", "Asia", "ar", "SYP"),
    ("TW", "Taiwan", "Asia", "zh", "TWD"), ("TJ", "Tajikistan", "Asia", "tg", "TJS"),
    ("TZ", "Tanzania", "Africa", "sw", "TZS"), ("TH", "Thailand", "Asia", "th", "THB"),
    ("TL", "Timor-Leste", "Asia", "pt", "USD"), ("TG", "Togo", "Africa", "fr", "XOF"),
    ("TO", "Tonga", "Oceania", "to", "TOP"), ("TT", "Trinidad and Tobago", "Americas", "en", "TTD"),
    ("TN", "Tunisia", "Africa", "ar", "TND"), ("TR", "Türkiye", "Europe", "tr", "TRY"),
    ("TM", "Turkmenistan", "Asia", "tk", "TMT"), ("TV", "Tuvalu", "Oceania", "en", "AUD"),
    ("UG", "Uganda", "Africa", "en", "UGX"), ("UA", "Ukraine", "Europe", "uk", "UAH"),
    ("AE", "United Arab Emirates", "Asia", "ar", "AED"), ("GB", "United Kingdom", "Europe", "en", "GBP"),
    ("US", "United States", "Americas", "en", "USD"), ("UY", "Uruguay", "Americas", "es", "UYU"),
    ("UZ", "Uzbekistan", "Asia", "uz", "UZS"), ("VU", "Vanuatu", "Oceania", "bi", "VUV"),
    ("VA", "Vatican City", "Europe", "it", "EUR"), ("VE", "Venezuela", "Americas", "es", "VES"),
    ("VN", "Vietnam", "Asia", "vi", "VND"), ("YE", "Yemen", "Asia", "ar", "YER"),
    ("ZM", "Zambia", "Africa", "en", "ZMW"), ("ZW", "Zimbabwe", "Africa", "en", "ZWL"),
]

ROOT = Path(r"c:\flutter_windows_3.29.3-stable\flutter\nfbot_app\lib\core\data")
ROOT.mkdir(parents=True, exist_ok=True)


def dart_str(s: str) -> str:
    return s.replace("\\", "\\\\").replace("$", r"\$").replace('"', '\\"')


seen = set()
langs = []
for code, en, native in LANGS:
    if code in seen:
        continue
    seen.add(code)
    speech = SPEECH.get(code, f"{code}-{code.upper()}")
    langs.append(
        f'  WorldLanguage(code: "{code}", englishName: "{dart_str(en)}", '
        f'nativeName: "{dart_str(native)}", speechLocale: "{speech}"),'
    )

curs = []
for code, name, symbol, per, region in CUR:
    curs.append(
        f'  WorldCurrency(code: "{code}", name: "{dart_str(name)}", '
        f'symbol: "{dart_str(symbol)}", perPln: {per}, region: "{region}"),'
    )

cos = []
for iso, name, continent, lang, cur in COUNTRIES:
    cos.append(
        f'  WorldCountry(iso2: "{iso}", name: "{dart_str(name)}", '
        f'continent: "{continent}", languageCode: "{lang}", currencyCode: "{cur}"),'
    )

(ROOT / "world_languages.dart").write_text(
    f'''/// ISO 639-1 living languages the coach can speak and listen in.
class WorldLanguage {{
  final String code;
  final String englishName;
  final String nativeName;
  final String speechLocale;

  const WorldLanguage({{
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.speechLocale,
  }});

  String get label => '$nativeName · $englishName';
}}

class WorldLanguages {{
  static const List<WorldLanguage> all = [
{chr(10).join(langs)}
  ];

  static WorldLanguage byCode(String code) {{
    final needle = code.toLowerCase().split(RegExp(r'[-_]')).first;
    return all.firstWhere(
      (l) => l.code == needle,
      orElse: () => all.firstWhere((l) => l.code == 'en'),
    );
  }}
}}
''',
    encoding="utf-8",
)

(ROOT / "world_currencies.dart").write_text(
    f'''/// ISO 4217 currencies with an approximate mid-market rate versus PLN.
///
/// [perPln] is how many units of this currency equal one Polish złoty.
/// Subscription prices are authored in PLN (15 / 22 / 29) and converted live.
class WorldCurrency {{
  final String code;
  final String name;
  final String symbol;
  final double perPln;
  final String region;

  const WorldCurrency({{
    required this.code,
    required this.name,
    required this.symbol,
    required this.perPln,
    required this.region,
  }});

  double fromPln(double amountPln) => amountPln * perPln;

  String format(double amountPln) {{
    final local = fromPln(amountPln);
    final digits = local >= 100 ? 0 : 2;
    return '$symbol${{local.toStringAsFixed(digits)}}';
  }}
}}

class WorldCurrencies {{
  static const List<WorldCurrency> all = [
{chr(10).join(curs)}
  ];

  static WorldCurrency byCode(String code) {{
    final needle = code.toUpperCase();
    return all.firstWhere(
      (c) => c.code == needle,
      orElse: () => all.firstWhere((c) => c.code == 'PLN'),
    );
  }}
}}
''',
    encoding="utf-8",
)

(ROOT / "world_countries.dart").write_text(
    f'''/// ISO 3166-1 countries used to pick language and billing currency.
class WorldCountry {{
  final String iso2;
  final String name;
  final String continent;
  final String languageCode;
  final String currencyCode;

  const WorldCountry({{
    required this.iso2,
    required this.name,
    required this.continent,
    required this.languageCode,
    required this.currencyCode,
  }});
}}

class WorldCountries {{
  static const List<WorldCountry> all = [
{chr(10).join(cos)}
  ];

  static WorldCountry byIso(String iso2) {{
    final needle = iso2.toUpperCase();
    return all.firstWhere(
      (c) => c.iso2 == needle,
      orElse: () => all.firstWhere((c) => c.iso2 == 'PL'),
    );
  }}
}}
''',
    encoding="utf-8",
)

print(f"languages={len(LANGS)} currencies={len(CUR)} countries={len(COUNTRIES)}")
