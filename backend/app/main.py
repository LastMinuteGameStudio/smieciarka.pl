from fastapi import FastAPI

from app.api import auth, filters, images, listings, notifications

app = FastAPI(title="smieciarka.pl")

app.include_router(auth.router, tags=["auth"])
app.include_router(listings.router, tags=["listings"])
app.include_router(images.router, tags=["images"])
app.include_router(filters.router, tags=["filters"])
app.include_router(notifications.router, tags=["notifications"])


@app.get("/health")
def health():
    return {"status": "ok"}
