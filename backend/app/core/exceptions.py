from fastapi import HTTPException, status

class APIException(HTTPException):
    def __init__(self, status_code: int, code: str, message: str):
        super().__init__(
            status_code=status_code,
            detail={"error": {"code": code, "message": message}}
        )

class UnauthorizedException(APIException):
    def __init__(self, message: str = "Geçersiz veya süresi dolmuş kimlik bilgisi."):
        super().__init__(status_code=status.HTTP_401_UNAUTHORIZED, code="UNAUTHORIZED", message=message)

class ForbiddenException(APIException):
    def __init__(self, message: str = "Bu işlem için yetkiniz bulunmamaktadır."):
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, code="FORBIDDEN", message=message)

class NotFoundException(APIException):
    def __init__(self, message: str = "İstenen kaynak bulunamadı."):
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, code="NOT_FOUND", message=message)

class BadRequestException(APIException):
    def __init__(self, code: str = "BAD_REQUEST", message: str = "Geçersiz istek."):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, code=code, message=message)

class InviteCodeInvalidException(APIException):
    def __init__(self, message: str = "Davet kodu geçersiz, kullanılmış veya süresi dolmuş."):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, code="INVITE_CODE_INVALID", message=message)

class VerificationCodeInvalidException(APIException):
    def __init__(self, message: str = "Doğrulama kodu geçersiz veya kullanılmış."):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, code="VERIFICATION_CODE_INVALID", message=message)

class VerificationCodeExpiredException(APIException):
    def __init__(self, message: str = "Doğrulama kodunun süresi dolmuş."):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, code="VERIFICATION_CODE_EXPIRED", message=message)

class EmailSendFailedException(APIException):
    def __init__(self, message: str = "E-posta gönderilemedi. Lütfen adresi kontrol edin."):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, code="EMAIL_SEND_FAILED", message=message)

class UserAlreadyExistsException(APIException):
    def __init__(self, message: str = "Bu telefon, e-posta veya sicil no ile kayıtlı kullanıcı zaten var."):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, code="USER_ALREADY_EXISTS", message=message)

class InvalidCredentialsException(APIException):
    def __init__(self, message: str = "Giriş bilgileri veya şifre hatalı."):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, code="INVALID_CREDENTIALS", message=message)

class RateLimitedException(APIException):
    def __init__(self, message: str = "Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin."):
        super().__init__(status_code=status.HTTP_429_TOO_MANY_REQUESTS, code="RATE_LIMIT_EXCEEDED", message=message)
