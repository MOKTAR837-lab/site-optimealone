from pydantic import BaseModel
from typing import List, Optional, Any
class Preferences(BaseModel):
    diet: Optional[str]=None
    allergies: List[str]=[]
    exclude_ingredients: List[str]=[]
    kcal_target_per_day: Optional[int]=None
    goals: Any | None = None