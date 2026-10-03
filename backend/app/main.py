from fastapi import FastAPI

from app.api import auth

app = FastAPI(title="smieciarka.pl")

app.include_router(auth.router, tags=["auth"])


@app.get("/health")
def health():
    return {"status": "ok"}
