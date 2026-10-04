// The folder guide (see FolderGuide.swift): generated JSON, embedded as one raw string so it
// costs the compiler nothing and needs no resource bundle.
enum FolderGuideData {
    static let json = #"""
[
 {
  "match": [
   "~/Desktop"
  ],
  "title": {
   "en": "Desktop",
   "tr": "Masaüstü",
   "es": "Escritorio",
   "de": "Schreibtisch"
  },
  "what": {
   "en": "Your own files shown on the desktop, including screenshots by default; only you can decide what to remove.",
   "tr": "Masaüstünüzde görünen kendi dosyalarınız; ekran görüntüleri de varsayılan olarak buraya kaydedilir. Neyin silineceğine yalnızca siz karar verebilirsiniz.",
   "es": "Tus propios archivos del escritorio, incluidas por defecto las capturas de pantalla; solo tú puedes decidir qué borrar.",
   "de": "Deine eigenen Dateien auf dem Schreibtisch, standardmäßig auch Bildschirmfotos; nur du kannst entscheiden, was weg kann."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Documents"
  ],
  "title": {
   "en": "Documents",
   "tr": "Belgeler",
   "es": "Documentos",
   "de": "Dokumente"
  },
  "what": {
   "en": "Your documents and the default save location of many apps; it syncs with iCloud Drive if Desktop & Documents syncing is on.",
   "tr": "Belgeleriniz ve birçok uygulamanın varsayılan kayıt yeri; Masaüstü ve Belgeler eşzamanlaması açıksa iCloud Drive ile eşzamanlanır.",
   "es": "Tus documentos y el lugar donde muchas apps guardan por defecto; se sincroniza con iCloud Drive si tienes activado Escritorio y Documentos.",
   "de": "Deine Dokumente und Standard-Speicherort vieler Apps; wird mit iCloud Drive synchronisiert, wenn „Schreibtisch & Dokumente“ aktiv ist."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Downloads"
  ],
  "title": {
   "en": "Downloads",
   "tr": "İndirilenler",
   "es": "Descargas",
   "de": "Downloads"
  },
  "what": {
   "en": "Files you downloaded from browsers, Mail and other apps; it grows until you tidy it, and old installers and archives often pile up here.",
   "tr": "Tarayıcılardan, Mail'den ve diğer uygulamalardan indirdiğiniz dosyalar; siz düzenleyene kadar büyür, eski yükleyiciler ve arşivler genellikle burada birikir.",
   "es": "Archivos que descargaste desde navegadores, Mail y otras apps; crece hasta que lo ordenas y suele acumular instaladores y archivos comprimidos antiguos.",
   "de": "Dateien, die du aus Browsern, Mail und anderen Apps geladen hast; wächst, bis du aufräumst – oft sammeln sich alte Installer und Archive an."
  },
  "by": "macOS",
  "safety": "review"
 },
 {
  "match": [
   "~/Movies"
  ],
  "title": {
   "en": "Movies",
   "tr": "Filmler",
   "es": "Películas",
   "de": "Filme"
  },
  "what": {
   "en": "Your videos plus libraries from iMovie, Final Cut Pro and the TV app; it's large because video files are large.",
   "tr": "Videolarınız ile iMovie, Final Cut Pro ve TV uygulamasının arşivleri; video dosyaları büyük olduğu için çok yer kaplar.",
   "es": "Tus vídeos y las bibliotecas de iMovie, Final Cut Pro y la app TV; ocupa mucho porque los vídeos pesan mucho.",
   "de": "Deine Videos sowie Mediatheken von iMovie, Final Cut Pro und der TV-App; groß, weil Videodateien groß sind."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Music"
  ],
  "title": {
   "en": "Music",
   "tr": "Müzik",
   "es": "Música",
   "de": "Musik"
  },
  "what": {
   "en": "Your Music app library, GarageBand projects and other audio files.",
   "tr": "Müzik uygulamasındaki arşiviniz, GarageBand projeleriniz ve diğer ses dosyalarınız.",
   "es": "Tu biblioteca de la app Música, tus proyectos de GarageBand y otros archivos de audio.",
   "de": "Deine Mediathek der Musik-App, GarageBand-Projekte und andere Audiodateien."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Pictures"
  ],
  "title": {
   "en": "Pictures",
   "tr": "Resimler",
   "es": "Imágenes",
   "de": "Bilder"
  },
  "what": {
   "en": "Your photos and images, including the Photos library, which holds originals unless iCloud Photos optimizes storage.",
   "tr": "Fotoğraflarınız ve görselleriniz; iCloud Fotoğrafları depolamayı optimize etmiyorsa orijinalleri tutan Fotoğraflar arşivi de burada.",
   "es": "Tus fotos e imágenes, incluida la fototeca de Fotos, que guarda los originales salvo que Fotos en iCloud optimice el almacenamiento.",
   "de": "Deine Fotos und Bilder, inklusive der Fotos-Mediathek mit den Originalen, sofern iCloud-Fotos den Speicher nicht optimiert."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Public"
  ],
  "title": {
   "en": "Public",
   "tr": "Herkese Açık",
   "es": "Público",
   "de": "Öffentlich"
  },
  "what": {
   "en": "Files you share with other users of this Mac or over file sharing; its Drop Box folder receives files from others.",
   "tr": "Bu Mac'in diğer kullanıcılarıyla veya dosya paylaşımıyla paylaştığınız dosyalar; içindeki Drop Box klasörü başkalarından dosya alır.",
   "es": "Archivos que compartes con otros usuarios de este Mac o por red; su carpeta Buzón de entrega recibe archivos de otros.",
   "de": "Dateien, die du mit anderen Benutzern dieses Mac oder per Dateifreigabe teilst; der Briefkasten darin empfängt Dateien von anderen."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Applications"
  ],
  "title": {
   "en": "Your apps",
   "tr": "Uygulamalarınız",
   "es": "Tus apps",
   "de": "Deine Apps"
  },
  "what": {
   "en": "Apps installed just for your account, such as web apps saved from Safari or Chrome.",
   "tr": "Yalnızca hesabınız için yüklenmiş uygulamalar; örneğin Safari veya Chrome'dan kaydedilen web uygulamaları.",
   "es": "Apps instaladas solo para tu cuenta, como las apps web guardadas desde Safari o Chrome.",
   "de": "Nur für deinen Account installierte Apps, etwa aus Safari oder Chrome gesicherte Web-Apps."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library"
  ],
  "title": {
   "en": "Library",
   "tr": "Kitaplık",
   "es": "Biblioteca",
   "de": "Library"
  },
  "what": {
   "en": "Settings, caches and data of macOS and your apps; hidden by default because deleting things here can break apps.",
   "tr": "macOS'in ve uygulamalarınızın ayarları, önbellekleri ve verileri; buradaki öğeleri silmek uygulamaları bozabileceği için varsayılan olarak gizlidir.",
   "es": "Ajustes, cachés y datos de macOS y de tus apps; está oculta por defecto porque borrar cosas aquí puede estropear apps.",
   "de": "Einstellungen, Caches und Daten von macOS und deinen Apps; standardmäßig ausgeblendet, weil Löschen hier Apps beschädigen kann."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Caches"
  ],
  "title": {
   "en": "App caches",
   "tr": "Uygulama önbellekleri",
   "es": "Cachés de apps",
   "de": "App-Caches"
  },
  "what": {
   "en": "Temporary data apps keep to work faster; they rebuild it as needed, so deleting only costs some speed and downloads.",
   "tr": "Uygulamaların daha hızlı çalışmak için tuttuğu geçici veriler; gerektiğinde yeniden oluşturulur, silmek yalnızca biraz hız ve indirme maliyeti getirir.",
   "es": "Datos temporales que las apps guardan para ir más rápido; los regeneran cuando hace falta, así que borrarlos solo cuesta algo de velocidad y descargas.",
   "de": "Temporäre Daten, mit denen Apps schneller arbeiten; sie werden bei Bedarf neu erstellt, Löschen kostet nur etwas Tempo und Downloads."
  },
  "by": "macOS",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "~/Library/Containers/*/Data/Library/Caches"
  ],
  "title": {
   "en": "Sandboxed app cache",
   "tr": "Korumalı uygulama önbelleği",
   "es": "Caché de app aislada",
   "de": "Cache einer Sandbox-App"
  },
  "what": {
   "en": "The cache of an App Store or Apple app inside its container; the app rebuilds it, so deleting only costs speed and downloads.",
   "tr": "Bir App Store veya Apple uygulamasının kapsayıcısındaki önbellek; uygulama yeniden oluşturur, silmek yalnızca hız ve indirme maliyeti getirir.",
   "es": "La caché de una app de App Store o de Apple dentro de su contenedor; la app la regenera, así que borrarla solo cuesta velocidad y descargas.",
   "de": "Der Cache einer App-Store- oder Apple-App in ihrem Container; die App baut ihn neu auf, Löschen kostet nur Tempo und Downloads."
  },
  "by": "Sandboxed apps",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "~/Library/Logs"
  ],
  "title": {
   "en": "Logs",
   "tr": "Günlükler",
   "es": "Registros",
   "de": "Protokolle"
  },
  "what": {
   "en": "Diagnostic logs written by apps and macOS; they're only useful for troubleshooting, and new ones are written as needed.",
   "tr": "Uygulamaların ve macOS'in yazdığı tanılama günlükleri; yalnızca sorun gidermede işe yarar, gerektiğinde yenileri yazılır.",
   "es": "Registros de diagnóstico que escriben las apps y macOS; solo sirven para solucionar problemas y se crean nuevos cuando hace falta.",
   "de": "Diagnoseprotokolle von Apps und macOS; nur zur Fehlersuche nützlich, neue werden bei Bedarf geschrieben."
  },
  "by": "macOS",
  "safety": "safe",
  "category": "logs"
 },
 {
  "match": [
   "~/Library/Logs/DiagnosticReports",
   "/Library/Logs/DiagnosticReports"
  ],
  "title": {
   "en": "Crash reports",
   "tr": "Çökme raporları",
   "es": "Informes de fallos",
   "de": "Absturzberichte"
  },
  "what": {
   "en": "Reports saved when an app crashes or hangs; they pile up over time and are only useful for troubleshooting.",
   "tr": "Bir uygulama çöktüğünde veya donduğunda kaydedilen raporlar; zamanla birikir ve yalnızca sorun gidermede işe yarar.",
   "es": "Informes que se guardan cuando una app falla o se cuelga; se acumulan con el tiempo y solo sirven para diagnosticar problemas.",
   "de": "Berichte, die beim Absturz oder Hängen einer App entstehen; sie sammeln sich an und helfen nur bei der Fehlersuche."
  },
  "by": "macOS",
  "safety": "safe",
  "category": "logs"
 },
 {
  "match": [
   "/Library/Logs"
  ],
  "title": {
   "en": "System logs",
   "tr": "Sistem günlükleri",
   "es": "Registros del sistema",
   "de": "Systemprotokolle"
  },
  "what": {
   "en": "Logs from installers and system services for all users; only needed for troubleshooting.",
   "tr": "Tüm kullanıcılar için yükleyicilerin ve sistem hizmetlerinin günlükleri; yalnızca sorun gidermede gerekir.",
   "es": "Registros de instaladores y servicios del sistema para todos los usuarios; solo hacen falta para diagnosticar problemas.",
   "de": "Protokolle von Installern und Systemdiensten für alle Benutzer; nur zur Fehlersuche nötig."
  },
  "by": "macOS",
  "safety": "safe",
  "category": "logs"
 },
 {
  "match": [
   "~/Library/Application Support"
  ],
  "title": {
   "en": "App data",
   "tr": "Uygulama verileri",
   "es": "Datos de apps",
   "de": "App-Daten"
  },
  "what": {
   "en": "Where apps keep their data, settings and downloaded content; deleting an app's folder can erase its documents, so check per app.",
   "tr": "Uygulamaların verilerini, ayarlarını ve indirdiği içerikleri tuttuğu yer; bir uygulamanın klasörünü silmek belgelerini silebilir, uygulama bazında kontrol edin.",
   "es": "Donde las apps guardan sus datos, ajustes y contenido descargado; borrar la carpeta de una app puede eliminar sus documentos, revísalo app por app.",
   "de": "Hier speichern Apps Daten, Einstellungen und geladene Inhalte; den Ordner einer App zu löschen kann ihre Dokumente entfernen – prüfe jede App einzeln."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Containers"
  ],
  "title": {
   "en": "App containers",
   "tr": "Uygulama kapsayıcıları",
   "es": "Contenedores de apps",
   "de": "App-Container"
  },
  "what": {
   "en": "Sandboxed storage of App Store and Apple apps with their data, settings and caches; deleting one resets that app and can lose its data.",
   "tr": "App Store ve Apple uygulamalarının verilerini, ayarlarını ve önbelleklerini tutan korumalı alan; birini silmek o uygulamayı sıfırlar ve verilerini kaybettirebilir.",
   "es": "Almacenamiento aislado de las apps de App Store y de Apple con sus datos, ajustes y cachés; borrar uno restablece esa app y puede perder sus datos.",
   "de": "Abgeschotteter Speicher von App-Store- und Apple-Apps mit Daten, Einstellungen und Caches; einen zu löschen setzt die App zurück und kann Daten kosten."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Group Containers"
  ],
  "title": {
   "en": "Shared app containers",
   "tr": "Paylaşılan uygulama kapsayıcıları",
   "es": "Contenedores compartidos",
   "de": "Gemeinsame App-Container"
  },
  "what": {
   "en": "Data shared between related apps and their extensions, such as Microsoft Office or Apple Notes; deleting can lose that data.",
   "tr": "Microsoft Office veya Apple Notlar gibi ilişkili uygulamalar ve uzantıları arasında paylaşılan veriler; silmek bu verileri kaybettirebilir.",
   "es": "Datos compartidos entre apps relacionadas y sus extensiones, como Microsoft Office o Notas; borrarlos puede hacerte perder esos datos.",
   "de": "Daten, die verwandte Apps und ihre Erweiterungen teilen, etwa Microsoft Office oder Notizen; Löschen kann diese Daten kosten."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Saved Application State"
  ],
  "title": {
   "en": "Saved window state",
   "tr": "Kayıtlı pencere durumu",
   "es": "Estado guardado de ventanas",
   "de": "Gesicherter Fensterzustand"
  },
  "what": {
   "en": "Snapshots apps use to reopen their windows after a restart; deleting just means windows don't come back as they were.",
   "tr": "Uygulamaların yeniden başlatmadan sonra pencerelerini geri açmak için kullandığı anlık görüntüler; silerseniz pencereler yalnızca eski hâliyle açılmaz.",
   "es": "Instantáneas que usan las apps para reabrir sus ventanas tras reiniciar; si lo borras, las ventanas simplemente no vuelven como estaban.",
   "de": "Schnappschüsse, mit denen Apps nach einem Neustart ihre Fenster wiederherstellen; nach dem Löschen öffnen sich Fenster nur nicht wie zuvor."
  },
  "by": "macOS",
  "safety": "safe"
 },
 {
  "match": [
   "~/Library/Autosave Information"
  ],
  "title": {
   "en": "Autosaved documents",
   "tr": "Otomatik kaydedilen belgeler",
   "es": "Documentos autoguardados",
   "de": "Automatisch gesicherte Dokumente"
  },
  "what": {
   "en": "Unsaved documents and versions kept by apps like TextEdit and Pages; deleting can lose work you never saved.",
   "tr": "TextEdit ve Pages gibi uygulamaların tuttuğu kaydedilmemiş belgeler ve sürümler; silmek hiç kaydetmediğiniz çalışmaları kaybettirebilir.",
   "es": "Documentos sin guardar y versiones que conservan apps como TextEdit y Pages; borrarlos puede hacerte perder trabajo que nunca guardaste.",
   "de": "Ungesicherte Dokumente und Versionen von Apps wie TextEdit und Pages; Löschen kann Arbeit kosten, die du nie gesichert hast."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/HTTPStorages"
  ],
  "title": {
   "en": "HTTP storage",
   "tr": "HTTP depolaması",
   "es": "Almacenamiento HTTP",
   "de": "HTTP-Speicher"
  },
  "what": {
   "en": "Per-app cookies and web security settings from the apps' network requests; deleting may sign you out of some apps.",
   "tr": "Uygulamaların ağ isteklerinden gelen, uygulamaya özel çerezler ve web güvenlik ayarları; silmek bazı uygulamalarda oturumunuzu kapatabilir.",
   "es": "Cookies y ajustes de seguridad web de cada app procedentes de sus conexiones; borrarlos puede cerrar tu sesión en algunas apps.",
   "de": "Cookies und Web-Sicherheitseinstellungen pro App aus deren Netzwerkanfragen; Löschen kann dich bei manchen Apps abmelden."
  },
  "by": "macOS",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/WebKit"
  ],
  "title": {
   "en": "WebKit data",
   "tr": "WebKit verileri",
   "es": "Datos de WebKit",
   "de": "WebKit-Daten"
  },
  "what": {
   "en": "Web storage of apps that show web content, such as local databases and offline data; deleting can sign you out or lose app data.",
   "tr": "Web içeriği gösteren uygulamaların yerel veritabanları ve çevrimdışı verileri gibi web depolaması; silmek oturumu kapatabilir veya veri kaybettirebilir.",
   "es": "Almacenamiento web de apps que muestran contenido web, como bases de datos locales y datos sin conexión; borrarlo puede cerrar sesiones o perder datos.",
   "de": "Webspeicher von Apps mit Webinhalten, etwa lokale Datenbanken und Offline-Daten; Löschen kann dich abmelden oder App-Daten kosten."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Cookies"
  ],
  "title": {
   "en": "Cookies",
   "tr": "Çerezler",
   "es": "Cookies",
   "de": "Cookies"
  },
  "what": {
   "en": "Cookies saved by Safari and other apps to keep you signed in; deleting signs you out of websites.",
   "tr": "Oturumunuzu açık tutmak için Safari ve diğer uygulamaların kaydettiği çerezler; silmek web sitelerindeki oturumlarınızı kapatır.",
   "es": "Cookies que guardan Safari y otras apps para mantener tu sesión; borrarlas cierra tu sesión en las webs.",
   "de": "Cookies von Safari und anderen Apps, damit du angemeldet bleibst; Löschen meldet dich bei Websites ab."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Preferences"
  ],
  "title": {
   "en": "Preferences",
   "tr": "Tercihler",
   "es": "Preferencias",
   "de": "Einstellungen"
  },
  "what": {
   "en": "Settings files (.plist) of macOS and your apps; they're small, and deleting them resets apps to their defaults.",
   "tr": "macOS'in ve uygulamalarınızın ayar dosyaları (.plist); küçüktürler ve silmek uygulamaları varsayılan ayarlara döndürür.",
   "es": "Archivos de ajustes (.plist) de macOS y tus apps; ocupan poco y borrarlos devuelve las apps a sus valores por defecto.",
   "de": "Einstellungsdateien (.plist) von macOS und deinen Apps; klein, und Löschen setzt Apps auf Standardwerte zurück."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/LaunchAgents"
  ],
  "title": {
   "en": "Launch agents",
   "tr": "Başlatma aracıları",
   "es": "Agentes de arranque",
   "de": "Startagenten"
  },
  "what": {
   "en": "Items that start app helpers when you log in; uninstalled apps can leave old ones behind, so remove only those you recognize.",
   "tr": "Oturum açtığınızda uygulama yardımcılarını başlatan öğeler; kaldırılan uygulamalar eskilerini bırakabilir, yalnızca tanıdıklarınızı silin.",
   "es": "Elementos que inician ayudantes de apps al iniciar sesión; las apps desinstaladas pueden dejar restos, así que borra solo los que reconozcas.",
   "de": "Einträge, die beim Anmelden App-Helfer starten; deinstallierte Apps hinterlassen manchmal welche – entferne nur, was du erkennst."
  },
  "by": "macOS",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Fonts"
  ],
  "title": {
   "en": "Your fonts",
   "tr": "Yazı tipleriniz",
   "es": "Tus tipos de letra",
   "de": "Deine Schriften"
  },
  "what": {
   "en": "Fonts you installed for your account; removing one breaks documents and apps that use it.",
   "tr": "Hesabınız için yüklediğiniz yazı tipleri; birini kaldırmak onu kullanan belgeleri ve uygulamaları etkiler.",
   "es": "Tipos de letra que instalaste para tu cuenta; quitar uno afecta a los documentos y apps que lo usan.",
   "de": "Schriften, die du für deinen Account installiert hast; eine zu entfernen beeinträchtigt Dokumente und Apps, die sie nutzen."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/Library/Fonts"
  ],
  "title": {
   "en": "Fonts for all users",
   "tr": "Tüm kullanıcılar için yazı tipleri",
   "es": "Tipos de letra para todos",
   "de": "Schriften für alle Benutzer"
  },
  "what": {
   "en": "Fonts installed for all users, often by apps like Microsoft Office or Adobe; the apps that installed them rely on them.",
   "tr": "Genellikle Microsoft Office veya Adobe gibi uygulamaların tüm kullanıcılar için yüklediği yazı tipleri; bu uygulamalar onlara ihtiyaç duyar.",
   "es": "Tipos de letra instalados para todos los usuarios, a menudo por apps como Microsoft Office o Adobe, que los necesitan.",
   "de": "Für alle Benutzer installierte Schriften, oft von Apps wie Microsoft Office oder Adobe, die sie benötigen."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Keychains"
  ],
  "title": {
   "en": "Keychains",
   "tr": "Anahtar zincirleri",
   "es": "Llaveros",
   "de": "Schlüsselbunde"
  },
  "what": {
   "en": "Your saved passwords, certificates and keys; deleting them loses passwords and can lock you out of accounts.",
   "tr": "Kayıtlı parolalarınız, sertifikalarınız ve anahtarlarınız; silmek parolaları kaybettirir ve hesaplarınıza erişiminizi engelleyebilir.",
   "es": "Tus contraseñas, certificados y claves guardados; borrarlos hace perder contraseñas y puede dejarte sin acceso a cuentas.",
   "de": "Deine gesicherten Passwörter, Zertifikate und Schlüssel; Löschen kostet Passwörter und kann dich aus Accounts aussperren."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Accounts"
  ],
  "title": {
   "en": "Internet accounts",
   "tr": "İnternet hesapları",
   "es": "Cuentas de Internet",
   "de": "Internetaccounts"
  },
  "what": {
   "en": "The database of accounts set up in System Settings for Mail, Calendar and other apps; small and essential.",
   "tr": "Mail, Takvim ve diğer uygulamalar için Sistem Ayarları'nda kurulan hesapların veritabanı; küçük ama gereklidir.",
   "es": "La base de datos de cuentas configuradas en Ajustes del Sistema para Mail, Calendario y otras apps; pequeña e imprescindible.",
   "de": "Die Datenbank der in den Systemeinstellungen eingerichteten Accounts für Mail, Kalender und andere Apps; klein und unverzichtbar."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Calendars"
  ],
  "title": {
   "en": "Calendars",
   "tr": "Takvimler",
   "es": "Calendarios",
   "de": "Kalender"
  },
  "what": {
   "en": "Local calendar data and copies of synced calendars; deleting can lose events that aren't stored on a server.",
   "tr": "Yerel takvim verileri ve eşzamanlanan takvimlerin kopyaları; silmek bir sunucuda saklanmayan etkinlikleri kaybettirebilir.",
   "es": "Datos de calendarios locales y copias de los sincronizados; borrarlos puede hacerte perder eventos que no están en un servidor.",
   "de": "Lokale Kalenderdaten und Kopien synchronisierter Kalender; Löschen kann Termine kosten, die auf keinem Server liegen."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Safari"
  ],
  "title": {
   "en": "Safari data",
   "tr": "Safari verileri",
   "es": "Datos de Safari",
   "de": "Safari-Daten"
  },
  "what": {
   "en": "Your Safari bookmarks, history, Reading List and extension settings.",
   "tr": "Safari yer işaretleriniz, geçmişiniz, Okuma Listeniz ve uzantı ayarlarınız.",
   "es": "Tus marcadores, historial, lista de lectura y ajustes de extensiones de Safari.",
   "de": "Deine Safari-Lesezeichen, dein Verlauf, die Leseliste und Erweiterungseinstellungen."
  },
  "by": "Apple Safari",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Mail"
  ],
  "title": {
   "en": "Mail data",
   "tr": "Mail verileri",
   "es": "Datos de Mail",
   "de": "Mail-Daten"
  },
  "what": {
   "en": "Your email messages and attachments downloaded by Mail; it grows with every account and mailbox kept offline.",
   "tr": "Mail'in indirdiği e-posta iletileriniz ve ekleri; çevrimdışı tutulan her hesap ve posta kutusuyla büyür.",
   "es": "Tus mensajes de correo y adjuntos descargados por Mail; crece con cada cuenta y buzón que se guarda sin conexión.",
   "de": "Deine von Mail geladenen E-Mails und Anhänge; wächst mit jedem Account und Postfach, das offline verfügbar ist."
  },
  "by": "Apple Mail",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads",
   "~/Library/Mail Downloads"
  ],
  "title": {
   "en": "Opened Mail attachments",
   "tr": "Açılan Mail ekleri",
   "es": "Adjuntos abiertos de Mail",
   "de": "Geöffnete Mail-Anhänge"
  },
  "what": {
   "en": "Copies of attachments you opened from Mail; the originals stay in the messages, but check for files you edited here.",
   "tr": "Mail'den açtığınız eklerin kopyaları; orijinaller iletilerde kalır, ancak burada düzenlediğiniz dosyalar olup olmadığını kontrol edin.",
   "es": "Copias de los adjuntos que abriste desde Mail; los originales siguen en los mensajes, pero revisa si editaste algún archivo aquí.",
   "de": "Kopien von Anhängen, die du aus Mail geöffnet hast; die Originale bleiben in den E-Mails, prüfe aber, ob du hier etwas bearbeitet hast."
  },
  "by": "Apple Mail",
  "safety": "review",
  "category": "mail"
 },
 {
  "match": [
   "~/Library/Messages"
  ],
  "title": {
   "en": "Messages",
   "tr": "Mesajlar",
   "es": "Mensajes",
   "de": "Nachrichten"
  },
  "what": {
   "en": "Your Messages history and the photos, videos and files people sent you.",
   "tr": "Mesajlar geçmişiniz ve size gönderilen fotoğraflar, videolar ve dosyalar.",
   "es": "Tu historial de Mensajes y las fotos, vídeos y archivos que te enviaron.",
   "de": "Dein Nachrichtenverlauf sowie Fotos, Videos und Dateien, die dir geschickt wurden."
  },
  "by": "Apple Messages",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Messages/Attachments"
  ],
  "title": {
   "en": "Messages attachments",
   "tr": "Mesajlar ekleri",
   "es": "Adjuntos de Mensajes",
   "de": "Nachrichten-Anhänge"
  },
  "what": {
   "en": "Photos, videos and files from your chats; it grows with every conversation, and deleting removes them from the chats on this Mac.",
   "tr": "Sohbetlerinizdeki fotoğraflar, videolar ve dosyalar; her konuşmayla büyür, silmek onları bu Mac'teki sohbetlerden kaldırır.",
   "es": "Fotos, vídeos y archivos de tus chats; crece con cada conversación y borrarlos los quita de los chats en este Mac.",
   "de": "Fotos, Videos und Dateien aus deinen Chats; wächst mit jeder Unterhaltung, Löschen entfernt sie aus den Chats auf diesem Mac."
  },
  "by": "Apple Messages",
  "safety": "review",
  "category": "messages"
 },
 {
  "match": [
   "~/Library/Mobile Documents"
  ],
  "title": {
   "en": "iCloud documents",
   "tr": "iCloud belgeleri",
   "es": "Documentos de iCloud",
   "de": "iCloud-Dokumente"
  },
  "what": {
   "en": "Documents that apps and iCloud Drive sync through iCloud; deleting here deletes them from iCloud and your other devices too.",
   "tr": "Uygulamaların ve iCloud Drive'ın iCloud üzerinden eşzamanladığı belgeler; burada silmek onları iCloud'dan ve diğer aygıtlarınızdan da siler.",
   "es": "Documentos que las apps e iCloud Drive sincronizan con iCloud; borrarlos aquí los borra también de iCloud y de tus otros dispositivos.",
   "de": "Dokumente, die Apps und iCloud Drive über iCloud synchronisieren; hier Löschen entfernt sie auch aus iCloud und von deinen anderen Geräten."
  },
  "by": "Apple iCloud",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Mobile Documents/com~apple~CloudDocs"
  ],
  "title": {
   "en": "iCloud Drive",
   "tr": "iCloud Drive",
   "es": "iCloud Drive",
   "de": "iCloud Drive"
  },
  "what": {
   "en": "The files you see in iCloud Drive in Finder; deleting them here deletes them on all your devices.",
   "tr": "Finder'da iCloud Drive'da gördüğünüz dosyalar; burada silmek onları tüm aygıtlarınızdan siler.",
   "es": "Los archivos que ves en iCloud Drive en el Finder; borrarlos aquí los borra en todos tus dispositivos.",
   "de": "Die Dateien, die du im Finder unter iCloud Drive siehst; hier Löschen entfernt sie auf allen deinen Geräten."
  },
  "by": "Apple iCloud",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/CloudStorage"
  ],
  "title": {
   "en": "Cloud storage",
   "tr": "Bulut depolama",
   "es": "Almacenamiento en la nube",
   "de": "Cloud-Speicher"
  },
  "what": {
   "en": "Folders of cloud services like Dropbox, Google Drive and OneDrive; deleting files here deletes them from the cloud too.",
   "tr": "Dropbox, Google Drive ve OneDrive gibi bulut hizmetlerinin klasörleri; buradaki dosyaları silmek onları buluttan da siler.",
   "es": "Carpetas de servicios en la nube como Dropbox, Google Drive y OneDrive; borrar archivos aquí los borra también de la nube.",
   "de": "Ordner von Cloud-Diensten wie Dropbox, Google Drive und OneDrive; hier gelöschte Dateien verschwinden auch aus der Cloud."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Photos"
  ],
  "title": {
   "en": "Photos system data",
   "tr": "Fotoğraflar sistem verileri",
   "es": "Datos del sistema de Fotos",
   "de": "Fotos-Systemdaten"
  },
  "what": {
   "en": "Photo libraries macOS manages for you, such as the one with photos shared with you in Messages; managed by macOS.",
   "tr": "macOS'in sizin için yönettiği fotoğraf arşivleri; örneğin Mesajlar'da sizinle paylaşılan fotoğraflar. macOS tarafından yönetilir.",
   "es": "Fototecas que macOS gestiona por ti, como la de fotos compartidas contigo en Mensajes; las gestiona macOS.",
   "de": "Fotomediatheken, die macOS für dich verwaltet, etwa die mit in Nachrichten mit dir geteilten Fotos; von macOS verwaltet."
  },
  "by": "Apple Photos",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Metadata"
  ],
  "title": {
   "en": "Spotlight metadata",
   "tr": "Spotlight meta verileri",
   "es": "Metadatos de Spotlight",
   "de": "Spotlight-Metadaten"
  },
  "what": {
   "en": "Search indexes apps provide to Spotlight; macOS manages it, and deleting forces slow re-indexing.",
   "tr": "Uygulamaların Spotlight'a sağladığı arama dizinleri; macOS yönetir, silmek yavaş bir yeniden dizinlemeye yol açar.",
   "es": "Índices de búsqueda que las apps aportan a Spotlight; lo gestiona macOS y borrarlo obliga a una reindexación lenta.",
   "de": "Suchindizes, die Apps an Spotlight liefern; macOS verwaltet sie, Löschen erzwingt eine langsame Neuindizierung."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Biome"
  ],
  "title": {
   "en": "Biome (system activity)",
   "tr": "Biome (sistem etkinliği)",
   "es": "Biome (actividad del sistema)",
   "de": "Biome (Systemaktivität)"
  },
  "what": {
   "en": "System records of app usage, Screen Time and Siri suggestions; macOS manages and trims it, and deleting can break those features.",
   "tr": "Uygulama kullanımı, Ekran Süresi ve Siri önerilerine ait sistem kayıtları; macOS yönetir ve budar, silmek bu özellikleri bozabilir.",
   "es": "Registros del sistema sobre uso de apps, Tiempo de uso y sugerencias de Siri; macOS lo gestiona y recorta, y borrarlo puede romper esas funciones.",
   "de": "Systemaufzeichnungen zu App-Nutzung, Bildschirmzeit und Siri-Vorschlägen; macOS verwaltet und kürzt sie, Löschen kann diese Funktionen stören."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Trial"
  ],
  "title": {
   "en": "Trial (system assets)",
   "tr": "Trial (sistem varlıkları)",
   "es": "Trial (recursos del sistema)",
   "de": "Trial (Systemressourcen)"
  },
  "what": {
   "en": "Assets and settings macOS downloads for features like Siri and on-device intelligence; macOS manages it.",
   "tr": "macOS'in Siri ve aygıt üzerindeki zekâ gibi özellikler için indirdiği varlıklar ve ayarlar; macOS tarafından yönetilir.",
   "es": "Recursos y ajustes que macOS descarga para funciones como Siri y la inteligencia en el dispositivo; lo gestiona macOS.",
   "de": "Ressourcen und Einstellungen, die macOS für Funktionen wie Siri und On-Device-Intelligenz lädt; von macOS verwaltet."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/DuetExpertCenter"
  ],
  "title": {
   "en": "App predictions",
   "tr": "Uygulama tahminleri",
   "es": "Predicciones de apps",
   "de": "App-Vorhersagen"
  },
  "what": {
   "en": "Data macOS uses to predict apps and suggestions, for example in Spotlight and Siri; managed by macOS.",
   "tr": "macOS'in Spotlight ve Siri gibi yerlerde uygulama ve öneri tahmini için kullandığı veriler; macOS tarafından yönetilir.",
   "es": "Datos que macOS usa para predecir apps y sugerencias, por ejemplo en Spotlight y Siri; los gestiona macOS.",
   "de": "Daten, mit denen macOS Apps und Vorschläge vorhersagt, etwa in Spotlight und Siri; von macOS verwaltet."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Suggestions"
  ],
  "title": {
   "en": "Siri Suggestions",
   "tr": "Siri Önerileri",
   "es": "Sugerencias de Siri",
   "de": "Siri-Vorschläge"
  },
  "what": {
   "en": "Data Siri Suggestions learns from Mail, Messages and other apps to suggest contacts and events; managed by macOS.",
   "tr": "Siri Önerileri'nin kişi ve etkinlik önermek için Mail, Mesajlar ve diğer uygulamalardan öğrendiği veriler; macOS tarafından yönetilir.",
   "es": "Datos que Sugerencias de Siri aprende de Mail, Mensajes y otras apps para sugerir contactos y eventos; los gestiona macOS.",
   "de": "Daten, die Siri-Vorschläge aus Mail, Nachrichten und anderen Apps lernt, um Kontakte und Termine vorzuschlagen; von macOS verwaltet."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/IntelligencePlatform"
  ],
  "title": {
   "en": "Intelligence data",
   "tr": "Zekâ verileri",
   "es": "Datos de inteligencia",
   "de": "Intelligence-Daten"
  },
  "what": {
   "en": "Data for Apple's on-device intelligence features; macOS manages it, so don't delete it by hand.",
   "tr": "Apple'ın aygıt üzerindeki zekâ özelliklerine ait veriler; macOS yönetir, elle silmeyin.",
   "es": "Datos de las funciones de inteligencia de Apple en el dispositivo; los gestiona macOS, no los borres a mano.",
   "de": "Daten für Apples On-Device-Intelligence-Funktionen; macOS verwaltet sie, lösche sie nicht von Hand."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Assistant"
  ],
  "title": {
   "en": "Siri data",
   "tr": "Siri verileri",
   "es": "Datos de Siri",
   "de": "Siri-Daten"
  },
  "what": {
   "en": "Siri's settings, vocabulary and history; deleting can reset or break Siri.",
   "tr": "Siri'nin ayarları, sözcük dağarcığı ve geçmişi; silmek Siri'yi sıfırlayabilir veya bozabilir.",
   "es": "Ajustes, vocabulario e historial de Siri; borrarlos puede restablecer o estropear Siri.",
   "de": "Siris Einstellungen, Wortschatz und Verlauf; Löschen kann Siri zurücksetzen oder stören."
  },
  "by": "Apple Siri",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Daemon Containers"
  ],
  "title": {
   "en": "System service containers",
   "tr": "Sistem hizmeti kapsayıcıları",
   "es": "Contenedores de servicios",
   "de": "Container von Systemdiensten"
  },
  "what": {
   "en": "Sandboxed storage of macOS background services; managed by macOS, and deleting can break system features.",
   "tr": "macOS arka plan hizmetlerinin korumalı depolama alanı; macOS yönetir, silmek sistem özelliklerini bozabilir.",
   "es": "Almacenamiento aislado de servicios en segundo plano de macOS; lo gestiona macOS y borrarlo puede romper funciones del sistema.",
   "de": "Abgeschotteter Speicher von macOS-Hintergrunddiensten; von macOS verwaltet, Löschen kann Systemfunktionen stören."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/PersonalizationPortrait"
  ],
  "title": {
   "en": "Personalization data",
   "tr": "Kişiselleştirme verileri",
   "es": "Datos de personalización",
   "de": "Personalisierungsdaten"
  },
  "what": {
   "en": "An on-device profile of topics and contacts macOS learns from your use to personalize suggestions; managed by macOS.",
   "tr": "macOS'in önerileri kişiselleştirmek için kullanımınızdan öğrendiği konu ve kişilerden oluşan aygıt üzerindeki profil; macOS yönetir.",
   "es": "Un perfil en el dispositivo de temas y contactos que macOS aprende de tu uso para personalizar sugerencias; lo gestiona macOS.",
   "de": "Ein lokales Profil aus Themen und Kontakten, das macOS aus deiner Nutzung für Vorschläge lernt; von macOS verwaltet."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/com.apple.aiml.instrumentation"
  ],
  "title": {
   "en": "Machine-learning diagnostics",
   "tr": "Makine öğrenimi tanılamaları",
   "es": "Diagnóstico de aprendizaje automático",
   "de": "Machine-Learning-Diagnose"
  },
  "what": {
   "en": "Diagnostic data from Apple's on-device machine-learning features; created by macOS and best left to macOS.",
   "tr": "Apple'ın aygıt üzerindeki makine öğrenimi özelliklerinin tanılama verileri; macOS oluşturur, en iyisi macOS'e bırakmaktır.",
   "es": "Datos de diagnóstico de las funciones de aprendizaje automático de Apple; los crea macOS y es mejor dejárselos a macOS.",
   "de": "Diagnosedaten von Apples Machine-Learning-Funktionen auf dem Gerät; von macOS erstellt und am besten macOS überlassen."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Application Support/Knowledge"
  ],
  "title": {
   "en": "Screen Time history",
   "tr": "Ekran Süresi geçmişi",
   "es": "Historial de Tiempo de uso",
   "de": "Bildschirmzeit-Verlauf"
  },
  "what": {
   "en": "The app-usage history behind Screen Time and suggestions; deleting loses that history.",
   "tr": "Ekran Süresi'nin ve önerilerin dayandığı uygulama kullanım geçmişi; silmek bu geçmişi kaybettirir.",
   "es": "El historial de uso de apps que usan Tiempo de uso y las sugerencias; borrarlo elimina ese historial.",
   "de": "Der App-Nutzungsverlauf hinter Bildschirmzeit und Vorschlägen; Löschen entfernt diesen Verlauf."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Application Support/FileProvider"
  ],
  "title": {
   "en": "Cloud sync state",
   "tr": "Bulut eşzamanlama durumu",
   "es": "Estado de sincronización",
   "de": "Cloud-Sync-Status"
  },
  "what": {
   "en": "Sync state of iCloud Drive and cloud apps like Dropbox; deleting can force a full re-sync or lose unsynced changes.",
   "tr": "iCloud Drive ve Dropbox gibi bulut uygulamalarının eşzamanlama durumu; silmek tam yeniden eşzamanlamaya veya eşzamanlanmamış değişikliklerin kaybına yol açabilir.",
   "es": "Estado de sincronización de iCloud Drive y apps como Dropbox; borrarlo puede forzar una resincronización completa o perder cambios sin sincronizar.",
   "de": "Sync-Status von iCloud Drive und Cloud-Apps wie Dropbox; Löschen kann eine komplette Neusynchronisierung erzwingen oder Änderungen kosten."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Application Support/CloudDocs"
  ],
  "title": {
   "en": "iCloud Drive database",
   "tr": "iCloud Drive veritabanı",
   "es": "Base de datos de iCloud Drive",
   "de": "iCloud-Drive-Datenbank"
  },
  "what": {
   "en": "iCloud Drive's sync database; deleting it can disrupt iCloud Drive syncing.",
   "tr": "iCloud Drive'ın eşzamanlama veritabanı; silmek iCloud Drive eşzamanlamasını bozabilir.",
   "es": "La base de datos de sincronización de iCloud Drive; borrarla puede alterar la sincronización.",
   "de": "Die Sync-Datenbank von iCloud Drive; Löschen kann die Synchronisierung stören."
  },
  "by": "Apple iCloud",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Application Support/com.apple.TCC"
  ],
  "title": {
   "en": "Privacy permissions",
   "tr": "Gizlilik izinleri",
   "es": "Permisos de privacidad",
   "de": "Datenschutzberechtigungen"
  },
  "what": {
   "en": "The permissions you gave apps for the camera, microphone, files and more; protected by macOS.",
   "tr": "Uygulamalara kamera, mikrofon, dosyalar ve daha fazlası için verdiğiniz izinler; macOS tarafından korunur.",
   "es": "Los permisos que diste a las apps para cámara, micrófono, archivos y más; protegidos por macOS.",
   "de": "Die Berechtigungen, die du Apps für Kamera, Mikrofon, Dateien usw. gegeben hast; von macOS geschützt."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Application Support/AddressBook"
  ],
  "title": {
   "en": "Contacts",
   "tr": "Kişiler",
   "es": "Contactos",
   "de": "Kontakte"
  },
  "what": {
   "en": "Your contacts database for the Contacts app and synced accounts.",
   "tr": "Kişiler uygulaması ve eşzamanlanan hesaplar için kişi veritabanınız.",
   "es": "Tu base de datos de contactos para la app Contactos y las cuentas sincronizadas.",
   "de": "Deine Kontaktdatenbank für die Kontakte-App und synchronisierte Accounts."
  },
  "by": "Apple Contacts",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Application Support/CrashReporter"
  ],
  "title": {
   "en": "Crash reporter data",
   "tr": "Çökme raporlayıcı verileri",
   "es": "Datos del informe de fallos",
   "de": "Absturzmelder-Daten"
  },
  "what": {
   "en": "Small records macOS keeps about app crashes; only used for diagnostics.",
   "tr": "macOS'in uygulama çökmeleri hakkında tuttuğu küçük kayıtlar; yalnızca tanılama için kullanılır.",
   "es": "Pequeños registros que macOS guarda sobre fallos de apps; solo se usan para diagnóstico.",
   "de": "Kleine Aufzeichnungen von macOS über App-Abstürze; nur für die Diagnose genutzt."
  },
  "by": "macOS",
  "safety": "safe",
  "category": "logs"
 },
 {
  "match": [
   "~/Library/Application Support/MobileSync/Backup"
  ],
  "title": {
   "en": "iPhone and iPad backups",
   "tr": "iPhone ve iPad yedekleri",
   "es": "Copias de iPhone y iPad",
   "de": "iPhone- und iPad-Backups"
  },
  "what": {
   "en": "Local backups of your iPhone or iPad made with Finder; each can be many GB, and deleting one loses that backup.",
   "tr": "Finder ile alınmış iPhone veya iPad yerel yedekleriniz; her biri birkaç GB olabilir ve silmek o yedeği kaybettirir.",
   "es": "Copias locales de tu iPhone o iPad hechas con el Finder; cada una puede ocupar varios GB y borrarla elimina esa copia.",
   "de": "Lokale Backups deines iPhone oder iPad aus dem Finder; jedes kann viele GB groß sein, Löschen entfernt das Backup."
  },
  "by": "Apple Finder",
  "safety": "review",
  "category": "backups"
 },
 {
  "match": [
   "~/Library/Developer"
  ],
  "title": {
   "en": "Developer data",
   "tr": "Geliştirici verileri",
   "es": "Datos de desarrollo",
   "de": "Entwicklerdaten"
  },
  "what": {
   "en": "Data from Xcode, simulators and other developer tools; it can get very large, but parts of it are worth keeping.",
   "tr": "Xcode, simülatörler ve diğer geliştirici araçlarının verileri; çok büyüyebilir ama bazı kısımları saklanmaya değer.",
   "es": "Datos de Xcode, simuladores y otras herramientas de desarrollo; puede crecer mucho, pero parte merece conservarse.",
   "de": "Daten von Xcode, Simulatoren und anderen Entwicklerwerkzeugen; kann sehr groß werden, manches davon lohnt sich aber zu behalten."
  },
  "by": "Apple Xcode",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Developer/Xcode/DerivedData"
  ],
  "title": {
   "en": "Xcode DerivedData",
   "tr": "Xcode DerivedData",
   "es": "DerivedData de Xcode",
   "de": "Xcode-DerivedData"
  },
  "what": {
   "en": "Xcode's build products and indexes for your projects; Xcode recreates them on the next build, which then takes longer.",
   "tr": "Projeleriniz için Xcode'un derleme çıktıları ve dizinleri; Xcode bir sonraki derlemede yeniden oluşturur, o derleme daha uzun sürer.",
   "es": "Productos de compilación e índices de Xcode para tus proyectos; Xcode los recrea en la siguiente compilación, que tardará más.",
   "de": "Build-Produkte und Indizes von Xcode für deine Projekte; Xcode erstellt sie beim nächsten Build neu, der dann länger dauert."
  },
  "by": "Apple Xcode",
  "safety": "regenerates",
  "category": "xcode"
 },
 {
  "match": [
   "~/Library/Developer/Xcode/Archives"
  ],
  "title": {
   "en": "Xcode archives",
   "tr": "Xcode arşivleri",
   "es": "Archivos de Xcode",
   "de": "Xcode-Archive"
  },
  "what": {
   "en": "App builds you archived for distribution; keep the ones you shipped if you need their symbols to read crash reports.",
   "tr": "Dağıtım için arşivlediğiniz uygulama derlemeleri; çökme raporlarını okumak için sembollerine ihtiyaç duyuyorsanız yayımladıklarınızı saklayın.",
   "es": "Compilaciones que archivaste para distribuir; conserva las publicadas si necesitas sus símbolos para leer informes de fallos.",
   "de": "Für die Verteilung archivierte App-Builds; behalte veröffentlichte, wenn du ihre Symbole zum Lesen von Absturzberichten brauchst."
  },
  "by": "Apple Xcode",
  "safety": "review",
  "category": "archives"
 },
 {
  "match": [
   "~/Library/Developer/Xcode/iOS DeviceSupport",
   "~/Library/Developer/Xcode/watchOS DeviceSupport",
   "~/Library/Developer/Xcode/tvOS DeviceSupport"
  ],
  "title": {
   "en": "Device support files",
   "tr": "Aygıt destek dosyaları",
   "es": "Archivos de soporte de dispositivos",
   "de": "Gerätesupport-Dateien"
  },
  "what": {
   "en": "Debug symbols Xcode copies for each OS version of the devices you connect; old versions pile up, and Xcode copies them again when needed.",
   "tr": "Xcode'un bağladığınız aygıtların her işletim sistemi sürümü için kopyaladığı hata ayıklama sembolleri; eski sürümler birikir, gerekirse yeniden kopyalanır.",
   "es": "Símbolos de depuración que Xcode copia por cada versión del sistema de los dispositivos que conectas; los antiguos se acumulan y se copian de nuevo si hace falta.",
   "de": "Debug-Symbole, die Xcode für jede OS-Version verbundener Geräte kopiert; alte sammeln sich an und werden bei Bedarf erneut kopiert."
  },
  "by": "Apple Xcode",
  "safety": "regenerates",
  "category": "xcode"
 },
 {
  "match": [
   "~/Library/Developer/Xcode/UserData/Previews"
  ],
  "title": {
   "en": "SwiftUI preview simulators",
   "tr": "SwiftUI önizleme simülatörleri",
   "es": "Simuladores de vistas previas de SwiftUI",
   "de": "SwiftUI-Vorschau-Simulatoren"
  },
  "what": {
   "en": "Simulator devices Xcode creates to render SwiftUI previews; Xcode recreates them the next time you preview.",
   "tr": "Xcode'un SwiftUI önizlemelerini oluşturmak için yarattığı simülatör aygıtları; bir sonraki önizlemede yeniden oluşturulur.",
   "es": "Dispositivos de simulador que Xcode crea para las vistas previas de SwiftUI; los recrea la próxima vez que previsualices.",
   "de": "Simulatorgeräte, die Xcode für SwiftUI-Vorschauen anlegt; beim nächsten Vorschauen werden sie neu erstellt."
  },
  "by": "Apple Xcode",
  "safety": "regenerates",
  "category": "simulators"
 },
 {
  "match": [
   "~/Library/Developer/Xcode/UserData"
  ],
  "title": {
   "en": "Xcode user data",
   "tr": "Xcode kullanıcı verileri",
   "es": "Datos de usuario de Xcode",
   "de": "Xcode-Benutzerdaten"
  },
  "what": {
   "en": "Your Xcode key bindings, themes, code snippets and other customizations.",
   "tr": "Xcode tuş atamalarınız, temalarınız, kod parçacıklarınız ve diğer özelleştirmeleriniz.",
   "es": "Tus atajos de teclado, temas, fragmentos de código y otras personalizaciones de Xcode.",
   "de": "Deine Xcode-Tastaturbelegungen, Themes, Code-Snippets und andere Anpassungen."
  },
  "by": "Apple Xcode",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Developer/CoreSimulator/Devices"
  ],
  "title": {
   "en": "Simulator devices",
   "tr": "Simülatör aygıtları",
   "es": "Dispositivos del simulador",
   "de": "Simulator-Geräte"
  },
  "what": {
   "en": "Simulators with their installed apps and data; remove old ones in Xcode or with “xcrun simctl delete unavailable”.",
   "tr": "Yüklü uygulamaları ve verileriyle simülatörler; eskileri Xcode'dan veya “xcrun simctl delete unavailable” ile kaldırın.",
   "es": "Simuladores con sus apps y datos instalados; elimina los antiguos en Xcode o con “xcrun simctl delete unavailable”.",
   "de": "Simulatoren mit installierten Apps und Daten; entferne alte in Xcode oder mit „xcrun simctl delete unavailable“."
  },
  "by": "Apple Xcode",
  "safety": "review",
  "category": "simulators"
 },
 {
  "match": [
   "~/Library/Developer/CoreSimulator/Caches"
  ],
  "title": {
   "en": "Simulator caches",
   "tr": "Simülatör önbellekleri",
   "es": "Cachés del simulador",
   "de": "Simulator-Caches"
  },
  "what": {
   "en": "Caches built for simulator runtimes, such as shared library caches; they're recreated when you next boot a simulator.",
   "tr": "Simülatör çalışma ortamları için oluşturulan, paylaşılan kitaplık önbellekleri gibi önbellekler; bir simülatörü yeniden başlattığınızda oluşturulur.",
   "es": "Cachés creadas para los entornos del simulador, como las de bibliotecas compartidas; se recrean al arrancar de nuevo un simulador.",
   "de": "Für Simulator-Laufzeiten erstellte Caches, etwa für gemeinsame Bibliotheken; sie entstehen beim nächsten Simulatorstart neu."
  },
  "by": "Apple Xcode",
  "safety": "regenerates",
  "category": "simulators"
 },
 {
  "match": [
   "~/Library/Developer/XCPGDevices"
  ],
  "title": {
   "en": "Playground simulators",
   "tr": "Playground simülatörleri",
   "es": "Simuladores de playgrounds",
   "de": "Playground-Simulatoren"
  },
  "what": {
   "en": "Simulator devices Xcode creates to run playgrounds; they're recreated when you run a playground again.",
   "tr": "Xcode'un playground'ları çalıştırmak için oluşturduğu simülatör aygıtları; bir playground'u yeniden çalıştırdığınızda oluşturulur.",
   "es": "Dispositivos de simulador que Xcode crea para ejecutar playgrounds; se recrean al volver a ejecutar uno.",
   "de": "Simulatorgeräte, die Xcode für Playgrounds anlegt; sie entstehen neu, wenn du wieder einen Playground ausführst."
  },
  "by": "Apple Xcode",
  "safety": "regenerates",
  "category": "simulators"
 },
 {
  "match": [
   "~/Library/Developer/XCTestDevices"
  ],
  "title": {
   "en": "Test simulator clones",
   "tr": "Test simülatörü kopyaları",
   "es": "Clones de simulador para tests",
   "de": "Test-Simulatorklone"
  },
  "what": {
   "en": "Simulator clones Xcode makes for parallel testing; they're recreated on the next parallel test run.",
   "tr": "Xcode'un paralel test için oluşturduğu simülatör kopyaları; bir sonraki paralel testte yeniden oluşturulur.",
   "es": "Clones de simulador que Xcode crea para tests en paralelo; se recrean en la siguiente ejecución en paralelo.",
   "de": "Simulatorklone, die Xcode für paralleles Testen anlegt; sie entstehen beim nächsten parallelen Testlauf neu."
  },
  "by": "Apple Xcode",
  "safety": "regenerates",
  "category": "simulators"
 },
 {
  "match": [
   "~/Library/Developer/Toolchains"
  ],
  "title": {
   "en": "Swift toolchains",
   "tr": "Swift araç zincirleri",
   "es": "Toolchains de Swift",
   "de": "Swift-Toolchains"
  },
  "what": {
   "en": "Extra Swift toolchains you installed besides the one in Xcode; remove versions you no longer build with.",
   "tr": "Xcode'dakinin dışında yüklediğiniz ek Swift araç zincirleri; artık kullanmadığınız sürümleri kaldırın.",
   "es": "Toolchains de Swift adicionales que instalaste aparte del de Xcode; elimina las versiones que ya no uses.",
   "de": "Zusätzlich zu Xcode installierte Swift-Toolchains; entferne Versionen, mit denen du nicht mehr baust."
  },
  "by": "Swift",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Logs/CoreSimulator"
  ],
  "title": {
   "en": "Simulator logs",
   "tr": "Simülatör günlükleri",
   "es": "Registros del simulador",
   "de": "Simulator-Protokolle"
  },
  "what": {
   "en": "Logs from the iOS and other simulators; only useful for debugging, and new ones are written as simulators run.",
   "tr": "iOS ve diğer simülatörlerin günlükleri; yalnızca hata ayıklamada işe yarar, simülatörler çalıştıkça yenileri yazılır.",
   "es": "Registros de los simuladores de iOS y otros; solo sirven para depurar y se escriben nuevos al usarlos.",
   "de": "Protokolle der iOS- und anderer Simulatoren; nur zum Debuggen nützlich, neue entstehen beim Betrieb."
  },
  "by": "Apple Xcode",
  "safety": "safe",
  "category": "logs"
 },
 {
  "match": [
   "~/Library/Caches/com.apple.dt.Xcode"
  ],
  "title": {
   "en": "Xcode cache",
   "tr": "Xcode önbelleği",
   "es": "Caché de Xcode",
   "de": "Xcode-Cache"
  },
  "what": {
   "en": "Temporary data Xcode keeps, such as downloads and network caches; Xcode recreates it as needed.",
   "tr": "Xcode'un tuttuğu indirmeler ve ağ önbellekleri gibi geçici veriler; Xcode gerektiğinde yeniden oluşturur.",
   "es": "Datos temporales de Xcode, como descargas y cachés de red; Xcode los recrea cuando hace falta.",
   "de": "Temporäre Xcode-Daten wie Downloads und Netzwerk-Caches; Xcode erstellt sie bei Bedarf neu."
  },
  "by": "Apple Xcode",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "/Library/Developer/CoreSimulator/Volumes",
   "/Library/Developer/CoreSimulator/Images"
  ],
  "title": {
   "en": "Simulator runtimes",
   "tr": "Simülatör çalışma ortamları",
   "es": "Entornos del simulador",
   "de": "Simulator-Laufzeiten"
  },
  "what": {
   "en": "Downloaded simulator runtimes, several GB each; remove old ones in Xcode Settings › Components rather than by hand.",
   "tr": "İndirilmiş simülatör çalışma ortamları, her biri birkaç GB; eskileri elle değil Xcode Ayarlar › Bileşenler'den kaldırın.",
   "es": "Entornos de simulador descargados, de varios GB cada uno; elimina los antiguos en Ajustes de Xcode › Componentes, no a mano.",
   "de": "Geladene Simulator-Laufzeiten, je mehrere GB; entferne alte in den Xcode-Einstellungen › Komponenten statt von Hand."
  },
  "by": "Apple Xcode",
  "safety": "review",
  "category": "simulators"
 },
 {
  "match": [
   "/Library/Developer/CoreSimulator/Profiles/Runtimes"
  ],
  "title": {
   "en": "Older simulator runtimes",
   "tr": "Eski simülatör çalışma ortamları",
   "es": "Entornos del simulador antiguos",
   "de": "Ältere Simulator-Laufzeiten"
  },
  "what": {
   "en": "Simulator runtimes installed by older Xcode versions; remove the ones you no longer test on.",
   "tr": "Eski Xcode sürümlerinin yüklediği simülatör çalışma ortamları; artık test etmediğiniz sürümleri kaldırın.",
   "es": "Entornos de simulador instalados por versiones antiguas de Xcode; elimina los que ya no uses para probar.",
   "de": "Von älteren Xcode-Versionen installierte Simulator-Laufzeiten; entferne die, auf denen du nicht mehr testest."
  },
  "by": "Apple Xcode",
  "safety": "review",
  "category": "simulators"
 },
 {
  "match": [
   "/Library/Developer/CommandLineTools"
  ],
  "title": {
   "en": "Command Line Tools",
   "tr": "Komut Satırı Araçları",
   "es": "Herramientas de línea de comandos",
   "de": "Befehlszeilenwerkzeuge"
  },
  "what": {
   "en": "Apple's compilers, git and other developer tools that Homebrew and many other tools depend on; deleting breaks them.",
   "tr": "Homebrew'un ve birçok aracın dayandığı Apple derleyicileri, git ve diğer geliştirici araçları; silmek bunları bozar.",
   "es": "Compiladores de Apple, git y otras herramientas de las que dependen Homebrew y muchas otras; borrarlas las rompe.",
   "de": "Apples Compiler, git und andere Werkzeuge, auf die Homebrew und viele Tools angewiesen sind; Löschen macht sie unbrauchbar."
  },
  "by": "Apple",
  "safety": "keep"
 },
 {
  "match": [
   "/Applications/Xcode*.app"
  ],
  "title": {
   "en": "Xcode app",
   "tr": "Xcode uygulaması",
   "es": "App Xcode",
   "de": "Xcode-App"
  },
  "what": {
   "en": "Xcode itself, often over 10 GB; if you keep several versions, remove the ones you no longer need.",
   "tr": "Xcode'un kendisi, genellikle 10 GB'tan büyük; birden fazla sürüm tutuyorsanız ihtiyaç duymadıklarınızı kaldırın.",
   "es": "El propio Xcode, a menudo más de 10 GB; si tienes varias versiones, elimina las que ya no necesites.",
   "de": "Xcode selbst, oft über 10 GB; wenn du mehrere Versionen hast, entferne die nicht mehr benötigten."
  },
  "by": "Apple Xcode",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Android/sdk"
  ],
  "title": {
   "en": "Android SDK",
   "tr": "Android SDK",
   "es": "SDK de Android",
   "de": "Android-SDK"
  },
  "what": {
   "en": "Android platforms, build tools, emulators and system images; manage it with Android Studio's SDK Manager.",
   "tr": "Android platformları, derleme araçları, emülatörler ve sistem görüntüleri; Android Studio'nun SDK Yöneticisi ile yönetin.",
   "es": "Plataformas, herramientas de compilación, emuladores e imágenes del sistema de Android; gestiónalo con el SDK Manager de Android Studio.",
   "de": "Android-Plattformen, Build-Tools, Emulatoren und System-Images; verwalte es mit dem SDK-Manager von Android Studio."
  },
  "by": "Google Android Studio",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Android/sdk/system-images"
  ],
  "title": {
   "en": "Android system images",
   "tr": "Android sistem görüntüleri",
   "es": "Imágenes del sistema de Android",
   "de": "Android-System-Images"
  },
  "what": {
   "en": "Emulator OS images, about 1–4 GB each; remove versions you don't run, and the SDK Manager can download them again.",
   "tr": "Emülatör işletim sistemi görüntüleri, her biri yaklaşık 1–4 GB; kullanmadığınız sürümleri kaldırın, SDK Yöneticisi yeniden indirebilir.",
   "es": "Imágenes del sistema para el emulador, de 1–4 GB cada una; elimina las que no uses, el SDK Manager puede volver a descargarlas.",
   "de": "Emulator-System-Images, je etwa 1–4 GB; entferne ungenutzte Versionen, der SDK-Manager kann sie erneut laden."
  },
  "by": "Google Android Studio",
  "safety": "review",
  "category": "devtools"
 },
 {
  "match": [
   "~/Library/Android/sdk/ndk"
  ],
  "title": {
   "en": "Android NDK",
   "tr": "Android NDK",
   "es": "NDK de Android",
   "de": "Android-NDK"
  },
  "what": {
   "en": "Native development kits, often 1+ GB per version; old versions pile up as projects upgrade.",
   "tr": "Yerel geliştirme kitleri, sürüm başına genellikle 1 GB'tan fazla; projeler güncellendikçe eski sürümler birikir.",
   "es": "Kits de desarrollo nativo, a menudo más de 1 GB por versión; las antiguas se acumulan al actualizar proyectos.",
   "de": "Native Development Kits, oft über 1 GB pro Version; alte sammeln sich an, wenn Projekte aktualisiert werden."
  },
  "by": "Google Android Studio",
  "safety": "review",
  "category": "devtools"
 },
 {
  "match": [
   "~/.android"
  ],
  "title": {
   "en": "Android settings",
   "tr": "Android ayarları",
   "es": "Ajustes de Android",
   "de": "Android-Einstellungen"
  },
  "what": {
   "en": "Android tooling data, including your debug signing key, adb keys and emulator devices; deleting can break app signing.",
   "tr": "Hata ayıklama imza anahtarınız, adb anahtarları ve emülatör aygıtları dahil Android araç verileri; silmek uygulama imzalamayı bozabilir.",
   "es": "Datos de las herramientas de Android, incluida tu clave de firma de depuración, claves de adb y emuladores; borrarlos puede romper la firma.",
   "de": "Daten der Android-Tools inklusive Debug-Signaturschlüssel, adb-Schlüssel und Emulatoren; Löschen kann das Signieren stören."
  },
  "by": "Google Android Studio",
  "safety": "keep"
 },
 {
  "match": [
   "~/.android/avd"
  ],
  "title": {
   "en": "Android emulators",
   "tr": "Android emülatörleri",
   "es": "Emuladores de Android",
   "de": "Android-Emulatoren"
  },
  "what": {
   "en": "Your Android Virtual Devices with their disks and snapshots; delete unused ones in Android Studio's Device Manager.",
   "tr": "Diskleri ve anlık görüntüleriyle Android Sanal Aygıtlarınız; kullanmadıklarınızı Android Studio'nun Aygıt Yöneticisi'nden silin.",
   "es": "Tus dispositivos virtuales de Android con sus discos e instantáneas; borra los que no uses desde el Device Manager de Android Studio.",
   "de": "Deine virtuellen Android-Geräte mit Festplatten und Snapshots; lösche ungenutzte im Geräte-Manager von Android Studio."
  },
  "by": "Google Android Studio",
  "safety": "review",
  "category": "devtools"
 },
 {
  "match": [
   "~/.android/cache"
  ],
  "title": {
   "en": "Android tools cache",
   "tr": "Android araçları önbelleği",
   "es": "Caché de herramientas Android",
   "de": "Android-Tools-Cache"
  },
  "what": {
   "en": "Downloads cached by the Android SDK tools; they're fetched again when needed.",
   "tr": "Android SDK araçlarının önbelleğe aldığı indirmeler; gerektiğinde yeniden alınır.",
   "es": "Descargas que guardan las herramientas del SDK de Android; se vuelven a obtener cuando hacen falta.",
   "de": "Von den Android-SDK-Tools zwischengespeicherte Downloads; sie werden bei Bedarf neu geladen."
  },
  "by": "Google Android Studio",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Application Support/Google/AndroidStudio*"
  ],
  "title": {
   "en": "Android Studio settings",
   "tr": "Android Studio ayarları",
   "es": "Ajustes de Android Studio",
   "de": "Android-Studio-Einstellungen"
  },
  "what": {
   "en": "Settings and plugins of one Android Studio version; folders of versions you no longer use are leftovers.",
   "tr": "Bir Android Studio sürümünün ayarları ve eklentileri; artık kullanmadığınız sürümlerin klasörleri artıktır.",
   "es": "Ajustes y plugins de una versión de Android Studio; las carpetas de versiones que ya no usas son restos.",
   "de": "Einstellungen und Plugins einer Android-Studio-Version; Ordner nicht mehr genutzter Versionen sind Überbleibsel."
  },
  "by": "Google Android Studio",
  "safety": "review",
  "category": "devtools"
 },
 {
  "match": [
   "~/Library/Caches/Google/AndroidStudio*"
  ],
  "title": {
   "en": "Android Studio cache",
   "tr": "Android Studio önbelleği",
   "es": "Caché de Android Studio",
   "de": "Android-Studio-Cache"
  },
  "what": {
   "en": "Indexes and caches of one Android Studio version; rebuilt on the next launch, and old versions' folders are leftovers.",
   "tr": "Bir Android Studio sürümünün dizinleri ve önbellekleri; bir sonraki açılışta yeniden oluşturulur, eski sürümlerin klasörleri artıktır.",
   "es": "Índices y cachés de una versión de Android Studio; se regeneran al abrirlo y las carpetas de versiones antiguas son restos.",
   "de": "Indizes und Caches einer Android-Studio-Version; beim nächsten Start neu aufgebaut, Ordner alter Versionen sind Überbleibsel."
  },
  "by": "Google Android Studio",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "~/Library/Application Support/JetBrains"
  ],
  "title": {
   "en": "JetBrains IDE settings",
   "tr": "JetBrains IDE ayarları",
   "es": "Ajustes de IDE de JetBrains",
   "de": "JetBrains-IDE-Einstellungen"
  },
  "what": {
   "en": "Settings and plugins for each JetBrains IDE version; folders for versions you've upgraded from are usually leftovers.",
   "tr": "Her JetBrains IDE sürümünün ayarları ve eklentileri; yükselttiğiniz eski sürümlerin klasörleri genellikle artıktır.",
   "es": "Ajustes y plugins de cada versión de los IDE de JetBrains; las carpetas de versiones antiguas suelen ser restos.",
   "de": "Einstellungen und Plugins jeder JetBrains-IDE-Version; Ordner von Versionen, die du ersetzt hast, sind meist Überbleibsel."
  },
  "by": "JetBrains",
  "safety": "review",
  "category": "devtools"
 },
 {
  "match": [
   "~/Library/Application Support/JetBrains/Toolbox"
  ],
  "title": {
   "en": "JetBrains Toolbox apps",
   "tr": "JetBrains Toolbox uygulamaları",
   "es": "Apps de JetBrains Toolbox",
   "de": "JetBrains-Toolbox-Apps"
  },
  "what": {
   "en": "IDEs installed by JetBrains Toolbox, sometimes with old versions kept for rollback; manage them in Toolbox.",
   "tr": "JetBrains Toolbox'ın yüklediği IDE'ler; bazen geri dönüş için eski sürümler de tutulur. Toolbox'tan yönetin.",
   "es": "IDE instalados por JetBrains Toolbox, a veces con versiones antiguas para volver atrás; gestiónalos desde Toolbox.",
   "de": "Von JetBrains Toolbox installierte IDEs, teils mit alten Versionen zum Zurücksetzen; verwalte sie in Toolbox."
  },
  "by": "JetBrains Toolbox",
  "safety": "review",
  "category": "devtools"
 },
 {
  "match": [
   "~/Library/Caches/JetBrains"
  ],
  "title": {
   "en": "JetBrains IDE caches",
   "tr": "JetBrains IDE önbellekleri",
   "es": "Cachés de IDE de JetBrains",
   "de": "JetBrains-IDE-Caches"
  },
  "what": {
   "en": "Indexes and caches of JetBrains IDEs; rebuilt when you open a project, which is slower the first time.",
   "tr": "JetBrains IDE'lerinin dizinleri ve önbellekleri; bir projeyi açtığınızda yeniden oluşturulur, ilk açılış daha yavaştır.",
   "es": "Índices y cachés de los IDE de JetBrains; se regeneran al abrir un proyecto, que la primera vez irá más lento.",
   "de": "Indizes und Caches der JetBrains-IDEs; beim Öffnen eines Projekts neu aufgebaut, was beim ersten Mal dauert."
  },
  "by": "JetBrains",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "~/Library/Logs/JetBrains"
  ],
  "title": {
   "en": "JetBrains IDE logs",
   "tr": "JetBrains IDE günlükleri",
   "es": "Registros de IDE de JetBrains",
   "de": "JetBrains-IDE-Protokolle"
  },
  "what": {
   "en": "Log files from JetBrains IDEs; only useful when troubleshooting.",
   "tr": "JetBrains IDE'lerinin günlük dosyaları; yalnızca sorun gidermede işe yarar.",
   "es": "Archivos de registro de los IDE de JetBrains; solo sirven para diagnosticar problemas.",
   "de": "Protokolldateien der JetBrains-IDEs; nur zur Fehlersuche nützlich."
  },
  "by": "JetBrains",
  "safety": "safe",
  "category": "logs"
 },
 {
  "match": [
   "/Applications"
  ],
  "title": {
   "en": "Applications",
   "tr": "Uygulamalar",
   "es": "Aplicaciones",
   "de": "Programme"
  },
  "what": {
   "en": "Apps installed for all users; remove an app you don't use by moving it to the Trash.",
   "tr": "Tüm kullanıcılar için yüklenmiş uygulamalar; kullanmadığınız bir uygulamayı Çöp Sepeti'ne taşıyarak kaldırın.",
   "es": "Apps instaladas para todos los usuarios; elimina una app que no uses moviéndola a la Papelera.",
   "de": "Für alle Benutzer installierte Apps; entferne eine ungenutzte App, indem du sie in den Papierkorb legst."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/Applications/Install macOS*.app"
  ],
  "title": {
   "en": "macOS installer",
   "tr": "macOS yükleyicisi",
   "es": "Instalador de macOS",
   "de": "macOS-Installationsprogramm"
  },
  "what": {
   "en": "A full macOS installer of about 12–15 GB; after upgrading you only need it to make a bootable USB drive.",
   "tr": "Yaklaşık 12–15 GB'lık tam macOS yükleyicisi; yükseltmeden sonra yalnızca önyüklenebilir USB oluşturmak için gerekir.",
   "es": "Un instalador completo de macOS de unos 12–15 GB; tras actualizar solo lo necesitas para crear un USB de arranque.",
   "de": "Ein vollständiges macOS-Installationsprogramm mit etwa 12–15 GB; nach dem Upgrade nur für einen bootfähigen USB-Stick nötig."
  },
  "by": "Apple",
  "safety": "review",
  "category": "installers"
 },
 {
  "match": [
   "/Library/Updates"
  ],
  "title": {
   "en": "Downloaded macOS updates",
   "tr": "İndirilmiş macOS güncellemeleri",
   "es": "Actualizaciones de macOS descargadas",
   "de": "Geladene macOS-Updates"
  },
  "what": {
   "en": "Software updates downloaded and waiting to install; macOS protects this folder and downloads updates again if needed.",
   "tr": "İndirilmiş ve yüklenmeyi bekleyen yazılım güncellemeleri; macOS bu klasörü korur ve gerekirse güncellemeleri yeniden indirir.",
   "es": "Actualizaciones descargadas que esperan a instalarse; macOS protege esta carpeta y las vuelve a descargar si hace falta.",
   "de": "Geladene Softwareupdates, die auf die Installation warten; macOS schützt diesen Ordner und lädt Updates bei Bedarf erneut."
  },
  "by": "Apple",
  "safety": "regenerates"
 },
 {
  "match": [
   "/Library/Caches"
  ],
  "title": {
   "en": "System caches",
   "tr": "Sistem önbellekleri",
   "es": "Cachés del sistema",
   "de": "System-Caches"
  },
  "what": {
   "en": "Caches shared by all users and system services; they're rebuilt as needed.",
   "tr": "Tüm kullanıcıların ve sistem hizmetlerinin paylaştığı önbellekler; gerektiğinde yeniden oluşturulur.",
   "es": "Cachés compartidas por todos los usuarios y servicios del sistema; se regeneran cuando hace falta.",
   "de": "Caches, die alle Benutzer und Systemdienste teilen; sie werden bei Bedarf neu aufgebaut."
  },
  "by": "macOS",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "/Library/Application Support"
  ],
  "title": {
   "en": "System-wide app data",
   "tr": "Sistem geneli uygulama verileri",
   "es": "Datos de apps para todos",
   "de": "Systemweite App-Daten"
  },
  "what": {
   "en": "Data and plug-ins apps install for all users, such as sound libraries and licenses; deleting can break apps.",
   "tr": "Uygulamaların tüm kullanıcılar için yüklediği ses kitaplıkları ve lisanslar gibi veriler ve eklentiler; silmek uygulamaları bozabilir.",
   "es": "Datos y complementos que las apps instalan para todos, como bibliotecas de sonido y licencias; borrarlos puede estropear apps.",
   "de": "Daten und Plug-ins, die Apps für alle Benutzer installieren, etwa Soundbibliotheken und Lizenzen; Löschen kann Apps beschädigen."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/Library"
  ],
  "title": {
   "en": "System Library",
   "tr": "Sistem Kitaplığı",
   "es": "Biblioteca del sistema",
   "de": "Systemweite Library"
  },
  "what": {
   "en": "Settings, fonts, drivers and data shared by all users; macOS and apps rely on it.",
   "tr": "Tüm kullanıcıların paylaştığı ayarlar, yazı tipleri, sürücüler ve veriler; macOS ve uygulamalar buna dayanır.",
   "es": "Ajustes, tipos de letra, controladores y datos compartidos por todos los usuarios; macOS y las apps dependen de ella.",
   "de": "Einstellungen, Schriften, Treiber und Daten für alle Benutzer; macOS und Apps sind darauf angewiesen."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/System"
  ],
  "title": {
   "en": "macOS system",
   "tr": "macOS sistemi",
   "es": "Sistema macOS",
   "de": "macOS-System"
  },
  "what": {
   "en": "The read-only, sealed macOS system volume; it can't and shouldn't be modified.",
   "tr": "Salt okunur, mühürlü macOS sistem bölümü; değiştirilemez ve değiştirilmemelidir.",
   "es": "El volumen del sistema macOS, sellado y de solo lectura; no se puede ni se debe modificar.",
   "de": "Das schreibgeschützte, versiegelte macOS-Systemvolume; es kann und soll nicht verändert werden."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/private/var/folders"
  ],
  "title": {
   "en": "Temporary files",
   "tr": "Geçici dosyalar",
   "es": "Archivos temporales",
   "de": "Temporäre Dateien"
  },
  "what": {
   "en": "Per-user temporary files and caches managed by macOS; cleaned automatically, and deleting by hand can crash running apps.",
   "tr": "macOS'in yönettiği kullanıcıya özel geçici dosyalar ve önbellekler; otomatik temizlenir, elle silmek çalışan uygulamaları çökertebilir.",
   "es": "Archivos temporales y cachés por usuario que gestiona macOS; se limpian solos y borrarlos a mano puede bloquear apps abiertas.",
   "de": "Temporäre Dateien und Caches pro Benutzer, von macOS verwaltet; werden automatisch bereinigt, manuelles Löschen kann laufende Apps abstürzen lassen."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/private/tmp"
  ],
  "title": {
   "en": "Temporary folder (tmp)",
   "tr": "Geçici klasör (tmp)",
   "es": "Carpeta temporal (tmp)",
   "de": "Temporärer Ordner (tmp)"
  },
  "what": {
   "en": "Short-lived files of running programs; macOS clears old files here automatically, so a restart is better than deleting.",
   "tr": "Çalışan programların kısa ömürlü dosyaları; macOS buradaki eski dosyaları otomatik temizler, silmek yerine yeniden başlatmak daha iyidir.",
   "es": "Archivos efímeros de programas en marcha; macOS borra solo los antiguos, así que reiniciar es mejor que borrar.",
   "de": "Kurzlebige Dateien laufender Programme; macOS entfernt alte Dateien hier automatisch, ein Neustart ist besser als Löschen."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/private/var/vm"
  ],
  "title": {
   "en": "Swap and sleep image",
   "tr": "Takas ve uyku görüntüsü",
   "es": "Intercambio e imagen de reposo",
   "de": "Auslagerung und Ruhezustandsabbild"
  },
  "what": {
   "en": "Swap files used when memory runs short, plus the sleep image; macOS manages them, and they shrink after a restart.",
   "tr": "Bellek yetmediğinde kullanılan takas dosyaları ve uyku görüntüsü; macOS yönetir, yeniden başlatınca küçülürler.",
   "es": "Archivos de intercambio usados cuando falta memoria y la imagen de reposo; los gestiona macOS y se reducen al reiniciar.",
   "de": "Auslagerungsdateien bei knappem Arbeitsspeicher und das Ruhezustandsabbild; macOS verwaltet sie, nach einem Neustart schrumpfen sie."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/private/var/log"
  ],
  "title": {
   "en": "System log files",
   "tr": "Sistem günlük dosyaları",
   "es": "Archivos de registro del sistema",
   "de": "Systemprotokolldateien"
  },
  "what": {
   "en": "Classic system log files that macOS rotates and trims on its own.",
   "tr": "macOS'in kendisi döndürüp budadığı klasik sistem günlük dosyaları.",
   "es": "Archivos de registro clásicos del sistema que macOS rota y recorta por sí mismo.",
   "de": "Klassische Systemprotokolle, die macOS selbst rotiert und kürzt."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/private/var/db/diagnostics",
   "/private/var/db/uuidtext"
  ],
  "title": {
   "en": "Unified system log",
   "tr": "Birleşik sistem günlüğü",
   "es": "Registro unificado del sistema",
   "de": "Vereinheitlichtes Systemprotokoll"
  },
  "what": {
   "en": "macOS's unified system log, read by Console; it's trimmed automatically by size and age.",
   "tr": "Konsol'un okuduğu macOS birleşik sistem günlüğü; boyut ve yaşa göre otomatik budanır.",
   "es": "El registro unificado de macOS que lee Consola; se recorta solo según tamaño y antigüedad.",
   "de": "Das vereinheitlichte macOS-Systemprotokoll, das die Konsole liest; wird automatisch nach Größe und Alter gekürzt."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/System/Volumes/Data/.Spotlight-V100"
  ],
  "title": {
   "en": "Spotlight index",
   "tr": "Spotlight dizini",
   "es": "Índice de Spotlight",
   "de": "Spotlight-Index"
  },
  "what": {
   "en": "The Spotlight search index of this disk; macOS manages it, and deleting forces a long re-index.",
   "tr": "Bu diskin Spotlight arama dizini; macOS yönetir, silmek uzun bir yeniden dizinlemeye yol açar.",
   "es": "El índice de búsqueda de Spotlight de este disco; lo gestiona macOS y borrarlo obliga a una larga reindexación.",
   "de": "Der Spotlight-Suchindex dieses Laufwerks; macOS verwaltet ihn, Löschen erzwingt eine lange Neuindizierung."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/System/Volumes/Data/.fseventsd"
  ],
  "title": {
   "en": "File change log",
   "tr": "Dosya değişiklik günlüğü",
   "es": "Registro de cambios de archivos",
   "de": "Dateiänderungsprotokoll"
  },
  "what": {
   "en": "A log of file changes used by Time Machine, Spotlight and backup apps; deleting can trigger full rescans.",
   "tr": "Time Machine, Spotlight ve yedekleme uygulamalarının kullandığı dosya değişiklikleri günlüğü; silmek tam yeniden taramalara yol açabilir.",
   "es": "Un registro de cambios de archivos que usan Time Machine, Spotlight y apps de copia; borrarlo puede provocar reescaneos completos.",
   "de": "Ein Protokoll von Dateiänderungen für Time Machine, Spotlight und Backup-Apps; Löschen kann komplette Neuscans auslösen."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/Users/Shared"
  ],
  "title": {
   "en": "Shared folder",
   "tr": "Paylaşılan klasör",
   "es": "Carpeta compartida",
   "de": "Geteilter Ordner"
  },
  "what": {
   "en": "Files shared between all users of this Mac; some apps also store their data or libraries here.",
   "tr": "Bu Mac'in tüm kullanıcıları arasında paylaşılan dosyalar; bazı uygulamalar verilerini veya kitaplıklarını da burada tutar.",
   "es": "Archivos compartidos entre todos los usuarios de este Mac; algunas apps también guardan aquí sus datos o bibliotecas.",
   "de": "Dateien, die alle Benutzer dieses Mac teilen; manche Apps legen hier auch Daten oder Bibliotheken ab."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "/Library/LaunchDaemons",
   "/Library/LaunchAgents"
  ],
  "title": {
   "en": "System launch items",
   "tr": "Sistem başlatma öğeleri",
   "es": "Elementos de arranque del sistema",
   "de": "System-Startobjekte"
  },
  "what": {
   "en": "Background services apps install for all users; removed apps can leave theirs behind, so remove only those you recognize.",
   "tr": "Uygulamaların tüm kullanıcılar için yüklediği arka plan hizmetleri; kaldırılan uygulamalar kalıntı bırakabilir, yalnızca tanıdıklarınızı silin.",
   "es": "Servicios en segundo plano que las apps instalan para todos; las apps eliminadas pueden dejar restos, borra solo los que reconozcas.",
   "de": "Hintergrunddienste, die Apps für alle Benutzer installieren; entfernte Apps lassen manchmal welche zurück – lösche nur bekannte."
  },
  "by": "macOS",
  "safety": "review"
 },
 {
  "match": [
   "/Library/PrivilegedHelperTools"
  ],
  "title": {
   "en": "Privileged helpers",
   "tr": "Ayrıcalıklı yardımcılar",
   "es": "Ayudantes con privilegios",
   "de": "Privilegierte Hilfsprogramme"
  },
  "what": {
   "en": "Helper programs apps install to run with admin rights; ones from uninstalled apps can remain here.",
   "tr": "Uygulamaların yönetici haklarıyla çalışmak için yüklediği yardımcı programlar; kaldırılan uygulamalarınkiler burada kalabilir.",
   "es": "Programas auxiliares que las apps instalan para funcionar con permisos de administrador; pueden quedar los de apps desinstaladas.",
   "de": "Hilfsprogramme, die Apps für Admin-Rechte installieren; die deinstallierter Apps können hier zurückbleiben."
  },
  "by": "macOS",
  "safety": "review"
 },
 {
  "match": [
   "/Library/Printers"
  ],
  "title": {
   "en": "Printer drivers",
   "tr": "Yazıcı sürücüleri",
   "es": "Controladores de impresora",
   "de": "Druckertreiber"
  },
  "what": {
   "en": "Drivers for printers and scanners; drivers for devices you no longer own can take up space.",
   "tr": "Yazıcı ve tarayıcı sürücüleri; artık sahip olmadığınız aygıtların sürücüleri yer kaplayabilir.",
   "es": "Controladores de impresoras y escáneres; los de dispositivos que ya no tienes pueden ocupar espacio.",
   "de": "Treiber für Drucker und Scanner; Treiber für Geräte, die du nicht mehr hast, belegen unnötig Platz."
  },
  "by": "macOS",
  "safety": "review"
 },
 {
  "match": [
   "/Library/Java/JavaVirtualMachines"
  ],
  "title": {
   "en": "Java installations (JDKs)",
   "tr": "Java kurulumları (JDK)",
   "es": "Instalaciones de Java (JDK)",
   "de": "Java-Installationen (JDKs)"
  },
  "what": {
   "en": "Java Development Kits installed on this Mac; remove versions your apps and projects no longer use.",
   "tr": "Bu Mac'e yüklenmiş Java Geliştirme Kitleri; uygulamalarınızın ve projelerinizin artık kullanmadığı sürümleri kaldırın.",
   "es": "Kits de desarrollo de Java instalados en este Mac; elimina las versiones que ya no usen tus apps y proyectos.",
   "de": "Auf diesem Mac installierte Java Development Kits; entferne Versionen, die deine Apps und Projekte nicht mehr nutzen."
  },
  "by": "Java",
  "safety": "review"
 },
 {
  "match": [
   "/Library/Audio/Apple Loops"
  ],
  "title": {
   "en": "Apple Loops",
   "tr": "Apple Loops",
   "es": "Apple Loops",
   "de": "Apple Loops"
  },
  "what": {
   "en": "Loops downloaded for GarageBand and Logic Pro; you can download them again from the app's Sound Library.",
   "tr": "GarageBand ve Logic Pro için indirilen loop'lar; uygulamanın Ses Kitaplığı'ndan yeniden indirebilirsiniz.",
   "es": "Loops descargados para GarageBand y Logic Pro; puedes volver a descargarlos desde la biblioteca de sonidos de la app.",
   "de": "Für GarageBand und Logic Pro geladene Loops; du kannst sie über die Soundbibliothek der App erneut laden."
  },
  "by": "Apple GarageBand / Logic Pro",
  "safety": "review"
 },
 {
  "match": [
   "/Library/Application Support/GarageBand",
   "/Library/Application Support/Logic"
  ],
  "title": {
   "en": "GarageBand/Logic sound library",
   "tr": "GarageBand/Logic ses kitaplığı",
   "es": "Biblioteca de sonidos de GarageBand/Logic",
   "de": "GarageBand/Logic-Soundbibliothek"
  },
  "what": {
   "en": "Instruments and sounds downloaded by GarageBand or Logic Pro; you can download them again from the app's Sound Library.",
   "tr": "GarageBand veya Logic Pro'nun indirdiği enstrümanlar ve sesler; uygulamanın Ses Kitaplığı'ndan yeniden indirebilirsiniz.",
   "es": "Instrumentos y sonidos descargados por GarageBand o Logic Pro; puedes volver a descargarlos desde su biblioteca de sonidos.",
   "de": "Von GarageBand oder Logic Pro geladene Instrumente und Sounds; du kannst sie über die Soundbibliothek erneut laden."
  },
  "by": "Apple GarageBand / Logic Pro",
  "safety": "review"
 },
 {
  "match": [
   "/Library/Application Support/com.apple.idleassetsd"
  ],
  "title": {
   "en": "Aerial wallpapers",
   "tr": "Hava görüntüsü duvar kâğıtları",
   "es": "Fondos aéreos",
   "de": "Luftaufnahmen-Hintergründe"
  },
  "what": {
   "en": "Aerial videos downloaded for wallpapers and screen savers; macOS downloads them again when you choose one.",
   "tr": "Duvar kâğıtları ve ekran koruyucular için indirilen hava çekimi videolar; birini seçtiğinizde macOS yeniden indirir.",
   "es": "Vídeos aéreos descargados para fondos y salvapantallas; macOS los vuelve a descargar cuando eliges uno.",
   "de": "Für Hintergrundbilder und Bildschirmschoner geladene Luftaufnahmen; macOS lädt sie erneut, wenn du eine auswählst."
  },
  "by": "macOS",
  "safety": "regenerates"
 },
 {
  "match": [
   "/Volumes/*/.Trashes"
  ],
  "title": {
   "en": "Trash on this drive",
   "tr": "Bu sürücüdeki Çöp Sepeti",
   "es": "Papelera de este disco",
   "de": "Papierkorb auf diesem Laufwerk"
  },
  "what": {
   "en": "Items you moved to the Trash from this external drive; they still take space here until you empty the Trash.",
   "tr": "Bu harici sürücüden Çöp Sepeti'ne taşıdığınız öğeler; Çöp Sepeti'ni boşaltana kadar burada yer kaplamaya devam eder.",
   "es": "Elementos que moviste a la Papelera desde este disco externo; siguen ocupando espacio aquí hasta que vacíes la Papelera.",
   "de": "Objekte, die du von diesem externen Laufwerk in den Papierkorb gelegt hast; sie belegen Platz, bis du den Papierkorb leerst."
  },
  "by": "macOS",
  "safety": "review",
  "category": "trash"
 },
 {
  "match": [
   "/opt/homebrew"
  ],
  "title": {
   "en": "Homebrew (Apple silicon)",
   "tr": "Homebrew (Apple silicon)",
   "es": "Homebrew (Apple silicon)",
   "de": "Homebrew (Apple silicon)"
  },
  "what": {
   "en": "Homebrew and the tools and apps you installed with it; use “brew uninstall” and “brew cleanup” instead of deleting.",
   "tr": "Homebrew ve onunla yüklediğiniz araçlar ve uygulamalar; silmek yerine “brew uninstall” ve “brew cleanup” kullanın.",
   "es": "Homebrew y las herramientas y apps que instalaste con él; usa “brew uninstall” y “brew cleanup” en lugar de borrar.",
   "de": "Homebrew und die damit installierten Tools und Apps; nutze „brew uninstall“ und „brew cleanup“ statt zu löschen."
  },
  "by": "Homebrew",
  "safety": "keep"
 },
 {
  "match": [
   "/opt/homebrew/Cellar",
   "/usr/local/Cellar"
  ],
  "title": {
   "en": "Homebrew packages",
   "tr": "Homebrew paketleri",
   "es": "Paquetes de Homebrew",
   "de": "Homebrew-Pakete"
  },
  "what": {
   "en": "Installed Homebrew formulae, one folder per version; “brew cleanup” removes outdated versions safely.",
   "tr": "Yüklü Homebrew paketleri, her sürüm için bir klasör; “brew cleanup” eski sürümleri güvenle kaldırır.",
   "es": "Fórmulas de Homebrew instaladas, una carpeta por versión; “brew cleanup” elimina las versiones antiguas de forma segura.",
   "de": "Installierte Homebrew-Formeln, ein Ordner pro Version; „brew cleanup“ entfernt veraltete Versionen sicher."
  },
  "by": "Homebrew",
  "safety": "keep",
  "category": "devtools"
 },
 {
  "match": [
   "/opt/homebrew/Caskroom",
   "/usr/local/Caskroom"
  ],
  "title": {
   "en": "Homebrew casks",
   "tr": "Homebrew cask'leri",
   "es": "Casks de Homebrew",
   "de": "Homebrew-Casks"
  },
  "what": {
   "en": "Records and files of apps installed with “brew install --cask”; remove apps with “brew uninstall”.",
   "tr": "“brew install --cask” ile yüklenen uygulamaların kayıtları ve dosyaları; uygulamaları “brew uninstall” ile kaldırın.",
   "es": "Registros y archivos de apps instaladas con “brew install --cask”; elimínalas con “brew uninstall”.",
   "de": "Einträge und Dateien von mit „brew install --cask“ installierten Apps; entferne Apps mit „brew uninstall“."
  },
  "by": "Homebrew",
  "safety": "keep"
 },
 {
  "match": [
   "/opt/homebrew/var",
   "/usr/local/var"
  ],
  "title": {
   "en": "Homebrew service data",
   "tr": "Homebrew hizmet verileri",
   "es": "Datos de servicios de Homebrew",
   "de": "Homebrew-Dienstdaten"
  },
  "what": {
   "en": "Data of services installed with Homebrew, such as PostgreSQL, MySQL or Redis databases; deleting loses that data.",
   "tr": "PostgreSQL, MySQL veya Redis veritabanları gibi Homebrew ile yüklenen hizmetlerin verileri; silmek bu verileri kaybettirir.",
   "es": "Datos de servicios instalados con Homebrew, como bases de datos PostgreSQL, MySQL o Redis; borrarlos los pierde.",
   "de": "Daten von mit Homebrew installierten Diensten wie PostgreSQL-, MySQL- oder Redis-Datenbanken; Löschen vernichtet sie."
  },
  "by": "Homebrew",
  "safety": "keep"
 },
 {
  "match": [
   "/usr/local/Homebrew"
  ],
  "title": {
   "en": "Homebrew (Intel)",
   "tr": "Homebrew (Intel)",
   "es": "Homebrew (Intel)",
   "de": "Homebrew (Intel)"
  },
  "what": {
   "en": "Homebrew's own code on Intel Macs; manage it with brew commands rather than deleting.",
   "tr": "Intel Mac'lerde Homebrew'un kendi kodu; silmek yerine brew komutlarıyla yönetin.",
   "es": "El código de Homebrew en Macs con Intel; gestiónalo con comandos brew en lugar de borrarlo.",
   "de": "Homebrews eigener Code auf Intel-Macs; verwalte ihn mit brew-Befehlen statt zu löschen."
  },
  "by": "Homebrew",
  "safety": "keep"
 },
 {
  "match": [
   "/usr/local"
  ],
  "title": {
   "en": "Local programs (/usr/local)",
   "tr": "Yerel programlar (/usr/local)",
   "es": "Programas locales (/usr/local)",
   "de": "Lokale Programme (/usr/local)"
  },
  "what": {
   "en": "Programs installed outside the App Store, including Homebrew on Intel Macs; deleting breaks those tools.",
   "tr": "App Store dışından yüklenen programlar, Intel Mac'lerde Homebrew dahil; silmek bu araçları bozar.",
   "es": "Programas instalados fuera del App Store, incluido Homebrew en Macs con Intel; borrarlos rompe esas herramientas.",
   "de": "Außerhalb des App Store installierte Programme, auf Intel-Macs auch Homebrew; Löschen macht diese Tools unbrauchbar."
  },
  "by": "Unix / Homebrew",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Caches/Homebrew"
  ],
  "title": {
   "en": "Homebrew download cache",
   "tr": "Homebrew indirme önbelleği",
   "es": "Caché de descargas de Homebrew",
   "de": "Homebrew-Download-Cache"
  },
  "what": {
   "en": "Packages and source archives Homebrew downloaded; “brew cleanup” trims it, and Homebrew downloads again if needed.",
   "tr": "Homebrew'un indirdiği paketler ve kaynak arşivleri; “brew cleanup” küçültür, Homebrew gerekirse yeniden indirir.",
   "es": "Paquetes y archivos de código que descargó Homebrew; “brew cleanup” lo reduce y Homebrew vuelve a descargar si hace falta.",
   "de": "Von Homebrew geladene Pakete und Quellarchive; „brew cleanup“ verkleinert ihn, Homebrew lädt bei Bedarf neu."
  },
  "by": "Homebrew",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Logs/Homebrew"
  ],
  "title": {
   "en": "Homebrew logs",
   "tr": "Homebrew günlükleri",
   "es": "Registros de Homebrew",
   "de": "Homebrew-Protokolle"
  },
  "what": {
   "en": "Build logs from Homebrew installs; only useful if an install failed.",
   "tr": "Homebrew kurulumlarının derleme günlükleri; yalnızca bir kurulum başarısız olduysa işe yarar.",
   "es": "Registros de compilación de instalaciones de Homebrew; solo sirven si falló alguna instalación.",
   "de": "Build-Protokolle von Homebrew-Installationen; nur nützlich, wenn eine Installation fehlgeschlagen ist."
  },
  "by": "Homebrew",
  "safety": "safe",
  "category": "logs"
 },
 {
  "match": [
   "~/.npm"
  ],
  "title": {
   "en": "npm cache",
   "tr": "npm önbelleği",
   "es": "Caché de npm",
   "de": "npm-Cache"
  },
  "what": {
   "en": "Packages npm downloaded, plus npx tools and logs; npm downloads them again on the next install.",
   "tr": "npm'in indirdiği paketler, npx araçları ve günlükler; npm bir sonraki kurulumda yeniden indirir.",
   "es": "Paquetes descargados por npm, además de herramientas de npx y registros; npm los vuelve a descargar en la siguiente instalación.",
   "de": "Von npm geladene Pakete sowie npx-Tools und Protokolle; npm lädt sie bei der nächsten Installation erneut."
  },
  "by": "npm",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Caches/Yarn"
  ],
  "title": {
   "en": "Yarn cache",
   "tr": "Yarn önbelleği",
   "es": "Caché de Yarn",
   "de": "Yarn-Cache"
  },
  "what": {
   "en": "Packages Yarn 1 downloaded for your projects; Yarn downloads them again when needed.",
   "tr": "Yarn 1'in projeleriniz için indirdiği paketler; Yarn gerektiğinde yeniden indirir.",
   "es": "Paquetes que Yarn 1 descargó para tus proyectos; Yarn los vuelve a descargar cuando hacen falta.",
   "de": "Von Yarn 1 für deine Projekte geladene Pakete; Yarn lädt sie bei Bedarf erneut."
  },
  "by": "Yarn",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.yarn"
  ],
  "title": {
   "en": "Yarn home",
   "tr": "Yarn ana klasörü",
   "es": "Carpeta de Yarn",
   "de": "Yarn-Ordner"
  },
  "what": {
   "en": "Yarn's global folder with cached packages and globally installed tools.",
   "tr": "Önbelleğe alınmış paketler ve genel olarak yüklenmiş araçlarla Yarn'ın genel klasörü.",
   "es": "La carpeta global de Yarn, con paquetes en caché y herramientas instaladas globalmente.",
   "de": "Yarns globaler Ordner mit zwischengespeicherten Paketen und global installierten Tools."
  },
  "by": "Yarn",
  "safety": "review"
 },
 {
  "match": [
   "~/.yarn/berry/cache"
  ],
  "title": {
   "en": "Yarn global cache",
   "tr": "Yarn genel önbelleği",
   "es": "Caché global de Yarn",
   "de": "Globaler Yarn-Cache"
  },
  "what": {
   "en": "Package archives shared by projects using modern Yarn; Yarn downloads them again on the next install.",
   "tr": "Modern Yarn kullanan projelerin paylaştığı paket arşivleri; Yarn bir sonraki kurulumda yeniden indirir.",
   "es": "Archivos de paquetes compartidos por proyectos con Yarn moderno; Yarn los vuelve a descargar en la siguiente instalación.",
   "de": "Paketarchive, die Projekte mit modernem Yarn teilen; Yarn lädt sie bei der nächsten Installation erneut."
  },
  "by": "Yarn",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/pnpm/store",
   "~/.pnpm-store"
  ],
  "title": {
   "en": "pnpm store",
   "tr": "pnpm deposu",
   "es": "Almacén de pnpm",
   "de": "pnpm-Store"
  },
  "what": {
   "en": "The shared package store pnpm links into your projects; “pnpm store prune” trims it, and pnpm downloads missing packages again.",
   "tr": "pnpm'in projelerinize bağladığı ortak paket deposu; “pnpm store prune” küçültür, pnpm eksik paketleri yeniden indirir.",
   "es": "El almacén de paquetes que pnpm enlaza en tus proyectos; “pnpm store prune” lo reduce y pnpm vuelve a descargar lo que falte.",
   "de": "Der gemeinsame Paketspeicher, den pnpm in Projekte verlinkt; „pnpm store prune“ verkleinert ihn, fehlende Pakete lädt pnpm neu."
  },
  "by": "pnpm",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.bun"
  ],
  "title": {
   "en": "Bun",
   "tr": "Bun",
   "es": "Bun",
   "de": "Bun"
  },
  "what": {
   "en": "The Bun runtime itself plus its global packages and cache; deleting removes Bun.",
   "tr": "Bun çalışma ortamının kendisi, genel paketleri ve önbelleği; silmek Bun'ı kaldırır.",
   "es": "El propio entorno Bun con sus paquetes globales y su caché; borrarlo elimina Bun.",
   "de": "Die Bun-Laufzeit selbst mit globalen Paketen und Cache; Löschen entfernt Bun."
  },
  "by": "Bun",
  "safety": "keep"
 },
 {
  "match": [
   "~/.bun/install/cache"
  ],
  "title": {
   "en": "Bun cache",
   "tr": "Bun önbelleği",
   "es": "Caché de Bun",
   "de": "Bun-Cache"
  },
  "what": {
   "en": "Packages Bun downloaded for your projects; Bun downloads them again on the next install.",
   "tr": "Bun'ın projeleriniz için indirdiği paketler; Bun bir sonraki kurulumda yeniden indirir.",
   "es": "Paquetes que Bun descargó para tus proyectos; Bun los vuelve a descargar en la siguiente instalación.",
   "de": "Von Bun für deine Projekte geladene Pakete; Bun lädt sie bei der nächsten Installation erneut."
  },
  "by": "Bun",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.deno"
  ],
  "title": {
   "en": "Deno",
   "tr": "Deno",
   "es": "Deno",
   "de": "Deno"
  },
  "what": {
   "en": "The Deno program and tools installed with “deno install”; deleting removes them.",
   "tr": "Deno programı ve “deno install” ile yüklenen araçlar; silmek bunları kaldırır.",
   "es": "El programa Deno y las herramientas instaladas con “deno install”; borrarlo las elimina.",
   "de": "Das Deno-Programm und mit „deno install“ installierte Tools; Löschen entfernt sie."
  },
  "by": "Deno",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Caches/deno"
  ],
  "title": {
   "en": "Deno cache",
   "tr": "Deno önbelleği",
   "es": "Caché de Deno",
   "de": "Deno-Cache"
  },
  "what": {
   "en": "Modules and npm packages Deno downloaded and compiled; Deno fetches them again on the next run.",
   "tr": "Deno'nun indirip derlediği modüller ve npm paketleri; Deno bir sonraki çalıştırmada yeniden alır.",
   "es": "Módulos y paquetes npm que Deno descargó y compiló; Deno los vuelve a obtener en la siguiente ejecución.",
   "de": "Von Deno geladene und kompilierte Module und npm-Pakete; Deno holt sie beim nächsten Lauf erneut."
  },
  "by": "Deno",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.nvm"
  ],
  "title": {
   "en": "nvm Node.js versions",
   "tr": "nvm Node.js sürümleri",
   "es": "Versiones de Node.js de nvm",
   "de": "nvm-Node.js-Versionen"
  },
  "what": {
   "en": "Node.js versions installed with nvm, each with its global packages; remove unused ones with “nvm uninstall”.",
   "tr": "nvm ile yüklenmiş Node.js sürümleri, her biri genel paketleriyle; kullanmadıklarınızı “nvm uninstall” ile kaldırın.",
   "es": "Versiones de Node.js instaladas con nvm, cada una con sus paquetes globales; elimina las que no uses con “nvm uninstall”.",
   "de": "Mit nvm installierte Node.js-Versionen samt globaler Pakete; entferne ungenutzte mit „nvm uninstall“."
  },
  "by": "nvm",
  "safety": "review"
 },
 {
  "match": [
   "~/.volta"
  ],
  "title": {
   "en": "Volta toolchains",
   "tr": "Volta araç zincirleri",
   "es": "Herramientas de Volta",
   "de": "Volta-Toolchains"
  },
  "what": {
   "en": "Node.js, npm and Yarn versions and tools managed by Volta; deleting removes them and Volta itself.",
   "tr": "Volta'nın yönettiği Node.js, npm ve Yarn sürümleri ile araçlar; silmek bunları ve Volta'nın kendisini kaldırır.",
   "es": "Versiones de Node.js, npm y Yarn y herramientas que gestiona Volta; borrarlo las elimina junto con Volta.",
   "de": "Von Volta verwaltete Node.js-, npm- und Yarn-Versionen und Tools; Löschen entfernt sie samt Volta."
  },
  "by": "Volta",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Caches/node-gyp",
   "~/.node-gyp"
  ],
  "title": {
   "en": "node-gyp headers",
   "tr": "node-gyp başlık dosyaları",
   "es": "Cabeceras de node-gyp",
   "de": "node-gyp-Header"
  },
  "what": {
   "en": "Node.js headers downloaded to build native npm modules; downloaded again on the next native build.",
   "tr": "Yerel npm modüllerini derlemek için indirilen Node.js başlık dosyaları; bir sonraki yerel derlemede yeniden indirilir.",
   "es": "Cabeceras de Node.js descargadas para compilar módulos nativos de npm; se vuelven a descargar en la siguiente compilación.",
   "de": "Node.js-Header zum Bauen nativer npm-Module; werden beim nächsten nativen Build erneut geladen."
  },
  "by": "node-gyp",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Caches/ms-playwright"
  ],
  "title": {
   "en": "Playwright browsers",
   "tr": "Playwright tarayıcıları",
   "es": "Navegadores de Playwright",
   "de": "Playwright-Browser"
  },
  "what": {
   "en": "Browser builds Playwright downloaded for testing, often several per version; reinstall with “npx playwright install”.",
   "tr": "Playwright'ın test için indirdiği tarayıcı sürümleri, çoğu zaman her sürüm için birkaç tane; “npx playwright install” ile yeniden yükleyin.",
   "es": "Navegadores que Playwright descargó para pruebas, a menudo varios por versión; reinstálalos con “npx playwright install”.",
   "de": "Von Playwright fürs Testen geladene Browser, oft mehrere pro Version; neu installieren mit „npx playwright install“."
  },
  "by": "Playwright",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Caches/Cypress"
  ],
  "title": {
   "en": "Cypress binaries",
   "tr": "Cypress dosyaları",
   "es": "Binarios de Cypress",
   "de": "Cypress-Binärdateien"
  },
  "what": {
   "en": "The Cypress test app, one copy per version you've installed; reinstalled with “npx cypress install”.",
   "tr": "Yüklediğiniz her sürüm için bir kopya olmak üzere Cypress test uygulaması; “npx cypress install” ile yeniden yüklenir.",
   "es": "La app de pruebas Cypress, una copia por versión instalada; se reinstala con “npx cypress install”.",
   "de": "Die Cypress-Test-App, eine Kopie pro installierter Version; neu installieren mit „npx cypress install“."
  },
  "by": "Cypress",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.cache/puppeteer"
  ],
  "title": {
   "en": "Puppeteer browsers",
   "tr": "Puppeteer tarayıcıları",
   "es": "Navegadores de Puppeteer",
   "de": "Puppeteer-Browser"
  },
  "what": {
   "en": "Chrome builds Puppeteer downloaded; they're downloaded again when you reinstall Puppeteer in a project.",
   "tr": "Puppeteer'ın indirdiği Chrome sürümleri; bir projede Puppeteer'ı yeniden yüklediğinizde tekrar indirilir.",
   "es": "Versiones de Chrome que descargó Puppeteer; se vuelven a descargar al reinstalar Puppeteer en un proyecto.",
   "de": "Von Puppeteer geladene Chrome-Versionen; sie werden beim erneuten Installieren von Puppeteer im Projekt geladen."
  },
  "by": "Puppeteer",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Caches/electron"
  ],
  "title": {
   "en": "Electron downloads",
   "tr": "Electron indirmeleri",
   "es": "Descargas de Electron",
   "de": "Electron-Downloads"
  },
  "what": {
   "en": "Electron releases downloaded while installing or packaging Electron apps; downloaded again when needed.",
   "tr": "Electron uygulamalarını kurarken veya paketlerken indirilen Electron sürümleri; gerektiğinde yeniden indirilir.",
   "es": "Versiones de Electron descargadas al instalar o empaquetar apps Electron; se vuelven a descargar si hace falta.",
   "de": "Beim Installieren oder Paketieren von Electron-Apps geladene Electron-Versionen; werden bei Bedarf erneut geladen."
  },
  "by": "Electron",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Caches/typescript"
  ],
  "title": {
   "en": "TypeScript typings cache",
   "tr": "TypeScript tür önbelleği",
   "es": "Caché de tipos de TypeScript",
   "de": "TypeScript-Typings-Cache"
  },
  "what": {
   "en": "Type definitions your editor's TypeScript service downloaded for JavaScript projects; downloaded again when needed.",
   "tr": "Düzenleyicinizin TypeScript hizmetinin JavaScript projeleri için indirdiği tür tanımları; gerektiğinde yeniden indirilir.",
   "es": "Definiciones de tipos que el servicio de TypeScript de tu editor descargó para proyectos JavaScript; se vuelven a descargar.",
   "de": "Typdefinitionen, die der TypeScript-Dienst deines Editors für JavaScript-Projekte lädt; bei Bedarf erneut geladen."
  },
  "by": "TypeScript",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.cache/node/corepack"
  ],
  "title": {
   "en": "Corepack cache",
   "tr": "Corepack önbelleği",
   "es": "Caché de Corepack",
   "de": "Corepack-Cache"
  },
  "what": {
   "en": "Yarn and pnpm versions Corepack downloaded for your projects; downloaded again on first use.",
   "tr": "Corepack'in projeleriniz için indirdiği Yarn ve pnpm sürümleri; ilk kullanımda yeniden indirilir.",
   "es": "Versiones de Yarn y pnpm que Corepack descargó para tus proyectos; se vuelven a descargar al usarlas.",
   "de": "Von Corepack für deine Projekte geladene Yarn- und pnpm-Versionen; beim ersten Gebrauch erneut geladen."
  },
  "by": "Node.js Corepack",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.gradle"
  ],
  "title": {
   "en": "Gradle home",
   "tr": "Gradle ana klasörü",
   "es": "Carpeta de Gradle",
   "de": "Gradle-Ordner"
  },
  "what": {
   "en": "Gradle's caches, wrapper downloads and your gradle.properties, which may hold settings or credentials.",
   "tr": "Gradle önbellekleri, wrapper indirmeleri ve ayar veya kimlik bilgileri içerebilen gradle.properties dosyanız.",
   "es": "Cachés de Gradle, descargas del wrapper y tu gradle.properties, que puede contener ajustes o credenciales.",
   "de": "Gradle-Caches, Wrapper-Downloads und deine gradle.properties, die Einstellungen oder Zugangsdaten enthalten kann."
  },
  "by": "Gradle",
  "safety": "review"
 },
 {
  "match": [
   "~/.gradle/caches"
  ],
  "title": {
   "en": "Gradle cache",
   "tr": "Gradle önbelleği",
   "es": "Caché de Gradle",
   "de": "Gradle-Cache"
  },
  "what": {
   "en": "Dependencies and build caches Gradle downloaded; Gradle downloads them again on the next build.",
   "tr": "Gradle'ın indirdiği bağımlılıklar ve derleme önbellekleri; Gradle bir sonraki derlemede yeniden indirir.",
   "es": "Dependencias y cachés de compilación que descargó Gradle; Gradle las vuelve a descargar en la siguiente compilación.",
   "de": "Von Gradle geladene Abhängigkeiten und Build-Caches; Gradle lädt sie beim nächsten Build erneut."
  },
  "by": "Gradle",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.gradle/wrapper/dists"
  ],
  "title": {
   "en": "Gradle wrapper distributions",
   "tr": "Gradle wrapper dağıtımları",
   "es": "Distribuciones del wrapper de Gradle",
   "de": "Gradle-Wrapper-Distributionen"
  },
  "what": {
   "en": "Full Gradle versions downloaded by projects' wrappers, about 100–200 MB each; downloaded again on the next build.",
   "tr": "Projelerin wrapper'larının indirdiği tam Gradle sürümleri, her biri yaklaşık 100–200 MB; bir sonraki derlemede yeniden indirilir.",
   "es": "Versiones completas de Gradle descargadas por el wrapper de cada proyecto, de 100–200 MB; se descargan de nuevo al compilar.",
   "de": "Vollständige Gradle-Versionen aus den Wrappern der Projekte, je etwa 100–200 MB; beim nächsten Build erneut geladen."
  },
  "by": "Gradle",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.gradle/daemon"
  ],
  "title": {
   "en": "Gradle daemon logs",
   "tr": "Gradle daemon günlükleri",
   "es": "Registros del daemon de Gradle",
   "de": "Gradle-Daemon-Protokolle"
  },
  "what": {
   "en": "Logs and state of Gradle's background build processes; recreated on the next build.",
   "tr": "Gradle'ın arka plan derleme süreçlerinin günlükleri ve durumu; bir sonraki derlemede yeniden oluşturulur.",
   "es": "Registros y estado de los procesos de compilación en segundo plano de Gradle; se recrean en la siguiente compilación.",
   "de": "Protokolle und Status von Gradles Hintergrund-Buildprozessen; beim nächsten Build neu erstellt."
  },
  "by": "Gradle",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.m2"
  ],
  "title": {
   "en": "Maven home",
   "tr": "Maven ana klasörü",
   "es": "Carpeta de Maven",
   "de": "Maven-Ordner"
  },
  "what": {
   "en": "Maven's local repository and your settings.xml, which may hold repository settings or credentials.",
   "tr": "Maven'ın yerel deposu ve depo ayarları veya kimlik bilgileri içerebilen settings.xml dosyanız.",
   "es": "El repositorio local de Maven y tu settings.xml, que puede contener ajustes de repositorios o credenciales.",
   "de": "Mavens lokales Repository und deine settings.xml, die Repository-Einstellungen oder Zugangsdaten enthalten kann."
  },
  "by": "Apache Maven",
  "safety": "review"
 },
 {
  "match": [
   "~/.m2/repository"
  ],
  "title": {
   "en": "Maven repository",
   "tr": "Maven deposu",
   "es": "Repositorio de Maven",
   "de": "Maven-Repository"
  },
  "what": {
   "en": "Libraries Maven downloaded for your builds; Maven downloads them again on the next build.",
   "tr": "Maven'ın derlemeleriniz için indirdiği kitaplıklar; Maven bir sonraki derlemede yeniden indirir.",
   "es": "Bibliotecas que Maven descargó para tus compilaciones; las vuelve a descargar en la siguiente.",
   "de": "Von Maven für deine Builds geladene Bibliotheken; Maven lädt sie beim nächsten Build erneut."
  },
  "by": "Apache Maven",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.ivy2"
  ],
  "title": {
   "en": "Ivy home",
   "tr": "Ivy ana klasörü",
   "es": "Carpeta de Ivy",
   "de": "Ivy-Ordner"
  },
  "what": {
   "en": "Dependencies used by Ivy and older sbt builds, plus locally published artifacts and possibly credentials.",
   "tr": "Ivy ve eski sbt derlemelerinin kullandığı bağımlılıklar, yerel olarak yayımlanan yapıtlar ve olası kimlik bilgileri.",
   "es": "Dependencias de Ivy y de compilaciones sbt antiguas, artefactos publicados localmente y quizá credenciales.",
   "de": "Abhängigkeiten von Ivy und älteren sbt-Builds, lokal veröffentlichte Artefakte und eventuell Zugangsdaten."
  },
  "by": "Apache Ivy / sbt",
  "safety": "review"
 },
 {
  "match": [
   "~/.ivy2/cache"
  ],
  "title": {
   "en": "Ivy cache",
   "tr": "Ivy önbelleği",
   "es": "Caché de Ivy",
   "de": "Ivy-Cache"
  },
  "what": {
   "en": "Libraries downloaded by Ivy or older sbt versions; downloaded again on the next build.",
   "tr": "Ivy veya eski sbt sürümlerinin indirdiği kitaplıklar; bir sonraki derlemede yeniden indirilir.",
   "es": "Bibliotecas descargadas por Ivy o versiones antiguas de sbt; se vuelven a descargar en la siguiente compilación.",
   "de": "Von Ivy oder älteren sbt-Versionen geladene Bibliotheken; beim nächsten Build erneut geladen."
  },
  "by": "Apache Ivy / sbt",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.sbt"
  ],
  "title": {
   "en": "sbt home",
   "tr": "sbt ana klasörü",
   "es": "Carpeta de sbt",
   "de": "sbt-Ordner"
  },
  "what": {
   "en": "sbt's launcher files, global plugins and settings; caches inside are rebuilt, but global settings are yours.",
   "tr": "sbt'nin başlatıcı dosyaları, genel eklentileri ve ayarları; içindeki önbellekler yeniden oluşur ama genel ayarlar sizindir.",
   "es": "Archivos del lanzador de sbt, plugins globales y ajustes; las cachés se regeneran, pero los ajustes globales son tuyos.",
   "de": "Startdateien, globale Plugins und Einstellungen von sbt; Caches darin entstehen neu, globale Einstellungen aber nicht."
  },
  "by": "sbt",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Caches/Coursier"
  ],
  "title": {
   "en": "Coursier cache",
   "tr": "Coursier önbelleği",
   "es": "Caché de Coursier",
   "de": "Coursier-Cache"
  },
  "what": {
   "en": "JVM libraries downloaded by Coursier for sbt, Mill or Scala CLI; downloaded again on the next build.",
   "tr": "Coursier'in sbt, Mill veya Scala CLI için indirdiği JVM kitaplıkları; bir sonraki derlemede yeniden indirilir.",
   "es": "Bibliotecas JVM que Coursier descargó para sbt, Mill o Scala CLI; se vuelven a descargar en la siguiente compilación.",
   "de": "Von Coursier für sbt, Mill oder Scala CLI geladene JVM-Bibliotheken; beim nächsten Build erneut geladen."
  },
  "by": "Coursier",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.konan"
  ],
  "title": {
   "en": "Kotlin/Native toolchain",
   "tr": "Kotlin/Native araç zinciri",
   "es": "Herramientas de Kotlin/Native",
   "de": "Kotlin/Native-Toolchain"
  },
  "what": {
   "en": "Compilers and dependencies Kotlin/Native downloads for multiplatform builds; downloaded again on the next build.",
   "tr": "Kotlin/Native'in çoklu platform derlemeleri için indirdiği derleyiciler ve bağımlılıklar; bir sonraki derlemede yeniden indirilir.",
   "es": "Compiladores y dependencias que Kotlin/Native descarga para compilaciones multiplataforma; se descargan de nuevo al compilar.",
   "de": "Compiler und Abhängigkeiten, die Kotlin/Native für Multiplattform-Builds lädt; beim nächsten Build erneut geladen."
  },
  "by": "Kotlin/Native",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.sdkman"
  ],
  "title": {
   "en": "SDKMAN! candidates",
   "tr": "SDKMAN! adayları",
   "es": "Candidatos de SDKMAN!",
   "de": "SDKMAN!-Kandidaten"
  },
  "what": {
   "en": "JDKs and JVM tools installed with SDKMAN!; remove unused versions with “sdk uninstall”.",
   "tr": "SDKMAN! ile yüklenen JDK'lar ve JVM araçları; kullanmadığınız sürümleri “sdk uninstall” ile kaldırın.",
   "es": "JDK y herramientas JVM instaladas con SDKMAN!; elimina las versiones que no uses con “sdk uninstall”.",
   "de": "Mit SDKMAN! installierte JDKs und JVM-Tools; entferne ungenutzte Versionen mit „sdk uninstall“."
  },
  "by": "SDKMAN!",
  "safety": "review"
 },
 {
  "match": [
   "~/.cargo"
  ],
  "title": {
   "en": "Cargo home",
   "tr": "Cargo ana klasörü",
   "es": "Carpeta de Cargo",
   "de": "Cargo-Ordner"
  },
  "what": {
   "en": "Cargo's binaries, including rustup's commands and tools from “cargo install”, plus its download caches.",
   "tr": "rustup komutları ve “cargo install” ile kurulan araçlar dahil Cargo'nun programları ile indirme önbellekleri.",
   "es": "Los binarios de Cargo, incluidos los comandos de rustup y las herramientas de “cargo install”, y sus cachés de descargas.",
   "de": "Cargos Programme inklusive der rustup-Befehle und mit „cargo install“ installierter Tools sowie Download-Caches."
  },
  "by": "Rust (Cargo)",
  "safety": "keep"
 },
 {
  "match": [
   "~/.cargo/registry",
   "~/.cargo/git"
  ],
  "title": {
   "en": "Cargo cache",
   "tr": "Cargo önbelleği",
   "es": "Caché de Cargo",
   "de": "Cargo-Cache"
  },
  "what": {
   "en": "Crates and git dependencies Cargo downloaded; Cargo downloads them again on the next build.",
   "tr": "Cargo'nun indirdiği crate'ler ve git bağımlılıkları; Cargo bir sonraki derlemede yeniden indirir.",
   "es": "Crates y dependencias git que descargó Cargo; Cargo las vuelve a descargar en la siguiente compilación.",
   "de": "Von Cargo geladene Crates und Git-Abhängigkeiten; Cargo lädt sie beim nächsten Build erneut."
  },
  "by": "Rust (Cargo)",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.rustup"
  ],
  "title": {
   "en": "Rust toolchains (rustup)",
   "tr": "Rust araç zincirleri (rustup)",
   "es": "Toolchains de Rust (rustup)",
   "de": "Rust-Toolchains (rustup)"
  },
  "what": {
   "en": "Rust compilers and components managed by rustup; deleting breaks Rust until reinstalled.",
   "tr": "rustup'ın yönettiği Rust derleyicileri ve bileşenleri; silmek Rust'ı yeniden kurulana kadar bozar.",
   "es": "Compiladores y componentes de Rust gestionados por rustup; borrarlo rompe Rust hasta reinstalarlo.",
   "de": "Von rustup verwaltete Rust-Compiler und Komponenten; Löschen macht Rust bis zur Neuinstallation unbrauchbar."
  },
  "by": "rustup",
  "safety": "keep"
 },
 {
  "match": [
   "~/.rustup/toolchains"
  ],
  "title": {
   "en": "Installed Rust toolchains",
   "tr": "Yüklü Rust araç zincirleri",
   "es": "Toolchains de Rust instalados",
   "de": "Installierte Rust-Toolchains"
  },
  "what": {
   "en": "One folder per Rust toolchain, often 1+ GB each; remove old ones with “rustup toolchain uninstall”.",
   "tr": "Her Rust araç zinciri için bir klasör, genellikle 1 GB'tan büyük; eskileri “rustup toolchain uninstall” ile kaldırın.",
   "es": "Una carpeta por toolchain de Rust, a menudo de más de 1 GB; elimina los antiguos con “rustup toolchain uninstall”.",
   "de": "Ein Ordner pro Rust-Toolchain, oft über 1 GB; entferne alte mit „rustup toolchain uninstall“."
  },
  "by": "rustup",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Caches/go-build"
  ],
  "title": {
   "en": "Go build cache",
   "tr": "Go derleme önbelleği",
   "es": "Caché de compilación de Go",
   "de": "Go-Build-Cache"
  },
  "what": {
   "en": "Compiled Go packages reused between builds; “go clean -cache” empties it, and the next build recompiles.",
   "tr": "Derlemeler arasında yeniden kullanılan derlenmiş Go paketleri; “go clean -cache” boşaltır, sonraki derleme yeniden derler.",
   "es": "Paquetes de Go compilados que se reutilizan entre compilaciones; “go clean -cache” lo vacía y la siguiente recompila.",
   "de": "Zwischen Builds wiederverwendete kompilierte Go-Pakete; „go clean -cache“ leert ihn, der nächste Build kompiliert neu."
  },
  "by": "Go",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/go"
  ],
  "title": {
   "en": "Go workspace (GOPATH)",
   "tr": "Go çalışma alanı (GOPATH)",
   "es": "Espacio de trabajo de Go (GOPATH)",
   "de": "Go-Arbeitsbereich (GOPATH)"
  },
  "what": {
   "en": "Go's default GOPATH with downloaded modules, tools from “go install” and, in older setups, your own code.",
   "tr": "İndirilen modüller, “go install” ile kurulan araçlar ve eski kurulumlarda kendi kodunuzla Go'nun varsayılan GOPATH'i.",
   "es": "El GOPATH por defecto de Go, con módulos descargados, herramientas de “go install” y, en configuraciones antiguas, tu código.",
   "de": "Gos Standard-GOPATH mit geladenen Modulen, Tools aus „go install“ und bei älteren Setups deinem eigenen Code."
  },
  "by": "Go",
  "safety": "review"
 },
 {
  "match": [
   "~/go/pkg/mod"
  ],
  "title": {
   "en": "Go module cache",
   "tr": "Go modül önbelleği",
   "es": "Caché de módulos de Go",
   "de": "Go-Modul-Cache"
  },
  "what": {
   "en": "Modules Go downloaded for your projects; clear it with “go clean -modcache”, since the files are read-only.",
   "tr": "Go'nun projeleriniz için indirdiği modüller; dosyalar salt okunur olduğundan “go clean -modcache” ile temizleyin.",
   "es": "Módulos que Go descargó para tus proyectos; vacíala con “go clean -modcache”, ya que los archivos son de solo lectura.",
   "de": "Von Go für deine Projekte geladene Module; leere ihn mit „go clean -modcache“, da die Dateien schreibgeschützt sind."
  },
  "by": "Go",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.swiftpm"
  ],
  "title": {
   "en": "SwiftPM settings",
   "tr": "SwiftPM ayarları",
   "es": "Ajustes de SwiftPM",
   "de": "SwiftPM-Einstellungen"
  },
  "what": {
   "en": "Swift Package Manager settings such as mirrors, registries and package fingerprints.",
   "tr": "Yansılar, kayıt defterleri ve paket parmak izleri gibi Swift Package Manager ayarları.",
   "es": "Ajustes de Swift Package Manager, como espejos, registros y huellas de paquetes.",
   "de": "Einstellungen des Swift Package Manager wie Mirrors, Registries und Paket-Fingerabdrücke."
  },
  "by": "Swift Package Manager",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Caches/org.swift.swiftpm"
  ],
  "title": {
   "en": "SwiftPM cache",
   "tr": "SwiftPM önbelleği",
   "es": "Caché de SwiftPM",
   "de": "SwiftPM-Cache"
  },
  "what": {
   "en": "Package repositories and artifacts SwiftPM and Xcode downloaded; downloaded again when packages resolve.",
   "tr": "SwiftPM ve Xcode'un indirdiği paket depoları ve yapıtları; paketler çözümlendiğinde yeniden indirilir.",
   "es": "Repositorios y artefactos de paquetes que descargaron SwiftPM y Xcode; se descargan de nuevo al resolver paquetes.",
   "de": "Von SwiftPM und Xcode geladene Paket-Repositories und Artefakte; beim Auflösen der Pakete erneut geladen."
  },
  "by": "Swift Package Manager",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.cocoapods"
  ],
  "title": {
   "en": "CocoaPods spec repos",
   "tr": "CocoaPods spec depoları",
   "es": "Repositorios de specs de CocoaPods",
   "de": "CocoaPods-Spec-Repos"
  },
  "what": {
   "en": "Clones of CocoaPods spec repositories; CocoaPods fetches them again on the next “pod install”.",
   "tr": "CocoaPods spec depolarının kopyaları; CocoaPods bir sonraki “pod install” işleminde yeniden alır.",
   "es": "Clones de los repositorios de specs de CocoaPods; CocoaPods los vuelve a obtener en el siguiente “pod install”.",
   "de": "Klone der CocoaPods-Spec-Repositories; CocoaPods holt sie beim nächsten „pod install“ erneut."
  },
  "by": "CocoaPods",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Caches/CocoaPods"
  ],
  "title": {
   "en": "CocoaPods cache",
   "tr": "CocoaPods önbelleği",
   "es": "Caché de CocoaPods",
   "de": "CocoaPods-Cache"
  },
  "what": {
   "en": "Pods CocoaPods downloaded for your projects; downloaded again on the next “pod install”.",
   "tr": "CocoaPods'un projeleriniz için indirdiği pod'lar; bir sonraki “pod install” işleminde yeniden indirilir.",
   "es": "Pods que CocoaPods descargó para tus proyectos; se vuelven a descargar en el siguiente “pod install”.",
   "de": "Von CocoaPods für deine Projekte geladene Pods; beim nächsten „pod install“ erneut geladen."
  },
  "by": "CocoaPods",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Caches/org.carthage.CarthageKit"
  ],
  "title": {
   "en": "Carthage cache",
   "tr": "Carthage önbelleği",
   "es": "Caché de Carthage",
   "de": "Carthage-Cache"
  },
  "what": {
   "en": "Dependency repositories and binaries Carthage downloaded; downloaded again on the next update or bootstrap.",
   "tr": "Carthage'ın indirdiği bağımlılık depoları ve ikili dosyalar; bir sonraki update veya bootstrap işleminde yeniden indirilir.",
   "es": "Repositorios y binarios de dependencias que descargó Carthage; se descargan de nuevo en el siguiente update o bootstrap.",
   "de": "Von Carthage geladene Abhängigkeits-Repositories und Binärdateien; beim nächsten Update oder Bootstrap erneut geladen."
  },
  "by": "Carthage",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.pub-cache"
  ],
  "title": {
   "en": "Dart pub cache",
   "tr": "Dart pub önbelleği",
   "es": "Caché de pub de Dart",
   "de": "Dart-pub-Cache"
  },
  "what": {
   "en": "Packages Dart and Flutter downloaded, plus globally activated tools; “pub get” downloads packages again.",
   "tr": "Dart ve Flutter'ın indirdiği paketler ve genel olarak etkinleştirilmiş araçlar; “pub get” paketleri yeniden indirir.",
   "es": "Paquetes que descargaron Dart y Flutter y herramientas activadas globalmente; “pub get” vuelve a descargar los paquetes.",
   "de": "Von Dart und Flutter geladene Pakete sowie global aktivierte Tools; „pub get“ lädt die Pakete erneut."
  },
  "by": "Dart / Flutter",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.gem"
  ],
  "title": {
   "en": "Ruby gems",
   "tr": "Ruby gem'leri",
   "es": "Gemas de Ruby",
   "de": "Ruby-Gems"
  },
  "what": {
   "en": "Ruby gems installed for your user account; deleting removes them until you install them again.",
   "tr": "Kullanıcı hesabınız için yüklenmiş Ruby gem'leri; silmek onları siz yeniden yükleyene kadar kaldırır.",
   "es": "Gemas de Ruby instaladas para tu cuenta; borrarlas las elimina hasta que las vuelvas a instalar.",
   "de": "Für deinen Account installierte Ruby-Gems; Löschen entfernt sie, bis du sie neu installierst."
  },
  "by": "RubyGems",
  "safety": "review"
 },
 {
  "match": [
   "~/.rbenv"
  ],
  "title": {
   "en": "rbenv Ruby versions",
   "tr": "rbenv Ruby sürümleri",
   "es": "Versiones de Ruby de rbenv",
   "de": "rbenv-Ruby-Versionen"
  },
  "what": {
   "en": "Ruby versions installed with rbenv, each with its gems; remove unused ones with “rbenv uninstall”.",
   "tr": "rbenv ile yüklenmiş Ruby sürümleri, her biri gem'leriyle; kullanmadıklarınızı “rbenv uninstall” ile kaldırın.",
   "es": "Versiones de Ruby instaladas con rbenv, cada una con sus gemas; elimina las que no uses con “rbenv uninstall”.",
   "de": "Mit rbenv installierte Ruby-Versionen samt Gems; entferne ungenutzte mit „rbenv uninstall“."
  },
  "by": "rbenv",
  "safety": "review"
 },
 {
  "match": [
   "~/.asdf"
  ],
  "title": {
   "en": "asdf tool versions",
   "tr": "asdf araç sürümleri",
   "es": "Versiones de herramientas de asdf",
   "de": "asdf-Tool-Versionen"
  },
  "what": {
   "en": "Language and tool versions installed with asdf; remove unused ones with “asdf uninstall”.",
   "tr": "asdf ile yüklenmiş dil ve araç sürümleri; kullanmadıklarınızı “asdf uninstall” ile kaldırın.",
   "es": "Versiones de lenguajes y herramientas instaladas con asdf; elimina las que no uses con “asdf uninstall”.",
   "de": "Mit asdf installierte Sprach- und Tool-Versionen; entferne ungenutzte mit „asdf uninstall“."
  },
  "by": "asdf",
  "safety": "review"
 },
 {
  "match": [
   "~/.stack"
  ],
  "title": {
   "en": "Haskell Stack",
   "tr": "Haskell Stack",
   "es": "Haskell Stack",
   "de": "Haskell Stack"
  },
  "what": {
   "en": "GHC compilers and package builds downloaded by Stack, plus its global config; Stack rebuilds them, which takes long.",
   "tr": "Stack'in indirdiği GHC derleyicileri ve paket derlemeleri ile genel yapılandırması; Stack yeniden oluşturur ama uzun sürer.",
   "es": "Compiladores GHC y paquetes compilados que descargó Stack, más su configuración global; Stack los regenera, pero tarda.",
   "de": "Von Stack geladene GHC-Compiler und Paket-Builds plus globale Konfiguration; Stack baut sie neu, was lange dauert."
  },
  "by": "Haskell Stack",
  "safety": "review",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.ghcup"
  ],
  "title": {
   "en": "GHCup Haskell tools",
   "tr": "GHCup Haskell araçları",
   "es": "Herramientas Haskell de GHCup",
   "de": "GHCup-Haskell-Tools"
  },
  "what": {
   "en": "GHC, Cabal and other Haskell tools installed with GHCup; remove unused versions with “ghcup rm”.",
   "tr": "GHCup ile yüklenmiş GHC, Cabal ve diğer Haskell araçları; kullanmadığınız sürümleri “ghcup rm” ile kaldırın.",
   "es": "GHC, Cabal y otras herramientas de Haskell instaladas con GHCup; elimina versiones sin uso con “ghcup rm”.",
   "de": "Mit GHCup installierte GHC-, Cabal- und andere Haskell-Tools; entferne ungenutzte Versionen mit „ghcup rm“."
  },
  "by": "GHCup",
  "safety": "review"
 },
 {
  "match": [
   "~/.hex"
  ],
  "title": {
   "en": "Hex home",
   "tr": "Hex ana klasörü",
   "es": "Carpeta de Hex",
   "de": "Hex-Ordner"
  },
  "what": {
   "en": "Elixir/Erlang packages cached by Hex plus its config, which may contain your API key.",
   "tr": "Hex'in önbelleğe aldığı Elixir/Erlang paketleri ve API anahtarınızı içerebilen yapılandırması.",
   "es": "Paquetes de Elixir/Erlang en caché de Hex y su configuración, que puede contener tu clave de API.",
   "de": "Von Hex zwischengespeicherte Elixir/Erlang-Pakete und seine Konfiguration, die deinen API-Schlüssel enthalten kann."
  },
  "by": "Hex (Elixir)",
  "safety": "review"
 },
 {
  "match": [
   "~/.hex/packages"
  ],
  "title": {
   "en": "Hex package cache",
   "tr": "Hex paket önbelleği",
   "es": "Caché de paquetes de Hex",
   "de": "Hex-Paketcache"
  },
  "what": {
   "en": "Packages Hex downloaded for Elixir and Erlang projects; downloaded again on the next “mix deps.get”.",
   "tr": "Hex'in Elixir ve Erlang projeleri için indirdiği paketler; bir sonraki “mix deps.get” işleminde yeniden indirilir.",
   "es": "Paquetes que Hex descargó para proyectos Elixir y Erlang; se descargan de nuevo en el siguiente “mix deps.get”.",
   "de": "Von Hex für Elixir- und Erlang-Projekte geladene Pakete; beim nächsten „mix deps.get“ erneut geladen."
  },
  "by": "Hex (Elixir)",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.julia"
  ],
  "title": {
   "en": "Julia depot",
   "tr": "Julia deposu",
   "es": "Depósito de Julia",
   "de": "Julia-Depot"
  },
  "what": {
   "en": "Julia packages, artifacts, registries and your global environments.",
   "tr": "Julia paketleri, yapıtlar, kayıt defterleri ve genel ortamlarınız.",
   "es": "Paquetes, artefactos y registros de Julia, además de tus entornos globales.",
   "de": "Julia-Pakete, Artefakte, Registries und deine globalen Umgebungen."
  },
  "by": "Julia",
  "safety": "review"
 },
 {
  "match": [
   "~/.julia/compiled"
  ],
  "title": {
   "en": "Julia precompile cache",
   "tr": "Julia ön derleme önbelleği",
   "es": "Caché de precompilación de Julia",
   "de": "Julia-Precompile-Cache"
  },
  "what": {
   "en": "Precompiled Julia packages; Julia recompiles them the next time you load a package, which is slower.",
   "tr": "Önceden derlenmiş Julia paketleri; bir paketi yüklediğinizde Julia yeniden derler, bu daha yavaştır.",
   "es": "Paquetes de Julia precompilados; Julia los recompila al cargar un paquete, lo que es más lento.",
   "de": "Vorkompilierte Julia-Pakete; Julia kompiliert sie beim nächsten Laden neu, was länger dauert."
  },
  "by": "Julia",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.composer"
  ],
  "title": {
   "en": "Composer home",
   "tr": "Composer ana klasörü",
   "es": "Carpeta de Composer",
   "de": "Composer-Ordner"
  },
  "what": {
   "en": "Composer's global packages and config, including auth.json with possible tokens.",
   "tr": "Olası belirteçler içeren auth.json dahil Composer'ın genel paketleri ve yapılandırması.",
   "es": "Paquetes globales y configuración de Composer, incluido auth.json con posibles tokens.",
   "de": "Composers globale Pakete und Konfiguration, inklusive auth.json mit möglichen Tokens."
  },
  "by": "Composer",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Caches/composer"
  ],
  "title": {
   "en": "Composer cache",
   "tr": "Composer önbelleği",
   "es": "Caché de Composer",
   "de": "Composer-Cache"
  },
  "what": {
   "en": "PHP packages Composer downloaded; downloaded again on the next “composer install”.",
   "tr": "Composer'ın indirdiği PHP paketleri; bir sonraki “composer install” işleminde yeniden indirilir.",
   "es": "Paquetes PHP que descargó Composer; se vuelven a descargar en el siguiente “composer install”.",
   "de": "Von Composer geladene PHP-Pakete; beim nächsten „composer install“ erneut geladen."
  },
  "by": "Composer",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.nuget/packages"
  ],
  "title": {
   "en": "NuGet packages",
   "tr": "NuGet paketleri",
   "es": "Paquetes de NuGet",
   "de": "NuGet-Pakete"
  },
  "what": {
   "en": "The global NuGet package folder used by .NET builds; packages are restored again on the next build.",
   "tr": ".NET derlemelerinin kullandığı genel NuGet paket klasörü; paketler bir sonraki derlemede yeniden geri yüklenir.",
   "es": "La carpeta global de paquetes NuGet que usan las compilaciones .NET; se restauran de nuevo en la siguiente compilación.",
   "de": "Der globale NuGet-Paketordner für .NET-Builds; Pakete werden beim nächsten Build wiederhergestellt."
  },
  "by": "NuGet",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.terraform.d"
  ],
  "title": {
   "en": "Terraform settings",
   "tr": "Terraform ayarları",
   "es": "Ajustes de Terraform",
   "de": "Terraform-Einstellungen"
  },
  "what": {
   "en": "Terraform CLI data, including saved login tokens and an optional plugin cache.",
   "tr": "Kayıtlı oturum belirteçleri ve isteğe bağlı eklenti önbelleği dahil Terraform CLI verileri.",
   "es": "Datos de la CLI de Terraform, incluidos tokens de inicio de sesión y una caché de plugins opcional.",
   "de": "Daten der Terraform-CLI inklusive gespeicherter Anmelde-Tokens und optionalem Plugin-Cache."
  },
  "by": "Terraform",
  "safety": "review"
 },
 {
  "match": [
   "~/.terraform.d/plugin-cache"
  ],
  "title": {
   "en": "Terraform plugin cache",
   "tr": "Terraform eklenti önbelleği",
   "es": "Caché de plugins de Terraform",
   "de": "Terraform-Plugin-Cache"
  },
  "what": {
   "en": "Provider plugins shared between Terraform projects; downloaded again on the next “terraform init”.",
   "tr": "Terraform projeleri arasında paylaşılan sağlayıcı eklentileri; bir sonraki “terraform init” işleminde yeniden indirilir.",
   "es": "Plugins de proveedores compartidos entre proyectos de Terraform; se descargan de nuevo en el siguiente “terraform init”.",
   "de": "Zwischen Terraform-Projekten geteilte Provider-Plugins; beim nächsten „terraform init“ erneut geladen."
  },
  "by": "Terraform",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Caches/helm"
  ],
  "title": {
   "en": "Helm cache",
   "tr": "Helm önbelleği",
   "es": "Caché de Helm",
   "de": "Helm-Cache"
  },
  "what": {
   "en": "Chart repository indexes and charts Helm downloaded; refreshed with “helm repo update”.",
   "tr": "Helm'in indirdiği chart depo dizinleri ve chart'lar; “helm repo update” ile yenilenir.",
   "es": "Índices de repositorios y charts que descargó Helm; se actualizan con “helm repo update”.",
   "de": "Von Helm geladene Chart-Repository-Indizes und Charts; mit „helm repo update“ aktualisiert."
  },
  "by": "Helm",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Caches/Mozilla.sccache"
  ],
  "title": {
   "en": "sccache compiler cache",
   "tr": "sccache derleyici önbelleği",
   "es": "Caché de compilación sccache",
   "de": "sccache-Compiler-Cache"
  },
  "what": {
   "en": "Compiled objects sccache reuses to speed up Rust and C/C++ builds; the next build fills it again.",
   "tr": "sccache'in Rust ve C/C++ derlemelerini hızlandırmak için yeniden kullandığı derlenmiş nesneler; sonraki derleme yeniden doldurur.",
   "es": "Objetos compilados que sccache reutiliza para acelerar compilaciones de Rust y C/C++; la siguiente compilación lo rellena.",
   "de": "Kompilierte Objekte, mit denen sccache Rust- und C/C++-Builds beschleunigt; der nächste Build füllt ihn wieder."
  },
  "by": "sccache",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Caches/ccache"
  ],
  "title": {
   "en": "ccache compiler cache",
   "tr": "ccache derleyici önbelleği",
   "es": "Caché de compilación ccache",
   "de": "ccache-Compiler-Cache"
  },
  "what": {
   "en": "Compiled objects ccache reuses to speed up C/C++ builds; the next build fills it again.",
   "tr": "ccache'in C/C++ derlemelerini hızlandırmak için yeniden kullandığı derlenmiş nesneler; sonraki derleme yeniden doldurur.",
   "es": "Objetos compilados que ccache reutiliza para acelerar compilaciones de C/C++; la siguiente compilación lo rellena.",
   "de": "Kompilierte Objekte, mit denen ccache C/C++-Builds beschleunigt; der nächste Build füllt ihn wieder."
  },
  "by": "ccache",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Caches/pip"
  ],
  "title": {
   "en": "pip cache",
   "tr": "pip önbelleği",
   "es": "Caché de pip",
   "de": "pip-Cache"
  },
  "what": {
   "en": "Python packages and wheels pip downloaded or built; pip downloads them again on the next install.",
   "tr": "pip'in indirdiği veya derlediği Python paketleri ve wheel dosyaları; pip bir sonraki kurulumda yeniden indirir.",
   "es": "Paquetes y wheels de Python que pip descargó o compiló; pip los vuelve a descargar en la siguiente instalación.",
   "de": "Von pip geladene oder gebaute Python-Pakete und Wheels; pip lädt sie bei der nächsten Installation erneut."
  },
  "by": "pip",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/Library/Caches/pypoetry"
  ],
  "title": {
   "en": "Poetry cache",
   "tr": "Poetry önbelleği",
   "es": "Caché de Poetry",
   "de": "Poetry-Cache"
  },
  "what": {
   "en": "Packages Poetry downloaded and, by default, your projects' virtual environments; “poetry install” recreates them.",
   "tr": "Poetry'nin indirdiği paketler ve varsayılan olarak projelerinizin sanal ortamları; “poetry install” yeniden oluşturur.",
   "es": "Paquetes que descargó Poetry y, por defecto, los entornos virtuales de tus proyectos; “poetry install” los recrea.",
   "de": "Von Poetry geladene Pakete und standardmäßig die virtuellen Umgebungen deiner Projekte; „poetry install“ erstellt sie neu."
  },
  "by": "Poetry",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.cache/uv"
  ],
  "title": {
   "en": "uv cache",
   "tr": "uv önbelleği",
   "es": "Caché de uv",
   "de": "uv-Cache"
  },
  "what": {
   "en": "Python packages uv downloaded and built; “uv cache clean” empties it, and uv downloads them again when needed.",
   "tr": "uv'nin indirip derlediği Python paketleri; “uv cache clean” boşaltır, uv gerektiğinde yeniden indirir.",
   "es": "Paquetes de Python que uv descargó y compiló; “uv cache clean” la vacía y uv los vuelve a descargar si hace falta.",
   "de": "Von uv geladene und gebaute Python-Pakete; „uv cache clean“ leert ihn, uv lädt sie bei Bedarf erneut."
  },
  "by": "uv",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.local/share/uv"
  ],
  "title": {
   "en": "uv Pythons and tools",
   "tr": "uv Python sürümleri ve araçları",
   "es": "Pythons y herramientas de uv",
   "de": "uv-Pythons und Tools"
  },
  "what": {
   "en": "Python versions and command-line tools installed with uv; remove them with “uv python uninstall” or “uv tool uninstall”.",
   "tr": "uv ile yüklenmiş Python sürümleri ve komut satırı araçları; “uv python uninstall” veya “uv tool uninstall” ile kaldırın.",
   "es": "Versiones de Python y herramientas instaladas con uv; elimínalas con “uv python uninstall” o “uv tool uninstall”.",
   "de": "Mit uv installierte Python-Versionen und Kommandozeilen-Tools; entferne sie mit „uv python uninstall“ oder „uv tool uninstall“."
  },
  "by": "uv",
  "safety": "review"
 },
 {
  "match": [
   "~/.pyenv"
  ],
  "title": {
   "en": "pyenv Python versions",
   "tr": "pyenv Python sürümleri",
   "es": "Versiones de Python de pyenv",
   "de": "pyenv-Python-Versionen"
  },
  "what": {
   "en": "Python versions installed with pyenv, each with its packages; remove unused ones with “pyenv uninstall”.",
   "tr": "pyenv ile yüklenmiş Python sürümleri, her biri paketleriyle; kullanmadıklarınızı “pyenv uninstall” ile kaldırın.",
   "es": "Versiones de Python instaladas con pyenv, cada una con sus paquetes; elimina las que no uses con “pyenv uninstall”.",
   "de": "Mit pyenv installierte Python-Versionen samt Paketen; entferne ungenutzte mit „pyenv uninstall“."
  },
  "by": "pyenv",
  "safety": "review"
 },
 {
  "match": [
   "~/.conda"
  ],
  "title": {
   "en": "conda settings",
   "tr": "conda ayarları",
   "es": "Ajustes de conda",
   "de": "conda-Einstellungen"
  },
  "what": {
   "en": "conda's list of environments and, in some setups, the environments themselves.",
   "tr": "conda'nın ortam listesi ve bazı kurulumlarda ortamların kendisi.",
   "es": "La lista de entornos de conda y, en algunas configuraciones, los propios entornos.",
   "de": "condas Liste der Umgebungen und bei manchen Setups die Umgebungen selbst."
  },
  "by": "conda",
  "safety": "review"
 },
 {
  "match": [
   "~/miniconda3",
   "~/anaconda3",
   "~/miniforge3",
   "~/opt/anaconda3",
   "~/opt/miniconda3"
  ],
  "title": {
   "en": "conda installation",
   "tr": "conda kurulumu",
   "es": "Instalación de conda",
   "de": "conda-Installation"
  },
  "what": {
   "en": "A full conda distribution with its Python, packages and your environments; deleting removes all of them.",
   "tr": "Python'u, paketleri ve ortamlarınızla birlikte tam bir conda dağıtımı; silmek hepsini kaldırır.",
   "es": "Una distribución completa de conda con su Python, paquetes y tus entornos; borrarla los elimina todos.",
   "de": "Eine vollständige conda-Distribution mit Python, Paketen und deinen Umgebungen; Löschen entfernt alles."
  },
  "by": "conda",
  "safety": "review"
 },
 {
  "match": [
   "~/miniconda3/pkgs",
   "~/anaconda3/pkgs",
   "~/miniforge3/pkgs",
   "~/opt/anaconda3/pkgs",
   "~/opt/miniconda3/pkgs"
  ],
  "title": {
   "en": "conda package cache",
   "tr": "conda paket önbelleği",
   "es": "Caché de paquetes de conda",
   "de": "conda-Paketcache"
  },
  "what": {
   "en": "Downloaded conda packages kept after installing; clear it with “conda clean --all” rather than by hand.",
   "tr": "Kurulumdan sonra tutulan indirilmiş conda paketleri; elle değil “conda clean --all” ile temizleyin.",
   "es": "Paquetes de conda descargados que se conservan tras instalar; vacíala con “conda clean --all” en lugar de a mano.",
   "de": "Nach der Installation aufbewahrte conda-Pakete; leere ihn mit „conda clean --all“ statt von Hand."
  },
  "by": "conda",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.virtualenvs"
  ],
  "title": {
   "en": "Python virtual environments",
   "tr": "Python sanal ortamları",
   "es": "Entornos virtuales de Python",
   "de": "Virtuelle Python-Umgebungen"
  },
  "what": {
   "en": "Virtual environments created with virtualenvwrapper; you can recreate them from your projects' requirements.",
   "tr": "virtualenvwrapper ile oluşturulmuş sanal ortamlar; projelerinizin gereksinimlerinden yeniden oluşturabilirsiniz.",
   "es": "Entornos virtuales creados con virtualenvwrapper; puedes recrearlos a partir de los requisitos de tus proyectos.",
   "de": "Mit virtualenvwrapper erstellte virtuelle Umgebungen; du kannst sie aus den Anforderungen deiner Projekte neu erstellen."
  },
  "by": "virtualenvwrapper",
  "safety": "review"
 },
 {
  "match": [
   "~/.local/share/virtualenvs"
  ],
  "title": {
   "en": "Pipenv environments",
   "tr": "Pipenv ortamları",
   "es": "Entornos de Pipenv",
   "de": "Pipenv-Umgebungen"
  },
  "what": {
   "en": "Virtual environments Pipenv created for your projects; “pipenv install” recreates them from the Pipfile.",
   "tr": "Pipenv'in projeleriniz için oluşturduğu sanal ortamlar; “pipenv install” bunları Pipfile'dan yeniden oluşturur.",
   "es": "Entornos virtuales que Pipenv creó para tus proyectos; “pipenv install” los recrea a partir del Pipfile.",
   "de": "Von Pipenv für deine Projekte erstellte virtuelle Umgebungen; „pipenv install“ erstellt sie aus dem Pipfile neu."
  },
  "by": "Pipenv",
  "safety": "regenerates"
 },
 {
  "match": [
   "~/.local/pipx"
  ],
  "title": {
   "en": "pipx tools",
   "tr": "pipx araçları",
   "es": "Herramientas de pipx",
   "de": "pipx-Tools"
  },
  "what": {
   "en": "Python command-line tools installed with pipx, each in its own environment; remove them with “pipx uninstall”.",
   "tr": "pipx ile yüklenmiş, her biri kendi ortamında Python komut satırı araçları; “pipx uninstall” ile kaldırın.",
   "es": "Herramientas de línea de comandos de Python instaladas con pipx, cada una en su entorno; elimínalas con “pipx uninstall”.",
   "de": "Mit pipx installierte Python-Kommandozeilen-Tools, jedes in eigener Umgebung; entferne sie mit „pipx uninstall“."
  },
  "by": "pipx",
  "safety": "review"
 },
 {
  "match": [
   "~/.local"
  ],
  "title": {
   "en": "Local data (.local)",
   "tr": "Yerel veriler (.local)",
   "es": "Datos locales (.local)",
   "de": "Lokale Daten (.local)"
  },
  "what": {
   "en": "Programs and data that command-line tools install for your account, such as ~/.local/bin; deleting can break them.",
   "tr": "Komut satırı araçlarının hesabınız için yüklediği ~/.local/bin gibi programlar ve veriler; silmek bunları bozabilir.",
   "es": "Programas y datos que las herramientas de terminal instalan para tu cuenta, como ~/.local/bin; borrarlo puede romperlas.",
   "de": "Programme und Daten, die Kommandozeilen-Tools für deinen Account ablegen, etwa ~/.local/bin; Löschen kann sie beschädigen."
  },
  "by": "Unix tools",
  "safety": "keep"
 },
 {
  "match": [
   "~/.cache"
  ],
  "title": {
   "en": "Tool cache (.cache)",
   "tr": "Araç önbelleği (.cache)",
   "es": "Caché de herramientas (.cache)",
   "de": "Tool-Cache (.cache)"
  },
  "what": {
   "en": "A shared cache folder used by many command-line and AI tools; most of it is re-downloadable, but check large subfolders.",
   "tr": "Birçok komut satırı ve yapay zekâ aracının kullandığı ortak önbellek; çoğu yeniden indirilebilir ama büyük alt klasörleri kontrol edin.",
   "es": "Una carpeta de caché que usan muchas herramientas de terminal y de IA; casi todo se puede volver a descargar, pero revisa las subcarpetas grandes.",
   "de": "Ein gemeinsamer Cache vieler Kommandozeilen- und KI-Tools; das meiste lässt sich neu laden, prüfe aber große Unterordner."
  },
  "by": "Unix tools",
  "safety": "review"
 },
 {
  "match": [
   "~/.cache/huggingface"
  ],
  "title": {
   "en": "Hugging Face cache",
   "tr": "Hugging Face önbelleği",
   "es": "Caché de Hugging Face",
   "de": "Hugging-Face-Cache"
  },
  "what": {
   "en": "AI models and datasets downloaded by Hugging Face libraries, often many GB; they're downloaded again on next use.",
   "tr": "Hugging Face kitaplıklarının indirdiği yapay zekâ modelleri ve veri kümeleri, çoğu zaman birkaç GB; sonraki kullanımda yeniden indirilir.",
   "es": "Modelos de IA y conjuntos de datos descargados por las bibliotecas de Hugging Face, a menudo de varios GB; se descargan al volver a usarlos.",
   "de": "Von Hugging-Face-Bibliotheken geladene KI-Modelle und Datensätze, oft viele GB; bei erneuter Nutzung wieder geladen."
  },
  "by": "Hugging Face",
  "safety": "regenerates"
 },
 {
  "match": [
   "~/.cache/torch"
  ],
  "title": {
   "en": "PyTorch model cache",
   "tr": "PyTorch model önbelleği",
   "es": "Caché de modelos de PyTorch",
   "de": "PyTorch-Modellcache"
  },
  "what": {
   "en": "Pretrained models and weights downloaded by PyTorch; downloaded again on next use.",
   "tr": "PyTorch'un indirdiği önceden eğitilmiş modeller ve ağırlıklar; sonraki kullanımda yeniden indirilir.",
   "es": "Modelos y pesos preentrenados que descargó PyTorch; se vuelven a descargar al usarlos.",
   "de": "Von PyTorch geladene vortrainierte Modelle und Gewichte; bei erneuter Nutzung wieder geladen."
  },
  "by": "PyTorch",
  "safety": "regenerates"
 },
 {
  "match": [
   "~/.cache/whisper"
  ],
  "title": {
   "en": "Whisper models",
   "tr": "Whisper modelleri",
   "es": "Modelos de Whisper",
   "de": "Whisper-Modelle"
  },
  "what": {
   "en": "Speech-recognition models downloaded by Whisper; downloaded again the next time you use that model.",
   "tr": "Whisper'ın indirdiği konuşma tanıma modelleri; o modeli bir sonraki kullanışınızda yeniden indirilir.",
   "es": "Modelos de reconocimiento de voz que descargó Whisper; se vuelven a descargar al usar ese modelo.",
   "de": "Von Whisper geladene Spracherkennungsmodelle; beim nächsten Einsatz des Modells erneut geladen."
  },
  "by": "OpenAI Whisper",
  "safety": "regenerates"
 },
 {
  "match": [
   "~/.cache/pre-commit"
  ],
  "title": {
   "en": "pre-commit environments",
   "tr": "pre-commit ortamları",
   "es": "Entornos de pre-commit",
   "de": "pre-commit-Umgebungen"
  },
  "what": {
   "en": "Hook repositories and environments pre-commit installed; recreated the next time hooks run.",
   "tr": "pre-commit'in yüklediği kanca depoları ve ortamları; kancalar bir sonraki çalıştığında yeniden oluşturulur.",
   "es": "Repositorios y entornos de hooks que instaló pre-commit; se recrean la próxima vez que se ejecuten los hooks.",
   "de": "Von pre-commit installierte Hook-Repositories und Umgebungen; beim nächsten Hook-Lauf neu erstellt."
  },
  "by": "pre-commit",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.cache/selenium"
  ],
  "title": {
   "en": "Selenium drivers",
   "tr": "Selenium sürücüleri",
   "es": "Controladores de Selenium",
   "de": "Selenium-Treiber"
  },
  "what": {
   "en": "Browsers and drivers downloaded by Selenium Manager; downloaded again on the next test run.",
   "tr": "Selenium Manager'ın indirdiği tarayıcılar ve sürücüler; bir sonraki test çalıştırmasında yeniden indirilir.",
   "es": "Navegadores y controladores que descargó Selenium Manager; se vuelven a descargar en la siguiente prueba.",
   "de": "Vom Selenium Manager geladene Browser und Treiber; beim nächsten Testlauf erneut geladen."
  },
  "by": "Selenium",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.matplotlib"
  ],
  "title": {
   "en": "Matplotlib cache",
   "tr": "Matplotlib önbelleği",
   "es": "Caché de Matplotlib",
   "de": "Matplotlib-Cache"
  },
  "what": {
   "en": "Matplotlib's font cache and settings; the cache is rebuilt on the next import.",
   "tr": "Matplotlib'in yazı tipi önbelleği ve ayarları; önbellek bir sonraki içe aktarmada yeniden oluşturulur.",
   "es": "La caché de fuentes y los ajustes de Matplotlib; la caché se regenera en la siguiente importación.",
   "de": "Matplotlibs Schriftcache und Einstellungen; der Cache wird beim nächsten Import neu aufgebaut."
  },
  "by": "Matplotlib",
  "safety": "regenerates"
 },
 {
  "match": [
   "~/.ipython"
  ],
  "title": {
   "en": "IPython profiles",
   "tr": "IPython profilleri",
   "es": "Perfiles de IPython",
   "de": "IPython-Profile"
  },
  "what": {
   "en": "IPython settings, startup scripts and your command history.",
   "tr": "IPython ayarları, başlangıç betikleri ve komut geçmişiniz.",
   "es": "Ajustes, scripts de inicio e historial de comandos de IPython.",
   "de": "IPython-Einstellungen, Startskripte und dein Befehlsverlauf."
  },
  "by": "IPython",
  "safety": "review"
 },
 {
  "match": [
   "~/.jupyter"
  ],
  "title": {
   "en": "Jupyter settings",
   "tr": "Jupyter ayarları",
   "es": "Ajustes de Jupyter",
   "de": "Jupyter-Einstellungen"
  },
  "what": {
   "en": "Jupyter configuration and extension settings; small, and deleting resets Jupyter.",
   "tr": "Jupyter yapılandırması ve uzantı ayarları; küçüktür, silmek Jupyter'ı sıfırlar.",
   "es": "Configuración de Jupyter y de sus extensiones; ocupa poco y borrarla restablece Jupyter.",
   "de": "Jupyter-Konfiguration und Erweiterungseinstellungen; klein, Löschen setzt Jupyter zurück."
  },
  "by": "Jupyter",
  "safety": "review"
 },
 {
  "match": [
   "~/.keras"
  ],
  "title": {
   "en": "Keras data",
   "tr": "Keras verileri",
   "es": "Datos de Keras",
   "de": "Keras-Daten"
  },
  "what": {
   "en": "Datasets and pretrained models downloaded by Keras, plus its config; downloads come back on next use.",
   "tr": "Keras'ın indirdiği veri kümeleri ve önceden eğitilmiş modeller ile yapılandırması; indirmeler sonraki kullanımda geri gelir.",
   "es": "Conjuntos de datos y modelos preentrenados descargados por Keras, más su configuración; lo descargado vuelve al usarlo.",
   "de": "Von Keras geladene Datensätze und vortrainierte Modelle plus Konfiguration; Downloads kommen bei Nutzung zurück."
  },
  "by": "Keras",
  "safety": "review"
 },
 {
  "match": [
   "~/.ollama"
  ],
  "title": {
   "en": "Ollama data",
   "tr": "Ollama verileri",
   "es": "Datos de Ollama",
   "de": "Ollama-Daten"
  },
  "what": {
   "en": "Ollama's downloaded models, its identity key and history; models are the large part.",
   "tr": "Ollama'nın indirdiği modeller, kimlik anahtarı ve geçmişi; büyük kısmı modellerdir.",
   "es": "Modelos descargados, clave de identidad e historial de Ollama; lo que más ocupa son los modelos.",
   "de": "Von Ollama geladene Modelle, sein Identitätsschlüssel und Verlauf; die Modelle machen den Großteil aus."
  },
  "by": "Ollama",
  "safety": "review"
 },
 {
  "match": [
   "~/.ollama/models"
  ],
  "title": {
   "en": "Ollama models",
   "tr": "Ollama modelleri",
   "es": "Modelos de Ollama",
   "de": "Ollama-Modelle"
  },
  "what": {
   "en": "AI models you pulled with Ollama, often several GB each; remove unused ones with “ollama rm”.",
   "tr": "Ollama ile çektiğiniz yapay zekâ modelleri, çoğu zaman her biri birkaç GB; kullanmadıklarınızı “ollama rm” ile kaldırın.",
   "es": "Modelos de IA que descargaste con Ollama, a menudo de varios GB; elimina los que no uses con “ollama rm”.",
   "de": "Mit Ollama geladene KI-Modelle, oft mehrere GB; entferne ungenutzte mit „ollama rm“."
  },
  "by": "Ollama",
  "safety": "review",
  "category": "devtools"
 },
 {
  "match": [
   "~/.lmstudio"
  ],
  "title": {
   "en": "LM Studio data",
   "tr": "LM Studio verileri",
   "es": "Datos de LM Studio",
   "de": "LM-Studio-Daten"
  },
  "what": {
   "en": "LM Studio's models, chats, settings and runtimes; models are the large part.",
   "tr": "LM Studio'nun modelleri, sohbetleri, ayarları ve çalışma ortamları; büyük kısmı modellerdir.",
   "es": "Modelos, chats, ajustes y entornos de LM Studio; lo que más ocupa son los modelos.",
   "de": "Modelle, Chats, Einstellungen und Laufzeiten von LM Studio; die Modelle machen den Großteil aus."
  },
  "by": "LM Studio",
  "safety": "review"
 },
 {
  "match": [
   "~/.lmstudio/models",
   "~/.cache/lm-studio/models"
  ],
  "title": {
   "en": "LM Studio models",
   "tr": "LM Studio modelleri",
   "es": "Modelos de LM Studio",
   "de": "LM-Studio-Modelle"
  },
  "what": {
   "en": "AI models downloaded in LM Studio, often several GB each; delete ones you no longer use from LM Studio.",
   "tr": "LM Studio'da indirilen yapay zekâ modelleri, çoğu zaman her biri birkaç GB; kullanmadıklarınızı LM Studio'dan silin.",
   "es": "Modelos de IA descargados en LM Studio, a menudo de varios GB; borra desde LM Studio los que ya no uses.",
   "de": "In LM Studio geladene KI-Modelle, oft mehrere GB; lösche nicht mehr genutzte in LM Studio."
  },
  "by": "LM Studio",
  "safety": "review",
  "category": "devtools"
 },
 {
  "match": [
   "~/.claude"
  ],
  "title": {
   "en": "Claude Code data",
   "tr": "Claude Code verileri",
   "es": "Datos de Claude Code",
   "de": "Claude-Code-Daten"
  },
  "what": {
   "en": "Claude Code settings, memory files, plugins and past session transcripts; transcripts grow with use.",
   "tr": "Claude Code ayarları, bellek dosyaları, eklentileri ve geçmiş oturum kayıtları; kayıtlar kullandıkça büyür.",
   "es": "Ajustes, archivos de memoria, plugins y transcripciones de sesiones de Claude Code; las transcripciones crecen con el uso.",
   "de": "Einstellungen, Memory-Dateien, Plugins und Sitzungsverläufe von Claude Code; die Verläufe wachsen mit der Nutzung."
  },
  "by": "Claude Code",
  "safety": "review"
 },
 {
  "match": [
   "~/.codeium"
  ],
  "title": {
   "en": "Codeium data",
   "tr": "Codeium verileri",
   "es": "Datos de Codeium",
   "de": "Codeium-Daten"
  },
  "what": {
   "en": "Codeium and Windsurf language servers, code indexes and settings; the binaries are downloaded again if removed.",
   "tr": "Codeium ve Windsurf dil sunucuları, kod dizinleri ve ayarları; kaldırılırsa programlar yeniden indirilir.",
   "es": "Servidores de lenguaje, índices de código y ajustes de Codeium y Windsurf; los binarios se vuelven a descargar si se borran.",
   "de": "Sprachserver, Code-Indizes und Einstellungen von Codeium und Windsurf; die Programme werden bei Bedarf neu geladen."
  },
  "by": "Codeium / Windsurf",
  "safety": "review"
 },
 {
  "match": [
   "~/.continue"
  ],
  "title": {
   "en": "Continue data",
   "tr": "Continue verileri",
   "es": "Datos de Continue",
   "de": "Continue-Daten"
  },
  "what": {
   "en": "The Continue AI assistant's config, chat sessions and code index.",
   "tr": "Continue yapay zekâ asistanının yapılandırması, sohbet oturumları ve kod dizini.",
   "es": "Configuración, sesiones de chat e índice de código del asistente de IA Continue.",
   "de": "Konfiguration, Chat-Sitzungen und Code-Index des KI-Assistenten Continue."
  },
  "by": "Continue",
  "safety": "review"
 },
 {
  "match": [
   "~/.vscode/extensions"
  ],
  "title": {
   "en": "VS Code extensions",
   "tr": "VS Code uzantıları",
   "es": "Extensiones de VS Code",
   "de": "VS-Code-Erweiterungen"
  },
  "what": {
   "en": "Extensions installed in VS Code; deleting uninstalls them, and you'd have to reinstall them from the Marketplace.",
   "tr": "VS Code'a yüklenmiş uzantılar; silmek onları kaldırır ve Marketplace'ten yeniden yüklemeniz gerekir.",
   "es": "Extensiones instaladas en VS Code; borrarlas las desinstala y tendrías que reinstalarlas desde el Marketplace.",
   "de": "In VS Code installierte Erweiterungen; Löschen deinstalliert sie, du müsstest sie aus dem Marketplace neu installieren."
  },
  "by": "Visual Studio Code",
  "safety": "review"
 },
 {
  "match": [
   "~/.cursor"
  ],
  "title": {
   "en": "Cursor data",
   "tr": "Cursor verileri",
   "es": "Datos de Cursor",
   "de": "Cursor-Daten"
  },
  "what": {
   "en": "Cursor's installed extensions and settings such as MCP server configuration.",
   "tr": "Cursor'ın yüklü uzantıları ve MCP sunucu yapılandırması gibi ayarları.",
   "es": "Extensiones instaladas y ajustes de Cursor, como la configuración de servidores MCP.",
   "de": "Installierte Erweiterungen und Einstellungen von Cursor, etwa die MCP-Server-Konfiguration."
  },
  "by": "Cursor",
  "safety": "review"
 },
 {
  "match": [
   "~/.cursor/extensions"
  ],
  "title": {
   "en": "Cursor extensions",
   "tr": "Cursor uzantıları",
   "es": "Extensiones de Cursor",
   "de": "Cursor-Erweiterungen"
  },
  "what": {
   "en": "Extensions installed in Cursor; deleting uninstalls them until you install them again.",
   "tr": "Cursor'a yüklenmiş uzantılar; silmek onları siz yeniden yükleyene kadar kaldırır.",
   "es": "Extensiones instaladas en Cursor; borrarlas las desinstala hasta que las vuelvas a instalar.",
   "de": "In Cursor installierte Erweiterungen; Löschen deinstalliert sie, bis du sie neu installierst."
  },
  "by": "Cursor",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Application Support/Code",
   "~/Library/Application Support/Cursor"
  ],
  "title": {
   "en": "Editor app data",
   "tr": "Düzenleyici verileri",
   "es": "Datos del editor",
   "de": "Editor-Daten"
  },
  "what": {
   "en": "Settings, keybindings, local history and workspace state of VS Code or Cursor; cache subfolders inside can go.",
   "tr": "VS Code veya Cursor'ın ayarları, tuş atamaları, yerel geçmişi ve çalışma alanı durumu; içindeki önbellek klasörleri silinebilir.",
   "es": "Ajustes, atajos, historial local y estado de espacios de trabajo de VS Code o Cursor; las subcarpetas de caché sí se pueden borrar.",
   "de": "Einstellungen, Tastenkürzel, lokaler Verlauf und Workspace-Status von VS Code oder Cursor; Cache-Unterordner können weg."
  },
  "by": "Visual Studio Code / Cursor",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Application Support/Code/CachedData",
   "~/Library/Application Support/Code/CachedExtensionVSIXs",
   "~/Library/Application Support/Cursor/CachedData",
   "~/Library/Application Support/Cursor/CachedExtensionVSIXs"
  ],
  "title": {
   "en": "Editor caches",
   "tr": "Düzenleyici önbellekleri",
   "es": "Cachés del editor",
   "de": "Editor-Caches"
  },
  "what": {
   "en": "Compiled code caches and downloaded extension packages of VS Code or Cursor, often from older versions; recreated as needed.",
   "tr": "VS Code veya Cursor'ın derlenmiş kod önbellekleri ve indirilmiş uzantı paketleri, çoğu eski sürümlerden; gerektiğinde yeniden oluşturulur.",
   "es": "Cachés de código compilado y paquetes de extensiones descargados de VS Code o Cursor, a menudo de versiones antiguas; se recrean.",
   "de": "Kompilierte Code-Caches und geladene Erweiterungspakete von VS Code oder Cursor, oft von älteren Versionen; bei Bedarf neu erstellt."
  },
  "by": "Visual Studio Code / Cursor",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "~/Library/Application Support/Code/User/workspaceStorage",
   "~/Library/Application Support/Cursor/User/workspaceStorage"
  ],
  "title": {
   "en": "Workspace storage",
   "tr": "Çalışma alanı depolaması",
   "es": "Almacenamiento de espacios de trabajo",
   "de": "Workspace-Speicher"
  },
  "what": {
   "en": "Per-project state saved by the editor and its extensions, including chat history in some tools; folders of old projects pile up.",
   "tr": "Düzenleyicinin ve uzantılarının proje başına kaydettiği durum, bazı araçlarda sohbet geçmişi dahil; eski projelerin klasörleri birikir.",
   "es": "Estado por proyecto que guardan el editor y sus extensiones, incluido el historial de chat en algunas; se acumulan carpetas de proyectos antiguos.",
   "de": "Projektbezogener Status von Editor und Erweiterungen, bei manchen inklusive Chatverlauf; Ordner alter Projekte sammeln sich an."
  },
  "by": "Visual Studio Code / Cursor",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Application Support/Code/logs",
   "~/Library/Application Support/Cursor/logs"
  ],
  "title": {
   "en": "Editor logs",
   "tr": "Düzenleyici günlükleri",
   "es": "Registros del editor",
   "de": "Editor-Protokolle"
  },
  "what": {
   "en": "Log files from VS Code or Cursor sessions; only useful when troubleshooting.",
   "tr": "VS Code veya Cursor oturumlarının günlük dosyaları; yalnızca sorun gidermede işe yarar.",
   "es": "Archivos de registro de sesiones de VS Code o Cursor; solo sirven para diagnosticar problemas.",
   "de": "Protokolldateien von VS-Code- oder Cursor-Sitzungen; nur zur Fehlersuche nützlich."
  },
  "by": "Visual Studio Code / Cursor",
  "safety": "safe",
  "category": "logs"
 },
 {
  "match": [
   "~/Library/Caches/com.microsoft.VSCode",
   "~/Library/Caches/com.microsoft.VSCode.ShipIt"
  ],
  "title": {
   "en": "VS Code update cache",
   "tr": "VS Code güncelleme önbelleği",
   "es": "Caché de actualizaciones de VS Code",
   "de": "VS-Code-Update-Cache"
  },
  "what": {
   "en": "Cached data and downloaded updates of VS Code; recreated when VS Code updates again.",
   "tr": "VS Code'un önbelleğe aldığı veriler ve indirilmiş güncellemeler; VS Code yeniden güncellendiğinde oluşturulur.",
   "es": "Datos en caché y actualizaciones descargadas de VS Code; se recrean en la siguiente actualización.",
   "de": "Zwischengespeicherte Daten und geladene Updates von VS Code; beim nächsten Update neu erstellt."
  },
  "by": "Visual Studio Code",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "~/Library/Application Support/*/Cache",
   "~/Library/Application Support/*/Code Cache",
   "~/Library/Application Support/*/GPUCache",
   "~/Library/Application Support/*/Service Worker/CacheStorage"
  ],
  "title": {
   "en": "Web-based app cache",
   "tr": "Web tabanlı uygulama önbelleği",
   "es": "Caché de app basada en web",
   "de": "Cache einer webbasierten App"
  },
  "what": {
   "en": "Web cache of an Electron app like Slack, Discord or VS Code; the app refills it as you use it.",
   "tr": "Slack, Discord veya VS Code gibi bir Electron uygulamasının web önbelleği; uygulama kullandıkça yeniden doldurur.",
   "es": "Caché web de una app Electron como Slack, Discord o VS Code; la app la rellena al usarla.",
   "de": "Web-Cache einer Electron-App wie Slack, Discord oder VS Code; die App füllt ihn bei Nutzung wieder."
  },
  "by": "Electron / Chromium apps",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "~/.docker"
  ],
  "title": {
   "en": "Docker CLI settings",
   "tr": "Docker CLI ayarları",
   "es": "Ajustes de Docker CLI",
   "de": "Docker-CLI-Einstellungen"
  },
  "what": {
   "en": "Docker command-line config, saved registry logins, contexts and plugins; deleting signs you out and can break docker commands.",
   "tr": "Docker komut satırı yapılandırması, kayıtlı registry girişleri, bağlamlar ve eklentiler; silmek oturumu kapatır ve docker komutlarını bozabilir.",
   "es": "Configuración de la CLI de Docker, inicios de sesión en registros, contextos y plugins; borrarla cierra sesión y puede romper comandos docker.",
   "de": "Docker-CLI-Konfiguration, gespeicherte Registry-Logins, Kontexte und Plugins; Löschen meldet dich ab und kann docker-Befehle stören."
  },
  "by": "Docker",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Containers/com.docker.docker"
  ],
  "title": {
   "en": "Docker Desktop data",
   "tr": "Docker Desktop verileri",
   "es": "Datos de Docker Desktop",
   "de": "Docker-Desktop-Daten"
  },
  "what": {
   "en": "Docker Desktop's virtual disk with all images, containers and volumes; free space with “docker system prune” or Docker Desktop.",
   "tr": "Tüm imajlar, konteynerler ve birimlerle Docker Desktop sanal diski; yer açmak için “docker system prune” veya Docker Desktop'ı kullanın.",
   "es": "El disco virtual de Docker Desktop con todas las imágenes, contenedores y volúmenes; libera espacio con “docker system prune” o Docker Desktop.",
   "de": "Die virtuelle Festplatte von Docker Desktop mit allen Images, Containern und Volumes; schaffe Platz mit „docker system prune“ oder Docker Desktop."
  },
  "by": "Docker Desktop",
  "safety": "review",
  "category": "docker"
 },
 {
  "match": [
   "~/Library/Application Support/Docker Desktop"
  ],
  "title": {
   "en": "Docker Desktop settings",
   "tr": "Docker Desktop ayarları",
   "es": "Ajustes de Docker Desktop",
   "de": "Docker-Desktop-Einstellungen"
  },
  "what": {
   "en": "Docker Desktop's settings and state; to start fresh, use its Troubleshoot menu instead of deleting.",
   "tr": "Docker Desktop ayarları ve durumu; sıfırdan başlamak için silmek yerine Sorun Giderme menüsünü kullanın.",
   "es": "Ajustes y estado de Docker Desktop; para empezar de cero usa su menú Troubleshoot en lugar de borrar.",
   "de": "Einstellungen und Status von Docker Desktop; für einen Neustart nutze das Troubleshoot-Menü statt zu löschen."
  },
  "by": "Docker Desktop",
  "safety": "keep"
 },
 {
  "match": [
   "~/.colima"
  ],
  "title": {
   "en": "Colima VMs",
   "tr": "Colima sanal makineleri",
   "es": "Máquinas virtuales de Colima",
   "de": "Colima-VMs"
  },
  "what": {
   "en": "Colima's virtual machines with their container images and volumes; delete them with “colima delete”.",
   "tr": "Konteyner imajları ve birimleriyle Colima sanal makineleri; “colima delete” ile silin.",
   "es": "Máquinas virtuales de Colima con sus imágenes y volúmenes; bórralas con “colima delete”.",
   "de": "Colimas virtuelle Maschinen mit Container-Images und Volumes; lösche sie mit „colima delete“."
  },
  "by": "Colima",
  "safety": "review",
  "category": "docker"
 },
 {
  "match": [
   "~/.lima"
  ],
  "title": {
   "en": "Lima VMs",
   "tr": "Lima sanal makineleri",
   "es": "Máquinas virtuales de Lima",
   "de": "Lima-VMs"
  },
  "what": {
   "en": "Lima Linux virtual machines and their disks; delete them with “limactl delete”.",
   "tr": "Lima Linux sanal makineleri ve diskleri; “limactl delete” ile silin.",
   "es": "Máquinas virtuales Linux de Lima y sus discos; bórralas con “limactl delete”.",
   "de": "Lima-Linux-VMs und ihre Festplatten; lösche sie mit „limactl delete“."
  },
  "by": "Lima",
  "safety": "review",
  "category": "docker"
 },
 {
  "match": [
   "~/.orbstack"
  ],
  "title": {
   "en": "OrbStack",
   "tr": "OrbStack",
   "es": "OrbStack",
   "de": "OrbStack"
  },
  "what": {
   "en": "OrbStack's settings, logs and helpers; manage containers and machines from the OrbStack app instead of deleting.",
   "tr": "OrbStack ayarları, günlükleri ve yardımcıları; konteynerleri ve makineleri silmek yerine OrbStack uygulamasından yönetin.",
   "es": "Ajustes, registros y ayudantes de OrbStack; gestiona contenedores y máquinas desde la app OrbStack en lugar de borrar.",
   "de": "Einstellungen, Protokolle und Helfer von OrbStack; verwalte Container und Maschinen in der OrbStack-App statt zu löschen."
  },
  "by": "OrbStack",
  "safety": "review",
  "category": "docker"
 },
 {
  "match": [
   "~/Library/Application Support/rancher-desktop"
  ],
  "title": {
   "en": "Rancher Desktop data",
   "tr": "Rancher Desktop verileri",
   "es": "Datos de Rancher Desktop",
   "de": "Rancher-Desktop-Daten"
  },
  "what": {
   "en": "Rancher Desktop's virtual machine with its images, containers and Kubernetes data; reset it from the app.",
   "tr": "İmajları, konteynerleri ve Kubernetes verileriyle Rancher Desktop sanal makinesi; uygulamadan sıfırlayın.",
   "es": "La máquina virtual de Rancher Desktop con imágenes, contenedores y datos de Kubernetes; restablécela desde la app.",
   "de": "Die VM von Rancher Desktop mit Images, Containern und Kubernetes-Daten; setze sie in der App zurück."
  },
  "by": "Rancher Desktop",
  "safety": "review",
  "category": "docker"
 },
 {
  "match": [
   "~/.minikube"
  ],
  "title": {
   "en": "minikube clusters",
   "tr": "minikube kümeleri",
   "es": "Clústeres de minikube",
   "de": "minikube-Cluster"
  },
  "what": {
   "en": "minikube cluster machines, certificates and cached images; delete clusters with “minikube delete”.",
   "tr": "minikube küme makineleri, sertifikaları ve önbelleğe alınmış imajları; kümeleri “minikube delete” ile silin.",
   "es": "Máquinas de clúster, certificados e imágenes en caché de minikube; borra clústeres con “minikube delete”.",
   "de": "minikube-Clustermaschinen, Zertifikate und zwischengespeicherte Images; lösche Cluster mit „minikube delete“."
  },
  "by": "minikube",
  "safety": "review",
  "category": "docker"
 },
 {
  "match": [
   "~/.minikube/cache"
  ],
  "title": {
   "en": "minikube cache",
   "tr": "minikube önbelleği",
   "es": "Caché de minikube",
   "de": "minikube-Cache"
  },
  "what": {
   "en": "Kubernetes images and binaries minikube downloaded; downloaded again on the next “minikube start”.",
   "tr": "minikube'un indirdiği Kubernetes imajları ve programları; bir sonraki “minikube start” işleminde yeniden indirilir.",
   "es": "Imágenes y binarios de Kubernetes que descargó minikube; se descargan de nuevo en el siguiente “minikube start”.",
   "de": "Von minikube geladene Kubernetes-Images und Programme; beim nächsten „minikube start“ erneut geladen."
  },
  "by": "minikube",
  "safety": "regenerates",
  "category": "docker"
 },
 {
  "match": [
   "~/.kube"
  ],
  "title": {
   "en": "Kubernetes config",
   "tr": "Kubernetes yapılandırması",
   "es": "Configuración de Kubernetes",
   "de": "Kubernetes-Konfiguration"
  },
  "what": {
   "en": "Your kubeconfig with cluster addresses and credentials, plus kubectl caches; deleting cuts access to your clusters.",
   "tr": "Küme adresleri ve kimlik bilgileriyle kubeconfig dosyanız ve kubectl önbellekleri; silmek kümelerinize erişimi keser.",
   "es": "Tu kubeconfig con direcciones y credenciales de clústeres, más cachés de kubectl; borrarlo te deja sin acceso a tus clústeres.",
   "de": "Deine kubeconfig mit Cluster-Adressen und Zugangsdaten sowie kubectl-Caches; Löschen kappt den Zugriff auf deine Cluster."
  },
  "by": "Kubernetes (kubectl)",
  "safety": "keep"
 },
 {
  "match": [
   "~/.vagrant.d"
  ],
  "title": {
   "en": "Vagrant boxes",
   "tr": "Vagrant kutuları",
   "es": "Boxes de Vagrant",
   "de": "Vagrant-Boxen"
  },
  "what": {
   "en": "Base boxes Vagrant downloaded, often GBs each, plus plugins; remove unused ones with “vagrant box remove”.",
   "tr": "Vagrant'ın indirdiği, çoğu zaman GB'larca temel kutular ve eklentiler; kullanmadıklarınızı “vagrant box remove” ile kaldırın.",
   "es": "Boxes base que descargó Vagrant, a menudo de varios GB, y plugins; elimina las que no uses con “vagrant box remove”.",
   "de": "Von Vagrant geladene Basis-Boxen, oft mehrere GB, plus Plugins; entferne ungenutzte mit „vagrant box remove“."
  },
  "by": "Vagrant",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Containers/com.utmapp.UTM"
  ],
  "title": {
   "en": "UTM virtual machines",
   "tr": "UTM sanal makineleri",
   "es": "Máquinas virtuales de UTM",
   "de": "UTM-VMs"
  },
  "what": {
   "en": "Your UTM virtual machines and their disks; delete VMs you don't need from within UTM.",
   "tr": "UTM sanal makineleriniz ve diskleri; ihtiyacınız olmayanları UTM içinden silin.",
   "es": "Tus máquinas virtuales de UTM y sus discos; borra las que no necesites desde UTM.",
   "de": "Deine UTM-VMs und ihre Festplatten; lösche nicht benötigte VMs in UTM."
  },
  "by": "UTM",
  "safety": "review"
 },
 {
  "match": [
   "~/Parallels"
  ],
  "title": {
   "en": "Parallels virtual machines",
   "tr": "Parallels sanal makineleri",
   "es": "Máquinas virtuales de Parallels",
   "de": "Parallels-VMs"
  },
  "what": {
   "en": "Your Parallels virtual machines, often tens of GB; delete unused ones from Parallels' Control Center.",
   "tr": "Parallels sanal makineleriniz, çoğu zaman onlarca GB; kullanmadıklarınızı Parallels Denetim Merkezi'nden silin.",
   "es": "Tus máquinas virtuales de Parallels, a menudo de decenas de GB; borra las que no uses desde el Centro de control de Parallels.",
   "de": "Deine Parallels-VMs, oft dutzende GB; lösche ungenutzte im Control Center von Parallels."
  },
  "by": "Parallels Desktop",
  "safety": "review"
 },
 {
  "match": [
   "~/Virtual Machines.localized"
  ],
  "title": {
   "en": "VMware Fusion virtual machines",
   "tr": "VMware Fusion sanal makineleri",
   "es": "Máquinas virtuales de VMware Fusion",
   "de": "VMware-Fusion-VMs"
  },
  "what": {
   "en": "Your VMware Fusion virtual machines, often tens of GB; delete unused ones from VMware Fusion.",
   "tr": "VMware Fusion sanal makineleriniz, çoğu zaman onlarca GB; kullanmadıklarınızı VMware Fusion'dan silin.",
   "es": "Tus máquinas virtuales de VMware Fusion, a menudo de decenas de GB; borra las que no uses desde VMware Fusion.",
   "de": "Deine VMware-Fusion-VMs, oft dutzende GB; lösche ungenutzte in VMware Fusion."
  },
  "by": "VMware Fusion",
  "safety": "review"
 },
 {
  "match": [
   "~/VirtualBox VMs"
  ],
  "title": {
   "en": "VirtualBox virtual machines",
   "tr": "VirtualBox sanal makineleri",
   "es": "Máquinas virtuales de VirtualBox",
   "de": "VirtualBox-VMs"
  },
  "what": {
   "en": "Your VirtualBox virtual machines and their disks; delete unused ones from VirtualBox.",
   "tr": "VirtualBox sanal makineleriniz ve diskleri; kullanmadıklarınızı VirtualBox'tan silin.",
   "es": "Tus máquinas virtuales de VirtualBox y sus discos; borra las que no uses desde VirtualBox.",
   "de": "Deine VirtualBox-VMs und ihre Festplatten; lösche ungenutzte in VirtualBox."
  },
  "by": "VirtualBox",
  "safety": "review"
 },
 {
  "match": [
   "~/.wine"
  ],
  "title": {
   "en": "Wine prefix",
   "tr": "Wine ortamı",
   "es": "Prefijo de Wine",
   "de": "Wine-Präfix"
  },
  "what": {
   "en": "A Windows environment for Wine with installed Windows programs and their data, such as game saves.",
   "tr": "Yüklü Windows programları ve oyun kayıtları gibi verileriyle Wine için bir Windows ortamı.",
   "es": "Un entorno Windows para Wine con programas instalados y sus datos, como partidas guardadas.",
   "de": "Eine Windows-Umgebung für Wine mit installierten Windows-Programmen und deren Daten, etwa Spielständen."
  },
  "by": "Wine",
  "safety": "review"
 },
 {
  "match": [
   "~/.platformio"
  ],
  "title": {
   "en": "PlatformIO data",
   "tr": "PlatformIO verileri",
   "es": "Datos de PlatformIO",
   "de": "PlatformIO-Daten"
  },
  "what": {
   "en": "Toolchains, frameworks and platforms PlatformIO downloaded for your boards; downloaded again when a project needs them.",
   "tr": "PlatformIO'nun kartlarınız için indirdiği araç zincirleri, çatılar ve platformlar; bir proje ihtiyaç duyduğunda yeniden indirilir.",
   "es": "Toolchains, frameworks y plataformas que PlatformIO descargó para tus placas; se descargan de nuevo cuando un proyecto los necesita.",
   "de": "Toolchains, Frameworks und Plattformen, die PlatformIO für deine Boards lud; bei Bedarf eines Projekts erneut geladen."
  },
  "by": "PlatformIO",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Arduino15"
  ],
  "title": {
   "en": "Arduino cores and tools",
   "tr": "Arduino çekirdekleri ve araçları",
   "es": "Núcleos y herramientas de Arduino",
   "de": "Arduino-Cores und Tools"
  },
  "what": {
   "en": "Board packages, compilers and settings of the Arduino IDE; remove unused boards in the Boards Manager.",
   "tr": "Arduino IDE'nin kart paketleri, derleyicileri ve ayarları; kullanmadığınız kartları Kart Yöneticisi'nden kaldırın.",
   "es": "Paquetes de placas, compiladores y ajustes del IDE de Arduino; elimina las placas que no uses en el Gestor de placas.",
   "de": "Board-Pakete, Compiler und Einstellungen der Arduino IDE; entferne ungenutzte Boards im Boardverwalter."
  },
  "by": "Arduino",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Arduino15/staging"
  ],
  "title": {
   "en": "Arduino download cache",
   "tr": "Arduino indirme önbelleği",
   "es": "Caché de descargas de Arduino",
   "de": "Arduino-Download-Cache"
  },
  "what": {
   "en": "Archives the Arduino IDE downloaded while installing boards and libraries; downloaded again if needed.",
   "tr": "Arduino IDE'nin kart ve kitaplık yüklerken indirdiği arşivler; gerekirse yeniden indirilir.",
   "es": "Archivos que el IDE de Arduino descargó al instalar placas y bibliotecas; se descargan de nuevo si hace falta.",
   "de": "Archive, die die Arduino IDE beim Installieren von Boards und Bibliotheken lud; bei Bedarf erneut geladen."
  },
  "by": "Arduino",
  "safety": "regenerates",
  "category": "devcaches"
 },
 {
  "match": [
   "~/.espressif"
  ],
  "title": {
   "en": "ESP-IDF tools",
   "tr": "ESP-IDF araçları",
   "es": "Herramientas de ESP-IDF",
   "de": "ESP-IDF-Tools"
  },
  "what": {
   "en": "Compilers and Python environments installed by ESP-IDF; its install script recreates them for the versions you use.",
   "tr": "ESP-IDF'nin yüklediği derleyiciler ve Python ortamları; kurulum betiği kullandığınız sürümler için yeniden oluşturur.",
   "es": "Compiladores y entornos de Python que instaló ESP-IDF; su script de instalación los recrea para las versiones que uses.",
   "de": "Von ESP-IDF installierte Compiler und Python-Umgebungen; das Installationsskript erstellt sie für genutzte Versionen neu."
  },
  "by": "Espressif ESP-IDF",
  "safety": "review"
 },
 {
  "match": [
   "~/.ssh"
  ],
  "title": {
   "en": "SSH keys",
   "tr": "SSH anahtarları",
   "es": "Claves SSH",
   "de": "SSH-Schlüssel"
  },
  "what": {
   "en": "Your private SSH keys, known hosts and SSH config; deleting locks you out of servers and Git hosts.",
   "tr": "Özel SSH anahtarlarınız, bilinen sunucular ve SSH yapılandırmanız; silmek sunuculara ve Git hizmetlerine erişiminizi keser.",
   "es": "Tus claves SSH privadas, hosts conocidos y configuración SSH; borrarlas te deja sin acceso a servidores y a Git.",
   "de": "Deine privaten SSH-Schlüssel, bekannten Hosts und SSH-Konfiguration; Löschen sperrt dich von Servern und Git-Hosts aus."
  },
  "by": "OpenSSH",
  "safety": "keep"
 },
 {
  "match": [
   "~/.gnupg"
  ],
  "title": {
   "en": "GnuPG keys",
   "tr": "GnuPG anahtarları",
   "es": "Claves de GnuPG",
   "de": "GnuPG-Schlüssel"
  },
  "what": {
   "en": "Your GPG keys and keyrings for signing and encryption; deleting can make encrypted data unreadable.",
   "tr": "İmzalama ve şifreleme için GPG anahtarlarınız ve anahtarlıklarınız; silmek şifreli verileri okunamaz hâle getirebilir.",
   "es": "Tus claves y llaveros GPG para firmar y cifrar; borrarlos puede dejar ilegibles tus datos cifrados.",
   "de": "Deine GPG-Schlüssel und Schlüsselbunde zum Signieren und Verschlüsseln; Löschen kann verschlüsselte Daten unlesbar machen."
  },
  "by": "GnuPG",
  "safety": "keep"
 },
 {
  "match": [
   "~/.aws"
  ],
  "title": {
   "en": "AWS credentials",
   "tr": "AWS kimlik bilgileri",
   "es": "Credenciales de AWS",
   "de": "AWS-Zugangsdaten"
  },
  "what": {
   "en": "Your AWS CLI credentials and profiles; deleting cuts access to your AWS accounts from this Mac.",
   "tr": "AWS CLI kimlik bilgileriniz ve profilleriniz; silmek bu Mac'ten AWS hesaplarınıza erişimi keser.",
   "es": "Tus credenciales y perfiles de la CLI de AWS; borrarlos te deja sin acceso a tus cuentas de AWS desde este Mac.",
   "de": "Deine AWS-CLI-Zugangsdaten und Profile; Löschen kappt den Zugriff auf deine AWS-Accounts von diesem Mac."
  },
  "by": "AWS CLI",
  "safety": "keep"
 },
 {
  "match": [
   "~/.azure"
  ],
  "title": {
   "en": "Azure CLI login",
   "tr": "Azure CLI oturumu",
   "es": "Sesión de Azure CLI",
   "de": "Azure-CLI-Anmeldung"
  },
  "what": {
   "en": "Azure CLI sign-in tokens and settings; deleting signs you out of Azure on this Mac.",
   "tr": "Azure CLI oturum belirteçleri ve ayarları; silmek bu Mac'te Azure oturumunuzu kapatır.",
   "es": "Tokens de inicio de sesión y ajustes de la CLI de Azure; borrarlos cierra tu sesión de Azure en este Mac.",
   "de": "Anmelde-Tokens und Einstellungen der Azure CLI; Löschen meldet dich auf diesem Mac von Azure ab."
  },
  "by": "Azure CLI",
  "safety": "keep"
 },
 {
  "match": [
   "~/.config/gcloud"
  ],
  "title": {
   "en": "Google Cloud CLI login",
   "tr": "Google Cloud CLI oturumu",
   "es": "Sesión de Google Cloud CLI",
   "de": "Google-Cloud-CLI-Anmeldung"
  },
  "what": {
   "en": "gcloud credentials and configurations; deleting signs you out of Google Cloud on this Mac.",
   "tr": "gcloud kimlik bilgileri ve yapılandırmaları; silmek bu Mac'te Google Cloud oturumunuzu kapatır.",
   "es": "Credenciales y configuraciones de gcloud; borrarlas cierra tu sesión de Google Cloud en este Mac.",
   "de": "gcloud-Zugangsdaten und Konfigurationen; Löschen meldet dich auf diesem Mac von Google Cloud ab."
  },
  "by": "Google Cloud CLI",
  "safety": "keep"
 },
 {
  "match": [
   "~/.config"
  ],
  "title": {
   "en": "Tool settings (.config)",
   "tr": "Araç ayarları (.config)",
   "es": "Ajustes de herramientas (.config)",
   "de": "Tool-Einstellungen (.config)"
  },
  "what": {
   "en": "Settings of many command-line tools and some apps, sometimes including login tokens; small and personal.",
   "tr": "Birçok komut satırı aracının ve bazı uygulamaların ayarları, bazen oturum belirteçleri dahil; küçük ve kişiseldir.",
   "es": "Ajustes de muchas herramientas de terminal y algunas apps, a veces con tokens de sesión; ocupa poco y es personal.",
   "de": "Einstellungen vieler Kommandozeilen-Tools und mancher Apps, teils mit Anmelde-Tokens; klein und persönlich."
  },
  "by": "Unix tools",
  "safety": "keep"
 },
 {
  "match": [
   "~/.oh-my-zsh"
  ],
  "title": {
   "en": "Oh My Zsh",
   "tr": "Oh My Zsh",
   "es": "Oh My Zsh",
   "de": "Oh My Zsh"
  },
  "what": {
   "en": "The Oh My Zsh framework with themes and plugins your shell loads; deleting it breaks your shell setup.",
   "tr": "Kabuğunuzun yüklediği temalar ve eklentilerle Oh My Zsh çatısı; silmek kabuk kurulumunuzu bozar.",
   "es": "El framework Oh My Zsh con los temas y plugins que carga tu shell; borrarlo rompe tu configuración del shell.",
   "de": "Das Oh-My-Zsh-Framework mit Themes und Plugins, die deine Shell lädt; Löschen beschädigt dein Shell-Setup."
  },
  "by": "Oh My Zsh",
  "safety": "keep"
 },
 {
  "match": [
   "~/.dropbox"
  ],
  "title": {
   "en": "Dropbox app state",
   "tr": "Dropbox uygulama durumu",
   "es": "Estado de la app Dropbox",
   "de": "Dropbox-App-Status"
  },
  "what": {
   "en": "Dropbox's internal databases and settings; deleting can unlink this Mac and force a full re-sync.",
   "tr": "Dropbox'ın dahili veritabanları ve ayarları; silmek bu Mac'in bağlantısını kesebilir ve tam yeniden eşzamanlama gerektirebilir.",
   "es": "Bases de datos internas y ajustes de Dropbox; borrarlos puede desvincular este Mac y forzar una resincronización completa.",
   "de": "Interne Datenbanken und Einstellungen von Dropbox; Löschen kann diesen Mac trennen und eine komplette Neusynchronisierung erzwingen."
  },
  "by": "Dropbox",
  "safety": "keep"
 },
 {
  "match": [
   "~/.Trash"
  ],
  "title": {
   "en": "Trash",
   "tr": "Çöp Sepeti",
   "es": "Papelera",
   "de": "Papierkorb"
  },
  "what": {
   "en": "Files you moved to the Trash; they still take space until you empty it, so make sure nothing there is still needed.",
   "tr": "Çöp Sepeti'ne taşıdığınız dosyalar; boşaltana kadar yer kaplamaya devam eder, içinde hâlâ gerekli bir şey olmadığından emin olun.",
   "es": "Archivos que moviste a la Papelera; siguen ocupando espacio hasta que la vacíes, asegúrate de que no necesitas nada.",
   "de": "Dateien, die du in den Papierkorb gelegt hast; sie belegen Platz, bis du ihn leerst – prüfe, dass nichts mehr gebraucht wird."
  },
  "by": "macOS",
  "safety": "review",
  "category": "trash"
 },
 {
  "match": [
   "~/Library/Application Support/Google/Chrome"
  ],
  "title": {
   "en": "Chrome profiles",
   "tr": "Chrome profilleri",
   "es": "Perfiles de Chrome",
   "de": "Chrome-Profile"
  },
  "what": {
   "en": "Your Chrome profiles with bookmarks, history, passwords, extensions and site data.",
   "tr": "Yer işaretleri, geçmiş, parolalar, uzantılar ve site verileriyle Chrome profilleriniz.",
   "es": "Tus perfiles de Chrome con marcadores, historial, contraseñas, extensiones y datos de sitios.",
   "de": "Deine Chrome-Profile mit Lesezeichen, Verlauf, Passwörtern, Erweiterungen und Website-Daten."
  },
  "by": "Google Chrome",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel"
  ],
  "title": {
   "en": "Chrome on-device AI model",
   "tr": "Chrome cihaz içi yapay zekâ modeli",
   "es": "Modelo de IA local de Chrome",
   "de": "Lokales KI-Modell von Chrome"
  },
  "what": {
   "en": "The AI model Chrome downloads for built-in features, a few GB; Chrome downloads it again if those features need it.",
   "tr": "Chrome'un yerleşik özellikler için indirdiği, birkaç GB'lık yapay zekâ modeli; bu özellikler gerektirirse Chrome yeniden indirir.",
   "es": "El modelo de IA que Chrome descarga para funciones integradas, de unos GB; Chrome lo vuelve a descargar si esas funciones lo necesitan.",
   "de": "Das KI-Modell, das Chrome für integrierte Funktionen lädt, einige GB; Chrome lädt es erneut, wenn diese Funktionen es brauchen."
  },
  "by": "Google Chrome",
  "safety": "regenerates"
 },
 {
  "match": [
   "~/Library/Caches/Google/Chrome"
  ],
  "title": {
   "en": "Chrome cache",
   "tr": "Chrome önbelleği",
   "es": "Caché de Chrome",
   "de": "Chrome-Cache"
  },
  "what": {
   "en": "Web pages, images and scripts Chrome stored to load sites faster; Chrome refills it as you browse.",
   "tr": "Chrome'un siteleri daha hızlı açmak için sakladığı web sayfaları, görseller ve betikler; gezindikçe yeniden dolar.",
   "es": "Páginas, imágenes y scripts que Chrome guarda para cargar webs más rápido; se rellena al navegar.",
   "de": "Webseiten, Bilder und Skripte, die Chrome für schnelleres Laden speichert; füllt sich beim Surfen wieder."
  },
  "by": "Google Chrome",
  "safety": "regenerates",
  "category": "browsers"
 },
 {
  "match": [
   "~/Library/Caches/Google"
  ],
  "title": {
   "en": "Google app caches",
   "tr": "Google uygulama önbellekleri",
   "es": "Cachés de apps de Google",
   "de": "Google-App-Caches"
  },
  "what": {
   "en": "Caches of Google apps such as Chrome, Android Studio and Google Drive; each app rebuilds its cache as needed.",
   "tr": "Chrome, Android Studio ve Google Drive gibi Google uygulamalarının önbellekleri; her uygulama gerektiğinde yeniden oluşturur.",
   "es": "Cachés de apps de Google como Chrome, Android Studio y Google Drive; cada app regenera la suya cuando hace falta.",
   "de": "Caches von Google-Apps wie Chrome, Android Studio und Google Drive; jede App baut ihren Cache bei Bedarf neu auf."
  },
  "by": "Google",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "~/Library/Application Support/Firefox"
  ],
  "title": {
   "en": "Firefox profiles",
   "tr": "Firefox profilleri",
   "es": "Perfiles de Firefox",
   "de": "Firefox-Profile"
  },
  "what": {
   "en": "Your Firefox profiles with bookmarks, history, passwords, extensions and site data.",
   "tr": "Yer işaretleri, geçmiş, parolalar, uzantılar ve site verileriyle Firefox profilleriniz.",
   "es": "Tus perfiles de Firefox con marcadores, historial, contraseñas, extensiones y datos de sitios.",
   "de": "Deine Firefox-Profile mit Lesezeichen, Verlauf, Passwörtern, Erweiterungen und Website-Daten."
  },
  "by": "Mozilla Firefox",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Caches/Firefox"
  ],
  "title": {
   "en": "Firefox cache",
   "tr": "Firefox önbelleği",
   "es": "Caché de Firefox",
   "de": "Firefox-Cache"
  },
  "what": {
   "en": "Web content Firefox stored to load sites faster; Firefox refills it as you browse.",
   "tr": "Firefox'un siteleri daha hızlı açmak için sakladığı web içeriği; gezindikçe yeniden dolar.",
   "es": "Contenido web que Firefox guarda para cargar webs más rápido; se rellena al navegar.",
   "de": "Webinhalte, die Firefox für schnelleres Laden speichert; füllt sich beim Surfen wieder."
  },
  "by": "Mozilla Firefox",
  "safety": "regenerates",
  "category": "browsers"
 },
 {
  "match": [
   "~/Library/Application Support/Microsoft Edge",
   "~/Library/Application Support/BraveSoftware",
   "~/Library/Application Support/Arc"
  ],
  "title": {
   "en": "Browser profiles",
   "tr": "Tarayıcı profilleri",
   "es": "Perfiles del navegador",
   "de": "Browserprofile"
  },
  "what": {
   "en": "Your browser profiles with bookmarks, history, passwords, extensions and site data.",
   "tr": "Yer işaretleri, geçmiş, parolalar, uzantılar ve site verileriyle tarayıcı profilleriniz.",
   "es": "Tus perfiles del navegador con marcadores, historial, contraseñas, extensiones y datos de sitios.",
   "de": "Deine Browserprofile mit Lesezeichen, Verlauf, Passwörtern, Erweiterungen und Website-Daten."
  },
  "by": "Microsoft Edge / Brave / Arc",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Caches/Microsoft Edge",
   "~/Library/Caches/BraveSoftware",
   "~/Library/Caches/com.operasoftware.Opera"
  ],
  "title": {
   "en": "Browser cache",
   "tr": "Tarayıcı önbelleği",
   "es": "Caché del navegador",
   "de": "Browser-Cache"
  },
  "what": {
   "en": "Web content the browser stored to load sites faster; it refills as you browse.",
   "tr": "Tarayıcının siteleri daha hızlı açmak için sakladığı web içeriği; gezindikçe yeniden dolar.",
   "es": "Contenido web que el navegador guarda para cargar webs más rápido; se rellena al navegar.",
   "de": "Webinhalte, die der Browser für schnelleres Laden speichert; füllt sich beim Surfen wieder."
  },
  "by": "Microsoft Edge / Brave / Opera",
  "safety": "regenerates",
  "category": "browsers"
 },
 {
  "match": [
   "~/Library/Caches/com.apple.Safari",
   "~/Library/Containers/com.apple.Safari/Data/Library/Caches"
  ],
  "title": {
   "en": "Safari cache",
   "tr": "Safari önbelleği",
   "es": "Caché de Safari",
   "de": "Safari-Cache"
  },
  "what": {
   "en": "Web content Safari stored to load sites faster; Safari refills it as you browse.",
   "tr": "Safari'nin siteleri daha hızlı açmak için sakladığı web içeriği; gezindikçe yeniden dolar.",
   "es": "Contenido web que Safari guarda para cargar webs más rápido; se rellena al navegar.",
   "de": "Webinhalte, die Safari für schnelleres Laden speichert; füllt sich beim Surfen wieder."
  },
  "by": "Apple Safari",
  "safety": "regenerates",
  "category": "browsers"
 },
 {
  "match": [
   "~/Library/Containers/com.apple.Safari"
  ],
  "title": {
   "en": "Safari container",
   "tr": "Safari kapsayıcısı",
   "es": "Contenedor de Safari",
   "de": "Safari-Container"
  },
  "what": {
   "en": "Safari's sandboxed data, such as website data, extension data and settings; its Caches subfolder can be cleared.",
   "tr": "Web sitesi verileri, uzantı verileri ve ayarlar gibi Safari'nin korumalı verileri; içindeki Caches klasörü temizlenebilir.",
   "es": "Datos aislados de Safari, como datos de sitios, de extensiones y ajustes; su subcarpeta Caches sí se puede vaciar.",
   "de": "Safaris abgeschottete Daten wie Website-, Erweiterungsdaten und Einstellungen; der Unterordner Caches kann geleert werden."
  },
  "by": "Apple Safari",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Application Support/Slack",
   "~/Library/Containers/com.tinyspeck.slackmacgap"
  ],
  "title": {
   "en": "Slack data",
   "tr": "Slack verileri",
   "es": "Datos de Slack",
   "de": "Slack-Daten"
  },
  "what": {
   "en": "Slack's sign-ins, settings and cached messages and files; your workspace data stays on Slack's servers.",
   "tr": "Slack oturumları, ayarları ve önbelleğe alınmış iletiler ve dosyalar; çalışma alanı verileriniz Slack sunucularında kalır.",
   "es": "Sesiones, ajustes y mensajes y archivos en caché de Slack; los datos de tu espacio de trabajo siguen en los servidores de Slack.",
   "de": "Anmeldungen, Einstellungen und zwischengespeicherte Nachrichten und Dateien von Slack; Workspace-Daten bleiben auf Slacks Servern."
  },
  "by": "Slack",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Application Support/discord"
  ],
  "title": {
   "en": "Discord data",
   "tr": "Discord verileri",
   "es": "Datos de Discord",
   "de": "Discord-Daten"
  },
  "what": {
   "en": "Discord's sign-in, settings, caches and app updates; chats stay on Discord's servers, and caches inside refill.",
   "tr": "Discord oturumu, ayarları, önbellekleri ve uygulama güncellemeleri; sohbetler Discord sunucularında kalır, önbellekler yeniden dolar.",
   "es": "Sesión, ajustes, cachés y actualizaciones de Discord; los chats siguen en sus servidores y las cachés se rellenan.",
   "de": "Anmeldung, Einstellungen, Caches und App-Updates von Discord; Chats bleiben auf Discords Servern, Caches füllen sich wieder."
  },
  "by": "Discord",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Application Support/Spotify"
  ],
  "title": {
   "en": "Spotify data",
   "tr": "Spotify verileri",
   "es": "Datos de Spotify",
   "de": "Spotify-Daten"
  },
  "what": {
   "en": "Spotify's settings, streaming cache and downloaded songs and podcasts; deleting removes your offline downloads.",
   "tr": "Spotify ayarları, akış önbelleği ve indirilmiş şarkılar ile podcast'ler; silmek çevrimdışı indirmelerinizi kaldırır.",
   "es": "Ajustes, caché de reproducción y canciones y pódcasts descargados de Spotify; borrarlo elimina tus descargas sin conexión.",
   "de": "Spotify-Einstellungen, Streaming-Cache und geladene Songs und Podcasts; Löschen entfernt deine Offline-Downloads."
  },
  "by": "Spotify",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Caches/com.spotify.client"
  ],
  "title": {
   "en": "Spotify cache",
   "tr": "Spotify önbelleği",
   "es": "Caché de Spotify",
   "de": "Spotify-Cache"
  },
  "what": {
   "en": "Cached app data and artwork from Spotify; Spotify refills it as you listen.",
   "tr": "Spotify'ın önbelleğe aldığı uygulama verileri ve kapak görselleri; dinledikçe yeniden dolar.",
   "es": "Datos de la app y portadas en caché de Spotify; se rellena mientras escuchas.",
   "de": "Zwischengespeicherte App-Daten und Cover von Spotify; füllt sich beim Hören wieder."
  },
  "by": "Spotify",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "~/Library/Application Support/Steam"
  ],
  "title": {
   "en": "Steam",
   "tr": "Steam",
   "es": "Steam",
   "de": "Steam"
  },
  "what": {
   "en": "Steam's client files, settings and installed games; uninstall games from the Steam library rather than deleting here.",
   "tr": "Steam istemci dosyaları, ayarları ve yüklü oyunlar; oyunları burada silmek yerine Steam kitaplığından kaldırın.",
   "es": "Archivos del cliente, ajustes y juegos instalados de Steam; desinstala los juegos desde la biblioteca de Steam, no aquí.",
   "de": "Steam-Clientdateien, Einstellungen und installierte Spiele; deinstalliere Spiele in der Steam-Bibliothek statt hier zu löschen."
  },
  "by": "Steam",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Application Support/Steam/steamapps"
  ],
  "title": {
   "en": "Steam games",
   "tr": "Steam oyunları",
   "es": "Juegos de Steam",
   "de": "Steam-Spiele"
  },
  "what": {
   "en": "Installed Steam games, often many GB each; uninstall ones you don't play from Steam, and redownload them anytime.",
   "tr": "Yüklü Steam oyunları, çoğu zaman her biri birkaç GB; oynamadıklarınızı Steam'den kaldırın, istediğiniz zaman yeniden indirebilirsiniz.",
   "es": "Juegos de Steam instalados, a menudo de muchos GB; desinstala desde Steam los que no juegues y vuelve a descargarlos cuando quieras.",
   "de": "Installierte Steam-Spiele, oft viele GB; deinstalliere ungespielte über Steam und lade sie jederzeit neu."
  },
  "by": "Steam",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Application Support/Adobe"
  ],
  "title": {
   "en": "Adobe app data",
   "tr": "Adobe uygulama verileri",
   "es": "Datos de apps de Adobe",
   "de": "Adobe-App-Daten"
  },
  "what": {
   "en": "Settings, presets, plug-ins and caches of Adobe apps; deleting can reset or break them.",
   "tr": "Adobe uygulamalarının ayarları, hazır ayarları, eklentileri ve önbellekleri; silmek bunları sıfırlayabilir veya bozabilir.",
   "es": "Ajustes, preajustes, complementos y cachés de las apps de Adobe; borrarlos puede restablecerlas o estropearlas.",
   "de": "Einstellungen, Vorgaben, Plug-ins und Caches von Adobe-Apps; Löschen kann sie zurücksetzen oder beschädigen."
  },
  "by": "Adobe",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Application Support/Adobe/Common/Media Cache Files",
   "~/Library/Application Support/Adobe/Common/Media Cache"
  ],
  "title": {
   "en": "Adobe media cache",
   "tr": "Adobe medya önbelleği",
   "es": "Caché de medios de Adobe",
   "de": "Adobe-Mediencache"
  },
  "what": {
   "en": "Audio and video preview files Premiere Pro and After Effects create for imported media; rebuilt when you reopen projects.",
   "tr": "Premiere Pro ve After Effects'in içe aktarılan medya için oluşturduğu ses ve video önizleme dosyaları; projeleri açınca yeniden oluşturulur.",
   "es": "Archivos de previsualización de audio y vídeo que crean Premiere Pro y After Effects; se regeneran al reabrir proyectos.",
   "de": "Audio- und Videovorschaudateien von Premiere Pro und After Effects für importierte Medien; beim Öffnen von Projekten neu erstellt."
  },
  "by": "Adobe",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "~/Library/Containers/com.microsoft.Word",
   "~/Library/Containers/com.microsoft.Excel",
   "~/Library/Containers/com.microsoft.Powerpoint",
   "~/Library/Containers/com.microsoft.Outlook"
  ],
  "title": {
   "en": "Microsoft Office app data",
   "tr": "Microsoft Office uygulama verileri",
   "es": "Datos de Microsoft Office",
   "de": "Microsoft-Office-App-Daten"
  },
  "what": {
   "en": "Settings, templates, autosaved files and caches of an Office app; deleting can lose unsaved work.",
   "tr": "Bir Office uygulamasının ayarları, şablonları, otomatik kaydedilen dosyaları ve önbellekleri; silmek kaydedilmemiş çalışmaları kaybettirebilir.",
   "es": "Ajustes, plantillas, archivos autoguardados y cachés de una app de Office; borrarlos puede perder trabajo sin guardar.",
   "de": "Einstellungen, Vorlagen, automatisch gesicherte Dateien und Caches einer Office-App; Löschen kann ungesicherte Arbeit kosten."
  },
  "by": "Microsoft Office",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Group Containers/UBF8T346G9.Office"
  ],
  "title": {
   "en": "Microsoft Office shared data",
   "tr": "Microsoft Office paylaşılan verileri",
   "es": "Datos compartidos de Office",
   "de": "Gemeinsame Office-Daten"
  },
  "what": {
   "en": "Data shared by Office apps, including Outlook's mailbox data and license info; deleting can lose mail and sign you out.",
   "tr": "Outlook posta verileri ve lisans bilgileri dahil Office uygulamalarının paylaştığı veriler; silmek postaları kaybettirebilir ve oturumu kapatabilir.",
   "es": "Datos que comparten las apps de Office, incluidos el correo de Outlook y la licencia; borrarlos puede perder correo y cerrar sesión.",
   "de": "Gemeinsame Daten der Office-Apps inklusive Outlook-Postfachdaten und Lizenz; Löschen kann Mails kosten und dich abmelden."
  },
  "by": "Microsoft Office",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Application Support/Google/DriveFS"
  ],
  "title": {
   "en": "Google Drive cache",
   "tr": "Google Drive önbelleği",
   "es": "Caché de Google Drive",
   "de": "Google-Drive-Cache"
  },
  "what": {
   "en": "Google Drive for desktop's local file cache and database; deleting can lose changes that haven't synced yet.",
   "tr": "Masaüstü için Google Drive'ın yerel dosya önbelleği ve veritabanı; silmek henüz eşzamanlanmamış değişiklikleri kaybettirebilir.",
   "es": "La caché local de archivos y la base de datos de Google Drive para ordenador; borrarla puede perder cambios aún sin sincronizar.",
   "de": "Lokaler Dateicache und Datenbank von Google Drive für den Desktop; Löschen kann noch nicht synchronisierte Änderungen kosten."
  },
  "by": "Google Drive",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Group Containers/group.net.whatsapp.WhatsApp.shared",
   "~/Library/Containers/net.whatsapp.WhatsApp"
  ],
  "title": {
   "en": "WhatsApp data",
   "tr": "WhatsApp verileri",
   "es": "Datos de WhatsApp",
   "de": "WhatsApp-Daten"
  },
  "what": {
   "en": "Your WhatsApp chats and the photos, videos and files in them on this Mac; clear media from WhatsApp's storage settings.",
   "tr": "Bu Mac'teki WhatsApp sohbetleriniz ve içlerindeki fotoğraflar, videolar ve dosyalar; medyayı WhatsApp depolama ayarlarından temizleyin.",
   "es": "Tus chats de WhatsApp en este Mac con sus fotos, vídeos y archivos; libera multimedia desde los ajustes de almacenamiento de WhatsApp.",
   "de": "Deine WhatsApp-Chats auf diesem Mac mit Fotos, Videos und Dateien; entferne Medien über die Speichereinstellungen von WhatsApp."
  },
  "by": "WhatsApp",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Containers/ru.keepcoder.Telegram"
  ],
  "title": {
   "en": "Telegram data",
   "tr": "Telegram verileri",
   "es": "Datos de Telegram",
   "de": "Telegram-Daten"
  },
  "what": {
   "en": "Telegram's account data and media cache; chats stay in the cloud, so clear the cache from Telegram's storage settings.",
   "tr": "Telegram hesap verileri ve medya önbelleği; sohbetler bulutta kalır, önbelleği Telegram depolama ayarlarından temizleyin.",
   "es": "Datos de cuenta y caché multimedia de Telegram; los chats siguen en la nube, así que vacía la caché desde sus ajustes de almacenamiento.",
   "de": "Accountdaten und Mediencache von Telegram; Chats bleiben in der Cloud, leere den Cache über die Speichereinstellungen."
  },
  "by": "Telegram",
  "safety": "review"
 },
 {
  "match": [
   "~/Library/Application Support/Postgres"
  ],
  "title": {
   "en": "Postgres.app databases",
   "tr": "Postgres.app veritabanları",
   "es": "Bases de datos de Postgres.app",
   "de": "Postgres.app-Datenbanken"
  },
  "what": {
   "en": "PostgreSQL database files created by Postgres.app; deleting destroys those databases.",
   "tr": "Postgres.app'in oluşturduğu PostgreSQL veritabanı dosyaları; silmek bu veritabanlarını yok eder.",
   "es": "Archivos de bases de datos PostgreSQL creados por Postgres.app; borrarlos destruye esas bases de datos.",
   "de": "Von Postgres.app angelegte PostgreSQL-Datenbankdateien; Löschen vernichtet diese Datenbanken."
  },
  "by": "Postgres.app",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Caches/com.apple.Music"
  ],
  "title": {
   "en": "Music app cache",
   "tr": "Müzik uygulaması önbelleği",
   "es": "Caché de la app Música",
   "de": "Cache der Musik-App"
  },
  "what": {
   "en": "Artwork and streaming data cached by the Music app; refilled as you use it.",
   "tr": "Müzik uygulamasının önbelleğe aldığı kapak görselleri ve akış verileri; kullandıkça yeniden dolar.",
   "es": "Portadas y datos de reproducción en caché de la app Música; se rellena al usarla.",
   "de": "Von der Musik-App zwischengespeicherte Cover und Streaming-Daten; füllt sich bei Nutzung wieder."
  },
  "by": "Apple Music",
  "safety": "regenerates",
  "category": "caches"
 },
 {
  "match": [
   "~/Library/Containers/com.apple.mediaanalysisd"
  ],
  "title": {
   "en": "Media analysis",
   "tr": "Medya analizi",
   "es": "Análisis multimedia",
   "de": "Medienanalyse"
  },
  "what": {
   "en": "Results of macOS analyzing your photos and videos for search and Visual Look Up; its Caches subfolder can grow large and is rebuilt.",
   "tr": "macOS'in arama ve Görsel Arama için fotoğraf ve videolarınızı analiz etme sonuçları; Caches alt klasörü büyüyebilir ve yeniden oluşturulur.",
   "es": "Resultados del análisis de tus fotos y vídeos que hace macOS para búsqueda y Buscar con imágenes; su subcarpeta Caches puede crecer y se regenera.",
   "de": "Ergebnisse der macOS-Analyse deiner Fotos und Videos für Suche und visuelles Nachschlagen; der Unterordner Caches kann groß werden und entsteht neu."
  },
  "by": "macOS",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Containers/com.apple.photoanalysisd"
  ],
  "title": {
   "en": "Photo analysis",
   "tr": "Fotoğraf analizi",
   "es": "Análisis de fotos",
   "de": "Fotoanalyse"
  },
  "what": {
   "en": "Data from Photos' background analysis of people, scenes and memories; managed by macOS.",
   "tr": "Fotoğraflar'ın kişiler, sahneler ve anılar için arka plan analizinin verileri; macOS tarafından yönetilir.",
   "es": "Datos del análisis en segundo plano de Fotos sobre personas, escenas y recuerdos; los gestiona macOS.",
   "de": "Daten der Hintergrundanalyse von Fotos zu Personen, Szenen und Rückblicken; von macOS verwaltet."
  },
  "by": "Apple Photos",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Containers/com.apple.iChat"
  ],
  "title": {
   "en": "Messages app container",
   "tr": "Mesajlar uygulama kapsayıcısı",
   "es": "Contenedor de Mensajes",
   "de": "Nachrichten-Container"
  },
  "what": {
   "en": "Settings and support data of the Messages app; your chats themselves live in ~/Library/Messages.",
   "tr": "Mesajlar uygulamasının ayarları ve destek verileri; sohbetlerinizin kendisi ~/Library/Messages içindedir.",
   "es": "Ajustes y datos auxiliares de la app Mensajes; tus chats están en ~/Library/Messages.",
   "de": "Einstellungen und Hilfsdaten der Nachrichten-App; deine Chats selbst liegen in ~/Library/Messages."
  },
  "by": "Apple Messages",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Containers/com.apple.Notes",
   "~/Library/Group Containers/group.com.apple.notes"
  ],
  "title": {
   "en": "Notes",
   "tr": "Notlar",
   "es": "Notas",
   "de": "Notizen"
  },
  "what": {
   "en": "Your Notes database with notes, attachments and drawings; deleting can lose notes not stored in iCloud.",
   "tr": "Notlar, ekler ve çizimlerle Notlar veritabanınız; silmek iCloud'da olmayan notları kaybettirebilir.",
   "es": "Tu base de datos de Notas con notas, adjuntos y dibujos; borrarla puede perder notas que no estén en iCloud.",
   "de": "Deine Notizen-Datenbank mit Notizen, Anhängen und Zeichnungen; Löschen kann Notizen kosten, die nicht in iCloud liegen."
  },
  "by": "Apple Notes",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Group Containers/group.com.apple.reminders"
  ],
  "title": {
   "en": "Reminders",
   "tr": "Anımsatıcılar",
   "es": "Recordatorios",
   "de": "Erinnerungen"
  },
  "what": {
   "en": "Your Reminders database; deleting can lose reminders not stored in iCloud.",
   "tr": "Anımsatıcılar veritabanınız; silmek iCloud'da olmayan anımsatıcıları kaybettirebilir.",
   "es": "Tu base de datos de Recordatorios; borrarla puede perder recordatorios que no estén en iCloud.",
   "de": "Deine Erinnerungen-Datenbank; Löschen kann Erinnerungen kosten, die nicht in iCloud liegen."
  },
  "by": "Apple Reminders",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Group Containers/group.com.apple.VoiceMemos.shared"
  ],
  "title": {
   "en": "Voice Memos",
   "tr": "Sesli Notlar",
   "es": "Notas de Voz",
   "de": "Sprachmemos"
  },
  "what": {
   "en": "Your Voice Memos recordings; deleting removes recordings that aren't synced elsewhere.",
   "tr": "Sesli Notlar kayıtlarınız; silmek başka yerde eşzamanlanmamış kayıtları kaldırır.",
   "es": "Tus grabaciones de Notas de Voz; borrarlas elimina las que no estén sincronizadas en otro sitio.",
   "de": "Deine Sprachmemo-Aufnahmen; Löschen entfernt Aufnahmen, die nicht anderswo synchronisiert sind."
  },
  "by": "Apple Voice Memos",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Containers/com.apple.TV"
  ],
  "title": {
   "en": "TV app data",
   "tr": "TV uygulaması verileri",
   "es": "Datos de la app TV",
   "de": "TV-App-Daten"
  },
  "what": {
   "en": "Settings, artwork and streaming data of the TV app; manage downloaded movies and shows in the TV app.",
   "tr": "TV uygulamasının ayarları, kapak görselleri ve akış verileri; indirilen film ve dizileri TV uygulamasından yönetin.",
   "es": "Ajustes, portadas y datos de reproducción de la app TV; gestiona las películas y series descargadas desde la app TV.",
   "de": "Einstellungen, Cover und Streaming-Daten der TV-App; verwalte geladene Filme und Serien in der TV-App."
  },
  "by": "Apple TV app",
  "safety": "keep"
 },
 {
  "match": [
   "~/Library/Containers/com.apple.podcasts",
   "~/Library/Group Containers/243LU875E5.groups.com.apple.podcasts"
  ],
  "title": {
   "en": "Podcasts data",
   "tr": "Podcast'ler verileri",
   "es": "Datos de Podcasts",
   "de": "Podcasts-Daten"
  },
  "what": {
   "en": "Podcasts library and downloaded episodes, which can add up; remove downloads in Podcasts or let it delete played episodes.",
   "tr": "Podcast'ler arşivi ve indirilmiş bölümler, birikebilir; indirmeleri Podcast'ler'den kaldırın veya oynatılanları otomatik sildirin.",
   "es": "La biblioteca de Podcasts y los episodios descargados, que se acumulan; elimina descargas en Podcasts o deja que borre los escuchados.",
   "de": "Podcasts-Mediathek und geladene Folgen, die sich summieren; entferne Downloads in Podcasts oder lass gehörte Folgen löschen."
  },
  "by": "Apple Podcasts",
  "safety": "review"
 },
 {
  "match": [
   "*/*.photoslibrary"
  ],
  "title": {
   "en": "Photos library",
   "tr": "Fotoğraflar arşivi",
   "es": "Fototeca de Fotos",
   "de": "Fotos-Mediathek"
  },
  "what": {
   "en": "A Photos library with your photos, videos, edits and albums; never delete files inside it, manage it in Photos.",
   "tr": "Fotoğraflarınız, videolarınız, düzenlemeleriniz ve albümlerinizle bir Fotoğraflar arşivi; içindeki dosyaları asla silmeyin, Fotoğraflar'dan yönetin.",
   "es": "Una fototeca de Fotos con tus fotos, vídeos, ediciones y álbumes; nunca borres archivos de dentro, gestiónala en Fotos.",
   "de": "Eine Fotos-Mediathek mit deinen Fotos, Videos, Bearbeitungen und Alben; lösche nie Dateien darin, verwalte sie in Fotos."
  },
  "by": "Apple Photos",
  "safety": "keep"
 },
 {
  "match": [
   "~/Music/Music",
   "~/Music/iTunes"
  ],
  "title": {
   "en": "Music library",
   "tr": "Müzik arşivi",
   "es": "Biblioteca de Música",
   "de": "Musikmediathek"
  },
  "what": {
   "en": "Your Music (formerly iTunes) library with its songs and database; manage it in the Music app.",
   "tr": "Şarkıları ve veritabanıyla Müzik (eski adıyla iTunes) arşiviniz; Müzik uygulamasından yönetin.",
   "es": "Tu biblioteca de Música (antes iTunes) con sus canciones y base de datos; gestiónala en la app Música.",
   "de": "Deine Musik-Mediathek (früher iTunes) mit Songs und Datenbank; verwalte sie in der Musik-App."
  },
  "by": "Apple Music",
  "safety": "keep"
 },
 {
  "match": [
   "~/Music/GarageBand"
  ],
  "title": {
   "en": "GarageBand projects",
   "tr": "GarageBand projeleri",
   "es": "Proyectos de GarageBand",
   "de": "GarageBand-Projekte"
  },
  "what": {
   "en": "Your GarageBand songs and projects.",
   "tr": "GarageBand şarkılarınız ve projeleriniz.",
   "es": "Tus canciones y proyectos de GarageBand.",
   "de": "Deine GarageBand-Songs und Projekte."
  },
  "by": "Apple GarageBand",
  "safety": "keep"
 },
 {
  "match": [
   "~/Movies/TV"
  ],
  "title": {
   "en": "TV media",
   "tr": "TV medyası",
   "es": "Contenido de TV",
   "de": "TV-Medien"
  },
  "what": {
   "en": "Movies and shows downloaded or imported in the TV app, including home videos; manage them in the TV app.",
   "tr": "TV uygulamasında indirilen veya içe aktarılan, ev videoları dahil film ve diziler; TV uygulamasından yönetin.",
   "es": "Películas y series descargadas o importadas en la app TV, incluidos vídeos caseros; gestiónalas en la app TV.",
   "de": "In der TV-App geladene oder importierte Filme und Serien, auch eigene Videos; verwalte sie in der TV-App."
  },
  "by": "Apple TV app",
  "safety": "keep"
 },
 {
  "match": [
   "*/*.imovielibrary"
  ],
  "title": {
   "en": "iMovie library",
   "tr": "iMovie arşivi",
   "es": "Biblioteca de iMovie",
   "de": "iMovie-Mediathek"
  },
  "what": {
   "en": "Your iMovie projects and imported clips; render files inside can be deleted from iMovie's settings.",
   "tr": "iMovie projeleriniz ve içe aktarılan klipler; içindeki işleme dosyaları iMovie ayarlarından silinebilir.",
   "es": "Tus proyectos de iMovie y los clips importados; los archivos de renderizado se pueden borrar desde los ajustes de iMovie.",
   "de": "Deine iMovie-Projekte und importierten Clips; Render-Dateien darin lassen sich in den iMovie-Einstellungen löschen."
  },
  "by": "Apple iMovie",
  "safety": "keep"
 },
 {
  "match": [
   "*/*.fcpbundle"
  ],
  "title": {
   "en": "Final Cut Pro library",
   "tr": "Final Cut Pro arşivi",
   "es": "Biblioteca de Final Cut Pro",
   "de": "Final-Cut-Pro-Mediathek"
  },
  "what": {
   "en": "A Final Cut Pro library with events, projects and media; delete generated files from Final Cut Pro's File menu instead.",
   "tr": "Etkinlikler, projeler ve medyayla bir Final Cut Pro arşivi; oluşturulan dosyaları bunun yerine Final Cut Pro'nun Dosya menüsünden silin.",
   "es": "Una biblioteca de Final Cut Pro con eventos, proyectos y contenido; borra los archivos generados desde el menú Archivo de Final Cut Pro.",
   "de": "Eine Final-Cut-Pro-Mediathek mit Ereignissen, Projekten und Medien; lösche generierte Dateien stattdessen über das Ablage-Menü."
  },
  "by": "Apple Final Cut Pro",
  "safety": "keep"
 },
 {
  "match": [
   "*/node_modules"
  ],
  "title": {
   "en": "node_modules",
   "tr": "node_modules",
   "es": "node_modules",
   "de": "node_modules"
  },
  "what": {
   "en": "A JavaScript project's installed packages; “npm install” (or yarn/pnpm) recreates it from the lockfile.",
   "tr": "Bir JavaScript projesinin yüklü paketleri; “npm install” (veya yarn/pnpm) kilit dosyasından yeniden oluşturur.",
   "es": "Los paquetes instalados de un proyecto JavaScript; “npm install” (o yarn/pnpm) lo recrea a partir del lockfile.",
   "de": "Die installierten Pakete eines JavaScript-Projekts; „npm install“ (oder yarn/pnpm) erstellt sie aus der Lockdatei neu."
  },
  "by": "npm / Yarn / pnpm",
  "safety": "regenerates",
  "category": "projects"
 },
 {
  "match": [
   "*/.venv",
   "*/venv"
  ],
  "title": {
   "en": "Python virtual environment",
   "tr": "Python sanal ortamı",
   "es": "Entorno virtual de Python",
   "de": "Virtuelle Python-Umgebung"
  },
  "what": {
   "en": "A project's Python environment with its installed packages; recreate it from requirements.txt or pyproject.toml.",
   "tr": "Bir projenin yüklü paketleriyle Python ortamı; requirements.txt veya pyproject.toml dosyasından yeniden oluşturun.",
   "es": "El entorno de Python de un proyecto con sus paquetes; recréalo desde requirements.txt o pyproject.toml.",
   "de": "Die Python-Umgebung eines Projekts mit installierten Paketen; erstelle sie aus requirements.txt oder pyproject.toml neu."
  },
  "by": "Python",
  "safety": "regenerates",
  "category": "projects"
 },
 {
  "match": [
   "*/__pycache__"
  ],
  "title": {
   "en": "Python bytecode cache",
   "tr": "Python bayt kodu önbelleği",
   "es": "Caché de bytecode de Python",
   "de": "Python-Bytecode-Cache"
  },
  "what": {
   "en": "Compiled .pyc files Python writes next to your code; recreated automatically the next time the code runs.",
   "tr": "Python'un kodunuzun yanına yazdığı derlenmiş .pyc dosyaları; kod bir sonraki çalıştığında otomatik oluşturulur.",
   "es": "Archivos .pyc compilados que Python escribe junto a tu código; se recrean solos la próxima vez que se ejecute.",
   "de": "Kompilierte .pyc-Dateien, die Python neben deinen Code schreibt; beim nächsten Ausführen automatisch neu erstellt."
  },
  "by": "Python",
  "safety": "regenerates",
  "category": "projects"
 },
 {
  "match": [
   "*/.pytest_cache",
   "*/.mypy_cache",
   "*/.ruff_cache",
   "*/.tox"
  ],
  "title": {
   "en": "Python tool caches",
   "tr": "Python araç önbellekleri",
   "es": "Cachés de herramientas Python",
   "de": "Python-Tool-Caches"
  },
  "what": {
   "en": "Caches and test environments of pytest, mypy, Ruff or tox; recreated on the next run.",
   "tr": "pytest, mypy, Ruff veya tox önbellekleri ve test ortamları; bir sonraki çalıştırmada yeniden oluşturulur.",
   "es": "Cachés y entornos de prueba de pytest, mypy, Ruff o tox; se recrean en la siguiente ejecución.",
   "de": "Caches und Testumgebungen von pytest, mypy, Ruff oder tox; beim nächsten Lauf neu erstellt."
  },
  "by": "Python tools",
  "safety": "regenerates",
  "category": "projects"
 },
 {
  "match": [
   "*/.next",
   "*/.nuxt",
   "*/.svelte-kit",
   "*/.angular",
   "*/.parcel-cache",
   "*/.turbo",
   "*/.docusaurus"
  ],
  "title": {
   "en": "Web build cache",
   "tr": "Web derleme önbelleği",
   "es": "Caché de compilación web",
   "de": "Web-Build-Cache"
  },
  "what": {
   "en": "Build output and caches of Next.js, Nuxt, SvelteKit, Angular, Parcel, Turborepo or Docusaurus; rebuilt on the next dev or build run.",
   "tr": "Next.js, Nuxt, SvelteKit, Angular, Parcel, Turborepo veya Docusaurus derleme çıktıları ve önbellekleri; bir sonraki dev veya build ile yeniden oluşur.",
   "es": "Salida de compilación y cachés de Next.js, Nuxt, SvelteKit, Angular, Parcel, Turborepo o Docusaurus; se regeneran al compilar de nuevo.",
   "de": "Build-Ausgaben und Caches von Next.js, Nuxt, SvelteKit, Angular, Parcel, Turborepo oder Docusaurus; beim nächsten Dev- oder Build-Lauf neu erstellt."
  },
  "by": "Web frameworks",
  "safety": "regenerates",
  "category": "projects"
 },
 {
  "match": [
   "*/target"
  ],
  "title": {
   "en": "Build output (target)",
   "tr": "Derleme çıktısı (target)",
   "es": "Salida de compilación (target)",
   "de": "Build-Ausgabe (target)"
  },
  "what": {
   "en": "In Rust and Maven projects, compiled output rebuilt by the next build; elsewhere a folder named “target” may be anything, so check first.",
   "tr": "Rust ve Maven projelerinde bir sonraki derlemede yeniden oluşan derleme çıktısı; başka yerlerde “target” adlı klasör her şey olabilir, önce kontrol edin.",
   "es": "En proyectos Rust y Maven, salida compilada que se regenera al compilar; en otros sitios una carpeta “target” puede ser cualquier cosa, revísala.",
   "de": "In Rust- und Maven-Projekten Build-Ausgabe, die der nächste Build neu erzeugt; anderswo kann ein Ordner „target“ alles sein – erst prüfen."
  },
  "by": "Cargo / Maven",
  "safety": "review",
  "category": "projects"
 },
 {
  "match": [
   "*/build"
  ],
  "title": {
   "en": "Build folder",
   "tr": "Derleme klasörü",
   "es": "Carpeta build",
   "de": "Build-Ordner"
  },
  "what": {
   "en": "Usually build output from Gradle, CMake, Flutter, webpack and others that the next build recreates; check it's not hand-made content.",
   "tr": "Genellikle Gradle, CMake, Flutter, webpack ve benzerlerinin sonraki derlemede yeniden oluşan çıktısı; elle oluşturulmuş içerik olmadığını kontrol edin.",
   "es": "Normalmente salida de Gradle, CMake, Flutter, webpack y otros que se recrea al compilar; comprueba que no sea contenido hecho a mano.",
   "de": "Meist Build-Ausgabe von Gradle, CMake, Flutter, webpack u. a., die der nächste Build neu erzeugt; prüfe, dass es kein eigener Inhalt ist."
  },
  "by": "Build tools",
  "safety": "review",
  "category": "projects"
 },
 {
  "match": [
   "*/dist"
  ],
  "title": {
   "en": "Distribution folder (dist)",
   "tr": "Dağıtım klasörü (dist)",
   "es": "Carpeta de distribución (dist)",
   "de": "Distributionsordner (dist)"
  },
  "what": {
   "en": "Usually packaged build output that a build recreates, but it may hold release files you want to keep.",
   "tr": "Genellikle bir derlemenin yeniden oluşturduğu paketlenmiş çıktı, ancak saklamak istediğiniz sürüm dosyalarını içerebilir.",
   "es": "Normalmente salida empaquetada que se recrea al compilar, pero puede contener versiones publicadas que quieras conservar.",
   "de": "Meist paketierte Build-Ausgabe, die neu erzeugt werden kann, kann aber Release-Dateien enthalten, die du behalten willst."
  },
  "by": "Build tools",
  "safety": "review",
  "category": "projects"
 },
 {
  "match": [
   "*/.gradle"
  ],
  "title": {
   "en": "Project Gradle cache",
   "tr": "Proje Gradle önbelleği",
   "es": "Caché de Gradle del proyecto",
   "de": "Gradle-Projektcache"
  },
  "what": {
   "en": "Gradle's per-project build cache and state; recreated on the next build.",
   "tr": "Gradle'ın proje başına derleme önbelleği ve durumu; bir sonraki derlemede yeniden oluşturulur.",
   "es": "La caché y el estado de compilación de Gradle de cada proyecto; se recrean en la siguiente compilación.",
   "de": "Gradles projektbezogener Build-Cache und Status; beim nächsten Build neu erstellt."
  },
  "by": "Gradle",
  "safety": "regenerates",
  "category": "projects"
 },
 {
  "match": [
   "*/DerivedData"
  ],
  "title": {
   "en": "Xcode DerivedData (custom)",
   "tr": "Xcode DerivedData (özel)",
   "es": "DerivedData de Xcode (personalizado)",
   "de": "Xcode-DerivedData (eigener Ort)"
  },
  "what": {
   "en": "Xcode build products and indexes stored in a custom location; Xcode recreates them on the next build.",
   "tr": "Özel bir konumda saklanan Xcode derleme çıktıları ve dizinleri; Xcode bir sonraki derlemede yeniden oluşturur.",
   "es": "Productos de compilación e índices de Xcode guardados en una ubicación personalizada; Xcode los recrea al compilar.",
   "de": "Xcode-Build-Produkte und Indizes an einem eigenen Ort; Xcode erstellt sie beim nächsten Build neu."
  },
  "by": "Apple Xcode",
  "safety": "regenerates",
  "category": "xcode"
 },
 {
  "match": [
   "*/Pods"
  ],
  "title": {
   "en": "CocoaPods dependencies",
   "tr": "CocoaPods bağımlılıkları",
   "es": "Dependencias de CocoaPods",
   "de": "CocoaPods-Abhängigkeiten"
  },
  "what": {
   "en": "Libraries CocoaPods installed into an iOS or macOS project; “pod install” recreates them from the Podfile.lock.",
   "tr": "CocoaPods'un bir iOS veya macOS projesine yüklediği kitaplıklar; “pod install” bunları Podfile.lock'tan yeniden oluşturur.",
   "es": "Bibliotecas que CocoaPods instaló en un proyecto iOS o macOS; “pod install” las recrea a partir del Podfile.lock.",
   "de": "Von CocoaPods in ein iOS- oder macOS-Projekt installierte Bibliotheken; „pod install“ erstellt sie aus Podfile.lock neu."
  },
  "by": "CocoaPods",
  "safety": "regenerates",
  "category": "projects"
 },
 {
  "match": [
   "*/.build"
  ],
  "title": {
   "en": "Swift package build",
   "tr": "Swift paket derlemesi",
   "es": "Compilación de paquete Swift",
   "de": "Swift-Paket-Build"
  },
  "what": {
   "en": "Build output and checked-out dependencies of a Swift package; recreated by the next “swift build”.",
   "tr": "Bir Swift paketinin derleme çıktısı ve indirilmiş bağımlılıkları; bir sonraki “swift build” ile yeniden oluşturulur.",
   "es": "Salida de compilación y dependencias descargadas de un paquete Swift; se recrean con el siguiente “swift build”.",
   "de": "Build-Ausgabe und ausgecheckte Abhängigkeiten eines Swift-Pakets; beim nächsten „swift build“ neu erstellt."
  },
  "by": "Swift Package Manager",
  "safety": "regenerates",
  "category": "projects"
 },
 {
  "match": [
   "*/.dart_tool"
  ],
  "title": {
   "en": "Dart tool cache",
   "tr": "Dart araç önbelleği",
   "es": "Caché de herramientas de Dart",
   "de": "Dart-Tool-Cache"
  },
  "what": {
   "en": "Package config and build caches of a Dart or Flutter project; recreated by “flutter pub get” or the next build.",
   "tr": "Bir Dart veya Flutter projesinin paket yapılandırması ve derleme önbellekleri; “flutter pub get” veya sonraki derleme ile yeniden oluşturulur.",
   "es": "Configuración de paquetes y cachés de compilación de un proyecto Dart o Flutter; se recrean con “flutter pub get” o al compilar.",
   "de": "Paketkonfiguration und Build-Caches eines Dart- oder Flutter-Projekts; durch „flutter pub get“ oder den nächsten Build neu erstellt."
  },
  "by": "Dart / Flutter",
  "safety": "regenerates",
  "category": "projects"
 },
 {
  "match": [
   "*/.terraform"
  ],
  "title": {
   "en": "Terraform working directory",
   "tr": "Terraform çalışma dizini",
   "es": "Directorio de trabajo de Terraform",
   "de": "Terraform-Arbeitsverzeichnis"
  },
  "what": {
   "en": "Providers and modules downloaded for a Terraform configuration; recreated by “terraform init”.",
   "tr": "Bir Terraform yapılandırması için indirilen sağlayıcılar ve modüller; “terraform init” ile yeniden oluşturulur.",
   "es": "Proveedores y módulos descargados para una configuración de Terraform; se recrean con “terraform init”.",
   "de": "Für eine Terraform-Konfiguration geladene Provider und Module; durch „terraform init“ neu erstellt."
  },
  "by": "Terraform",
  "safety": "regenerates",
  "category": "projects"
 },
 {
  "match": [
   "*/cmake-build-*",
   "*/.cxx"
  ],
  "title": {
   "en": "C/C++ build folder",
   "tr": "C/C++ derleme klasörü",
   "es": "Carpeta de compilación C/C++",
   "de": "C/C++-Build-Ordner"
  },
  "what": {
   "en": "CMake build output created by CLion or Android Studio's native builds; recreated on the next build.",
   "tr": "CLion veya Android Studio yerel derlemelerinin oluşturduğu CMake derleme çıktısı; bir sonraki derlemede yeniden oluşturulur.",
   "es": "Salida de compilación CMake creada por CLion o las compilaciones nativas de Android Studio; se recrea al compilar.",
   "de": "CMake-Build-Ausgabe von CLion oder nativen Android-Studio-Builds; beim nächsten Build neu erstellt."
  },
  "by": "CLion / Android NDK",
  "safety": "regenerates",
  "category": "projects"
 },
 {
  "match": [
   "*/vendor"
  ],
  "title": {
   "en": "Vendored dependencies",
   "tr": "Projeye dahil bağımlılıklar",
   "es": "Dependencias incluidas (vendor)",
   "de": "Mitgelieferte Abhängigkeiten"
  },
  "what": {
   "en": "Third-party code bundled with a project; Composer recreates it, but in Go and other projects it may be committed on purpose.",
   "tr": "Bir projeyle birlikte gelen üçüncü taraf kod; Composer yeniden oluşturur, ancak Go ve diğer projelerde bilerek eklenmiş olabilir.",
   "es": "Código de terceros incluido en un proyecto; Composer lo recrea, pero en Go y otros proyectos puede estar incluido a propósito.",
   "de": "Mit einem Projekt gebündelter Fremdcode; Composer erstellt ihn neu, in Go- und anderen Projekten kann er aber bewusst eingecheckt sein."
  },
  "by": "Composer / Go / Bundler",
  "safety": "review",
  "category": "projects"
 },
 {
  "match": [
   "*/.git"
  ],
  "title": {
   "en": "Git repository",
   "tr": "Git deposu",
   "es": "Repositorio Git",
   "de": "Git-Repository"
  },
  "what": {
   "en": "The full version history of a project; deleting it loses all commits and branches that aren't pushed elsewhere.",
   "tr": "Bir projenin tüm sürüm geçmişi; silmek başka yere gönderilmemiş tüm commit'leri ve dalları kaybettirir.",
   "es": "El historial de versiones completo de un proyecto; borrarlo pierde todos los commits y ramas que no estén subidos a otro sitio.",
   "de": "Die vollständige Versionsgeschichte eines Projekts; Löschen kostet alle Commits und Branches, die nicht anderswo gepusht sind."
  },
  "by": "Git",
  "safety": "keep"
 }
]
"""#
}
