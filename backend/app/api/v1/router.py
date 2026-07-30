from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.users import router as users_router
from app.api.v1.admin import router as admin_router
from app.api.v1.reports import router as reports_router, drafts_router

api_router = APIRouter()

api_router.include_router(auth_router, prefix="/auth", tags=["Auth"])
api_router.include_router(users_router, prefix="/users", tags=["Users"])
api_router.include_router(admin_router, prefix="/admin", tags=["Admin"])
api_router.include_router(reports_router, prefix="/reports", tags=["Reports"])
api_router.include_router(drafts_router, prefix="/drafts", tags=["Drafts"])
  # Optional convenience binding

