from pydantic import BaseModel
from typing import List, Dict, Any
class ChatIn(BaseModel): message:str; history: List[Dict[str,Any]]=[]
class ChatOut(BaseModel): reply:str; suggested_actions: List[Dict[str,Any]]=[]
class SuggestMealsIn(BaseModel): days:int=3; kcal_target_per_day:int|None=None; constraints: Dict[str,Any]|None=None
class SuggestMealsOut(BaseModel): meals: List[Dict[str,Any]]; warnings: List[str]=[]; source:str="ai_v1"