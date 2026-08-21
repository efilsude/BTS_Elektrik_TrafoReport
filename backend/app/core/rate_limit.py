"""
Basit, bellek-içi (in-memory) login deneme sınırlayıcı.

Amaç: /auth/login için brute-force korumasının hiç bulunmaması riskini
kapatmak. DB şemasına yeni kolon eklemek (`docs/DB_SCHEMA.md` "kırmızı bölge"
dosyasıdır ve mobile tarafının onayını gerektirir), bu yüzden şema
değiştirmeyen, süreç-içi bir çözüm tercih edildi.

NOT (bilinçli sınırlama): Bu sayaçlar sadece bu API sürecinin belleğinde
tutulur. Uygulama birden fazla worker/instance ile (örn. `uvicorn --workers N`
veya birden fazla container) çalıştırılırsa her worker kendi sayacını tutar
ve koruma etkisi zayıflar. Dahili tek-instance kurumsal kullanım için
yeterlidir; yatay ölçeklenirse Redis gibi paylaşılan bir depoya taşınmalıdır.
Bu karar `docs/DECISIONS.md`'e not düşülmelidir.
"""
import threading
import time
from typing import Dict, Tuple

MAX_ATTEMPTS = 5
LOCKOUT_SECONDS = 5 * 60  # 5 dakika
ATTEMPT_WINDOW_SECONDS = 15 * 60  # 15 dakika içindeki başarısız denemeler sayılır

_lock = threading.Lock()
# identifier (normalize edilmiş) -> (başarısız_deneme_sayısı, ilk_deneme_zamanı, kilit_bitiş_zamanı)
_attempts: Dict[str, Tuple[int, float, float]] = {}


def _now() -> float:
    return time.monotonic()


def is_locked_out(identifier: str) -> Tuple[bool, int]:
    """Bu identifier şu anda kilitli mi? (kilitli_mi, kalan_saniye) döner."""
    key = identifier.strip().lower()
    with _lock:
        record = _attempts.get(key)
        if not record:
            return False, 0
        count, first_attempt_at, locked_until = record
        now = _now()
        if locked_until and now < locked_until:
            return True, int(locked_until - now) + 1
        return False, 0


def record_failure(identifier: str) -> None:
    """Başarısız bir giriş denemesini kaydeder; eşik aşılırsa kilitler."""
    key = identifier.strip().lower()
    now = _now()
    with _lock:
        record = _attempts.get(key)
        if not record or (now - record[1]) > ATTEMPT_WINDOW_SECONDS:
            # Pencere dışına taşmış veya hiç kayıt yok: yeniden başla
            _attempts[key] = (1, now, 0.0)
            return

        count, first_attempt_at, _locked_until = record
        count += 1
        locked_until = now + LOCKOUT_SECONDS if count >= MAX_ATTEMPTS else 0.0
        _attempts[key] = (count, first_attempt_at, locked_until)


def record_success(identifier: str) -> None:
    """Başarılı girişte identifier için sayaçları temizler."""
    key = identifier.strip().lower()
    with _lock:
        _attempts.pop(key, None)
