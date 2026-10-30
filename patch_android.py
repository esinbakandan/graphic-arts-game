"""CI'da `flutter create` sonrası Android ayarlarını yapar (Facebook + izinler)."""
import os, re, sys
app_id = os.environ.get("FB_APP_ID") or "0000000000"   # Secret yoksa yer tutucu (Facebook girişi çalışmaz ama uygulama açılır)
token = os.environ.get("FB_CLIENT_TOKEN") or "00000000000000000000000000000000"
man = "android/app/src/main/AndroidManifest.xml"
s = open(man, encoding="utf-8").read()
if "INTERNET" not in s:
    s = s.replace("<application", '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)
if app_id and "facebook.sdk.ApplicationId" not in s:
    meta = ('<meta-data android:name="com.facebook.sdk.ApplicationId" android:value="@string/facebook_app_id"/>\n'
            '        <meta-data android:name="com.facebook.sdk.ClientToken" android:value="@string/facebook_client_token"/>\n        ')
    s = s.replace("<activity", meta + "<activity", 1)
open(man, "w", encoding="utf-8").write(s)
if app_id:
    d = "android/app/src/main/res/values"
    os.makedirs(d, exist_ok=True)
    open(d + "/facebook.xml", "w", encoding="utf-8").write(
        f'<?xml version="1.0" encoding="utf-8"?>\n<resources>\n<string name="facebook_app_id">{app_id}</string>\n'
        f'<string name="facebook_client_token">{token}</string>\n</resources>\n')
# minSdk 23 (Firebase için)
for g in ("android/app/build.gradle", "android/app/build.gradle.kts"):
    if os.path.exists(g):
        t = open(g, encoding="utf-8").read()
        t = re.sub(r"minSdk(Version)?\s*=?\s*(flutter\.minSdkVersion|\d+)", "minSdk = 23", t)
        open(g, "w", encoding="utf-8").write(t)
print("android patched")
