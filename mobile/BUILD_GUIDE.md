# B.T.S. Elektrik TrafoReport - Android Release Build & Signing Guide

Bu doküman, saha tabletlerine kurulacak olan Release (Üretim) APK dosyasının imzalanması ve derlenmesi adımlarını açıklar.

## 1. Keystore (İmza Dosyası) Oluşturma
Terminal üzerinden projenin ana dizininde aşağıdaki komutu çalıştırarak bir imza anahtarı (`key.jks`) oluşturun:

```bash
keytool -genkey -v -keystore mobile/key.jks -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias btselektrik
```
*Şifre olarak güvenli bir parola belirleyin ve bu parolayı aşağıdaki `key.properties` dosyasına yazın.*

---

## 2. İmza Yapılandırma Dosyası (`android/key.properties`)
`mobile/android/key.properties` adında bir dosya oluşturun ve içeriğini kendi şifrelerinize göre düzenleyin:

```properties
storePassword=btselektriktorrent
keyPassword=btselektriktorrent
keyAlias=btselektrik
storeFile=../../key.jks
```

---

## 3. Gradle Yapılandırması (`android/app/build.gradle`)
Flutter projesi oluşturulduğunda `android/app/build.gradle` dosyası içerisindeki `android` bloğunu aşağıdaki şekilde güncelleyin:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 4. Release APK Derleme Komutu
Tüm yapılandırmalar tamamlandıktan sonra, terminalden projenin `mobile/` dizinine gidip şu komutu çalıştırarak imzalanmış release APK dosyasını üretin:

```bash
flutter build apk --release
```

Derlenen imzalı APK dosyası şu dizinde oluşacaktır:
`build/app/outputs/flutter-apk/app-release.apk`

Saha tabletine USB veya yerel ağ üzerinden kopyalayarak doğrudan kurabilirsiniz. Play Store yüklemesi gerekmemektedir.
