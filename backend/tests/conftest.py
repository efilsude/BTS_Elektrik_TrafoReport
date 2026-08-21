"""
Paylaşılan pytest yapılandırması.

NEDEN BU DOSYA VAR:
`app/db/session.py` içindeki SQLAlchemy `engine`, `app.db.session` modülü
ilk import edildiğinde BİR KEZ oluşturulur ve `sys.modules` önbelleğinde
kalır. Test dosyalarının her biri kendi `DATABASE_URL`'ini ayarlayıp
"kendi izole sqlite dosyam var" varsaymıştı — ama pytest tüm dosyaları tek
süreçte topladığında sadece ilk import edilen dosyanın `DATABASE_URL`'i
gerçek `engine`'i oluşturuyor, geri kalan dosyaların ataması hiçbir işe
yaramıyor (hepsi aynı paylaşılan `engine`'i kullanıyor). Üstüne üstlük her
dosya teardown'da kendi sqlite dosyasını `os.remove()` ile siliyordu; bu,
hâlâ aynı paylaşılan engine'e bağlı açık bağlantılar varken dosyayı
sildiği için "attempt to write a readonly database" hatasına yol açıyordu.
Sonuç: `pytest tests/` ile tüm paket birlikte çalıştırıldığında 21/24 test
hataya düşüyordu (her dosya tek başına çalıştırıldığında ise sorun
gizleniyordu, çünkü o zaman gerçekten tek bir import/tek bir engine oluyor).

ÇÖZÜM:
Tüm test modülleri için **tek** bir DATABASE_URL, `app` herhangi bir test
dosyası tarafından import edilmeden ÖNCE (conftest.py, pytest tarafından
her zaman test modüllerinden önce yüklenir) ortam değişkenine yazılır.
Böylece gerçekten tek bir paylaşılan engine/sqlite dosyası kullanılır ve
bu, artık gerçeği yansıtır (önceden de fiilen böyleydi, sadece
yanlışlıkla/örtük olarak). Her test dosyası kendi `drop_all → create_all →
seed_data` desenini (modül/oturum başına temiz sıfırlama için) korur;
sadece dosyayı silme adımını kaldırırlar — fiziksel dosya temizliği tek
seferlik olarak burada, tüm oturum bittikten sonra yapılır.
"""
import os

TEST_DB_PATH = "./test_traforeport_shared.db"

# app.main / app.db.session ilk kez import edilmeden önce ayarlanmalı.
os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB_PATH}"
os.environ.setdefault("EMAIL_ENABLED", "false")

import pytest


@pytest.fixture(scope="session", autouse=True)
def _cleanup_shared_test_db():
    """Oturum sonunda paylaşılan sqlite dosyasını temizler.

    ÖNEMLİ: Dosyayı OTURUM BAŞINDA silmiyoruz. `app/main.py` import edilir
    edilmez (yani bu fixture ilk çalışmadan önce, test modülleri
    toplanırken) `Base.metadata.create_all(bind=engine)` çağırıyor ve bu,
    paylaşılan `engine`'in bağlantı havuzunda canlı bir bağlantı açıyor.
    O bağlantı açıkken dosyayı `os.remove()` ile silmek, SQLite'ın artık
    unlink edilmiş bir inode'a yazmaya çalışmasına ve "attempt to write a
    readonly database" hatasına yol açar (tam olarak bu bug'ın kök nedeni
    buydu). Modüller arası sıfırlama zaten her test dosyasının kendi
    drop_all/create_all fixture'ı tarafından — dosyayı silmeden, sadece
    tabloları temizleyerek — yapılıyor; bu yeterli.

    Oturum tamamen bitince önce `engine.dispose()` ile havuzdaki tüm
    bağlantıları düzgünce kapatıyoruz, ancak ONDAN SONRA dosyayı siliyoruz.
    """
    yield
    from app.db.session import engine as _engine
    _engine.dispose()
    if os.path.exists(TEST_DB_PATH):
        try:
            os.remove(TEST_DB_PATH)
        except OSError:
            pass
