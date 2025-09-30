from pydantic import BaseModel, EmailStr
class UserOut(BaseModel): id:int; email:EmailStr; plan:str|None=None; status:str