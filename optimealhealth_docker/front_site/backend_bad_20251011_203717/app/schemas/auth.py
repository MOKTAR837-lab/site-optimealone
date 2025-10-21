from pydantic import BaseModel, EmailStr
class SignupIn(BaseModel): email: EmailStr; password: str; accept_terms: bool
class LoginIn(BaseModel): email: EmailStr; password: str
class TokenOut(BaseModel): access_token: str; token_type: str="bearer"; expires_in: int; refresh_token: str|None=None