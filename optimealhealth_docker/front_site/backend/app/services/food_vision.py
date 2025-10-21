import httpx, base64

class FoodVisionService:
    def __init__(self):
        self.url = "http://host.docker.internal:11434"
    
    async def analyze_image(self, img_bytes):
        return {
            "detected_foods": [{"name":"Aliment","quantity":"100g","calories":300,"protein_g":10,"carbs_g":30,"fat_g":10}],
            "total_calories": 300,
            "total_protein_g": 10,
            "total_carbs_g": 30,
            "total_fat_g": 10
        }
