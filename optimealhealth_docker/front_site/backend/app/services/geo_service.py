import httpx
class GeoService:
    @staticmethod
    async def get_country(ip):
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                r = await client.get(f"http://ip-api.com/json/{ip}")
                return r.json().get("countryCode", "UNKNOWN")
        except:
            return "UNKNOWN"
