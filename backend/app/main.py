from fastapi import FastAPI

from app.api import auth, listings

app = FastAPI(title="smieciarka.pl")

app.include_router(auth.router, tags=["auth"])
app.include_router(listings.router, tags=["listings"])


@app.get("/health")
def health():
    return {"status": "ok"}
