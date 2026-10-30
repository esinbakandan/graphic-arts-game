# Graphic Arts Game

ATA AÖF Grafik Sanatları sınav hazırlığı: tek başına çalışma + arkadaşlarla canlı yarışma (Flutter + Firebase).
1915 soru, 6 ders (Genel Sanat Tarihi, Temel Bilgi Teknolojileri 1, İletişime Giriş, Temel Fotoğrafçılık, Temel Tasarım 1, Yabancı Dil 1).
GitHub Actions ile Android APK, web ve (isteğe bağlı) Windows/Linux sürümleri derlenir.

> **Durum:** Kod henüz bir Flutter SDK'sında derlenip çalıştırılmadı (hazırlandığı ortamda Flutter indirilemedi).
> İlk GitHub Actions çalışmasında küçük derleme hataları çıkabilir; hata metnini kopyalayıp düzeltmesini iste.

## 1. GitHub'a yükle ve APK'yı derle (Firebase gerekmez)
1. github.com'da hesap aç, **New repository** ile `graphic-arts-game` adında **Public** bir repo oluştur.
2. Zip'i çıkar. İçindeki dosyaları (`.github`, `.gitignore` gizli dosyalar dahil) repoya sürükle-bırak yükle ve **Commit changes** de.
3. **Actions** sekmesinde "Build" çalışır (~10 dk). Yeşil tik olunca çalıştırmayı aç, **Artifacts** bölümünden `android-and-web` dosyasını indir; içinde `app-release.apk` vardır.
4. APK'yı telefona gönder, "bilinmeyen kaynaklardan yükleme"ye izin ver ve kur. Firebase ayarlanmadıysa uygulama çevrimdışı tek oyunculu açılır.
5. `v1.0.0` gibi bir etiket (tag) oluşturursan APK ayrıca **Releases** bölümüne eklenir.

**Önemli (güncelleme):** Her derleme farklı bir geçici imza anahtarıyla imzalanır. Yeni APK'yı kurmadan önce telefondaki eski sürümü **kaldır**; aksi halde "paket çakışıyor" hatası alırsın. Kalıcı imza anahtarı eklenebilir (istersen iste).

## 2. Firebase ile çok oyunculu mod, giriş, haftalık liste, hata bildirimi
1. console.firebase.google.com > **Proje oluştur** (`graphic-arts-game`).
2. **Build > Authentication > Get started > Sign-in method**: **Anonymous** (misafir girişi) etkinleştir. Google/Facebook için bkz. bölüm 4.
3. **Build > Firestore Database > Create database** (Production mode). **Rules** sekmesine `firestore.rules` dosyasının içeriğini yapıştır ve **Publish** de.
4. **Proje ayarları (dişli) > Your apps**: bir **Web (</>)** uygulaması ve bir **Android** uygulaması ekle (Android paket adı: `com.example.graphic_arts_game`). Gösterilen değerleri (`apiKey`, `appId`, `messagingSenderId`, `projectId`) `lib/firebase_options.dart` içindeki "BURAYA_..." yerlerine yaz. (GitHub'da dosyayı aç, kalem simgesiyle düzenle, commit et.)
5. Actions yeniden derler; yeni APK'yı kur (önce eskisini kaldır). **Birlikte oyna** artık çalışır: bir kişi oda açar, **5 karakterli kodu** paylaşır, diğerleri katılır.

Masaüstü (Windows/Linux) sürümü yalnızca tek oyunculudur; bilgisayarda çok oyunculu oynamak için web sürümünü kullan (web.zip'i bir web sunucusuna / GitHub Pages'e koy ve Firebase Authentication > Settings > **Authorized domains** listesine alan adını ekle).

## 3. Hata bildirimleri ve yönetici
- Her sorunun altında **Hata bildir** düğmesi vardır (isteğe bağlı ekran görüntüsü + isteğe bağlı açıklama). Gönderilince şu mesaj gösterilir: "Geri bildirimin için teşekkürler! En kısa sürede inceleyip gerekli düzeltmeleri yapacağız. İyi çalışmalar! 😇"
- Bildirimler Firestore `reports` koleksiyonuna, gönderenin adı, e-postası (misafirse "misafir") ve uid'si ile kaydedilir. Bildirim için internet ve giriş (misafir girişi de olur) gerekir.
- **Yönetici olmak (kullanıcı adı/şifre yoktur; yetki hesabına bağlıdır):** uygulamada bir kez giriş yap > Firebase Console > Authentication > Users'tan kendi **UID**'ni kopyala > Firestore Database > **Start collection** > Collection ID: `admins` > Document ID: kopyaladığın UID > bir alan ekle (örn. `ok` = `true`) > Save. Uygulamayı yeniden aç; ana ekranda "Hata bildirimleri (yönetici)" kartı çıkar.
- `tool/belirsiz_sorular.json`: yapay zekânın açıklamasından emin olmadığı 134 sorunun kimlikleri. Açıklamalar yapay zekâ ile yazıldı ve ders kitaplarına karşı doğrulanmadı; önce bunları kontrol et.

## 4. Google ve Facebook girişi (isteğe bağlı, ileri seviye)
- **Google:** Firebase > Authentication > Google'ı etkinleştir. Web'de çalışır. Android'de, APK'nın imza parmak izi (SHA-1) Firebase'e kayıtlı olmalıdır; her derleme farklı anahtar kullandığı için kalıcı imza anahtarı eklenmeden Android'de Google girişi çalışmaz (misafir girişi çalışır).
- **Facebook:** developers.facebook.com'da uygulama aç; App ID ve Client Token'ı GitHub > Settings > Secrets and variables > Actions altına `FB_APP_ID` ve `FB_CLIENT_TOKEN` olarak ekle; Firebase'de Facebook sağlayıcısını etkinleştir. Facebook uygulaması "canlı" moda alınana kadar yalnızca test kullanıcıları girebilir.

## Dosya yapısı
- `assets/questions.json` soru bankası; `lib/` uygulama kodu; `firestore.rules` veritabanı kuralları; `.github/workflows/build.yml` derleme; `tool/patch_android.py` derleme sırasında Android ayarlarını yapar.
