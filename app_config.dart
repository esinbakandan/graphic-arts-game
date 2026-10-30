/// Uygulama ayarları. Değerleri README'deki adımlara göre doldurun.
class AppConfig {
  static const appName = 'Graphic Arts Game';

  /// Firebase konsolundan alınan Web client ID (Google ile giriş için Android'de gerekir).
  /// Boş bırakılırsa Android'de Google girişi çalışmayabilir.
  static const googleServerClientId = '';

  /// Çok oyunculu oyunda her soru için süre (saniye).
  static const liveSeconds = 20;

  /// Bir oyunda en fazla kaç soru sorulur.
  static const liveQuestions = 10;
}
