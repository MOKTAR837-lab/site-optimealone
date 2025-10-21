"""Quota Manager - Gestion quota par user_id"""
import redis
from datetime import datetime, timedelta
from typing import Optional
import logging

logger = logging.getLogger(__name__)

class QuotaManager:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self.FREE_DAILY_LIMIT = 10
        self.PREMIUM_DAILY_LIMIT = 999999
        
    def get_quota_key(self, user_id: str, date: str = None) -> str:
        if date is None:
            date = datetime.now().strftime("%Y-%m-%d")
        return f"quota:{user_id}:{date}"
    
    def check_quota(self, user_id: Optional[str], is_premium: bool = False) -> dict:
        if not user_id:
            return {"allowed": False, "used": 0, "limit": 0, "remaining": 0}
        
        daily_limit = self.PREMIUM_DAILY_LIMIT if is_premium else self.FREE_DAILY_LIMIT
        today = datetime.now().strftime("%Y-%m-%d")
        quota_key = self.get_quota_key(user_id, today)
        
        try:
            used = int(self.redis.get(quota_key) or 0)
        except:
            used = 0
        
        remaining = max(0, daily_limit - used)
        tomorrow = datetime.now() + timedelta(days=1)
        reset_time = tomorrow.replace(hour=0, minute=0, second=0, microsecond=0)
        
        return {
            "allowed": remaining > 0,
            "used": used,
            "limit": daily_limit,
            "remaining": remaining,
            "resets_at": reset_time.isoformat(),
            "is_premium": is_premium
        }
    
    def increment_usage(self, user_id: str) -> bool:
        if not user_id:
            return False
        today = datetime.now().strftime("%Y-%m-%d")
        quota_key = self.get_quota_key(user_id, today)
        try:
            self.redis.incr(quota_key)
            self.redis.expire(quota_key, 86400)
            return True
        except Exception as e:
            logger.error(f"Erreur quota: {e}")
            return False

quota_manager = None

def init_quota_manager(redis_client):
    global quota_manager
    quota_manager = QuotaManager(redis_client)