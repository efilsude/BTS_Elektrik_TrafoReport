import logging
import smtplib
from datetime import datetime, timezone
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import List, Union, Optional
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.exceptions import EmailSendFailedException
from app.db.session import SessionLocal

logger = logging.getLogger("traforeport.email")

def send_email(
    to: Union[str, List[str]],
    subject: str,
    html_body: str,
    text_body: Optional[str] = None,
    raise_on_error: bool = False
) -> bool:
    """
    Sends an email using configured SMTP settings.
    If EMAIL_ENABLED is False, logs to console (console sink for testing/offline).
    """
    recipients = [to] if isinstance(to, str) else to
    recipients = [r.strip() for r in recipients if r and r.strip()]

    if not recipients:
        logger.warning("Email send skipped: No recipients provided.")
        return False

    if not settings.EMAIL_ENABLED:
        logger.info(
            f"[CONSOLE EMAIL SINK]\n"
            f"To: {', '.join(recipients)}\n"
            f"Subject: {subject}\n"
            f"HTML Body: {html_body}\n"
            f"----------------------------------------"
        )
        return True

    try:
        msg = MIMEMultipart("alternative")
        msg["From"] = settings.SMTP_FROM
        msg["To"] = ", ".join(recipients)
        msg["Subject"] = subject

        if text_body:
            msg.attach(MIMEText(text_body, "plain", "utf-8"))
        msg.attach(MIMEText(html_body, "html", "utf-8"))

        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10) as server:
            if settings.SMTP_USE_TLS:
                server.starttls()
            if settings.SMTP_USER and settings.SMTP_PASSWORD:
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.send_message(msg)

        logger.info(f"Email sent successfully to {', '.join(recipients)}")
        return True
    except Exception as e:
        logger.error(f"Failed to send email to {', '.join(recipients)}: {str(e)}", exc_info=True)
        if raise_on_error:
            raise EmailSendFailedException(f"E-posta gönderimi başarısız: {str(e)}")
        return False


def notify_admins(db: Session, subject: str, html_body: str) -> None:
    """
    Helper function to send email notification to all admins.
    Uses ADMIN_NOTIFY_EMAILS setting if provided, otherwise queries DB for active admins.
    Does not raise exceptions on error so background/caller tasks are not interrupted.
    """
    admin_emails: List[str] = []

    if settings.ADMIN_NOTIFY_EMAILS:
        admin_emails = [e.strip() for e in settings.ADMIN_NOTIFY_EMAILS.split(",") if e.strip()]

    if not admin_emails:
        from app.models.user import User
        admins = db.query(User).filter(
            User.role == "admin",
            User.is_active == True,
            User.email.isnot(None)
        ).all()
        admin_emails = [u.email.strip() for u in admins if u.email and u.email.strip()]

    if admin_emails:
        send_email(
            to=admin_emails,
            subject=subject,
            html_body=html_body,
            raise_on_error=False
        )
    else:
        logger.info("notify_admins called, but no admin email addresses were found.")


def notify_admins_for_new_user(user_id: int) -> None:
    """Background task to notify admins about a new registered user."""
    db = SessionLocal()
    try:
        from app.models.user import User
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return
        subject = "[TrafoReport] Yeni kullanıcı kaydı"
        html_body = f"""
        <h2>[TrafoReport] Yeni Kullanıcı Kaydı</h2>
        <p>Sisteme yeni bir çalışan kayıt oldu:</p>
        <ul>
          <li><b>Ad Soyad:</b> {user.full_name}</li>
          <li><b>Telefon:</b> {user.phone}</li>
          <li><b>E-posta:</b> {user.email or '-'}</li>
          <li><b>Sicil No:</b> {user.sicil_no or '-'}</li>
          <li><b>Rol:</b> {user.role}</li>
          <li><b>Tarih:</b> {datetime.now(timezone.utc).strftime('%d.%m.%Y %H:%M')}</li>
        </ul>
        """
        notify_admins(db, subject, html_body)
    except Exception as e:
        logger.error(f"Error notifying admins for new user {user_id}: {e}", exc_info=True)
    finally:
        db.close()


def notify_admins_for_finalize(report_id: int) -> None:
    """Background task to notify admins about a finalized report."""
    db = SessionLocal()
    try:
        from app.models.report import Report
        report = db.query(Report).filter(Report.id == report_id).first()
        if not report:
            return
        subject = "[TrafoReport] Yeni rapor kesinleştirildi"
        html_body = f"""
        <h2>[TrafoReport] Yeni Rapor Kesinleştirildi</h2>
        <p>Aşağıdaki saha raporu başarıyla kesinleştirilmiştir:</p>
        <ul>
          <li><b>Rapor ID:</b> {report.id}</li>
          <li><b>Rapor Başlığı:</b> {report.title}</li>
          <li><b>Müşteri Adı:</b> {report.customer_name}</li>
          <li><b>Trafo Etiketi:</b> {report.trafo_label}</li>
          <li><b>Rapor Tipi:</b> {report.report_type} ({report.maintenance_type})</li>
          <li><b>Oluşturan Teknisyen:</b> {report.creator_display_name}</li>
          <li><b>Tarih:</b> {datetime.now(timezone.utc).strftime('%d.%m.%Y %H:%M')}</li>
        </ul>
        """
        notify_admins(db, subject, html_body)
    except Exception as e:
        logger.error(f"Error notifying admins for finalized report {report_id}: {e}", exc_info=True)
    finally:
        db.close()
