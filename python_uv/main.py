from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime, timezone

from sqlalchemy import func
from sqlalchemy.orm import Session
from db_python.db import SessionLocal
from db_python.models import ItemDB

app = FastAPI(title="My Serious API")

SERVICE_NAME = "fastapi-app"
SERVICE_VERSION = "1.0.0"
ENVIRONMENT = "dev"
START_TIME = datetime.now(timezone.utc)


# --- Models ---
class Item(BaseModel):
    name: str = Field(..., min_length=2, max_length=50)
    price: float = Field(..., gt=0)
    tags: Optional[List[str]] = []


class ItemResponse(Item):
    id: str


# --- Routes ---

@app.get("/")
async def root():
    return {"status": "ok"}


@app.post("/items", response_model=ItemResponse)
async def create_item(item: Item):

    # Create DB session
    db: Session = SessionLocal()

    try:

        # Create ORM object
        db_item = ItemDB(
            name=item.name,
            price=item.price,
            tags=item.tags,
        )

        # Add to transaction
        db.add(db_item)

        # Persist to PostgreSQL
        db.commit()

        # Reload object from DB
        db.refresh(db_item)

        # Return API response
        return ItemResponse(
            id=str(db_item.id),
            name=db_item.name,
            price=float(db_item.price),
            tags=db_item.tags,
        )
    finally:
        db.close()


@app.get("/items", response_model=List[ItemResponse])
async def list_items(
    min_price: float = Query(0, ge=0),
    max_price: float = Query(999999, ge=0),
):

    db: Session = SessionLocal()

    try:

        items = (
            db.query(ItemDB)
            .filter(ItemDB.price >= min_price)
            .filter(ItemDB.price <= max_price)
            .all()
        )

        return [
            ItemResponse(
                id=str(item.id),
                name=item.name,
                price=float(item.price),
                tags=item.tags,
            )
            for item in items
        ]
    finally:
        db.close()


@app.get("/items/{item_id}", response_model=ItemResponse)
async def get_item(item_id: str):

    db: Session = SessionLocal()

    try:

        item = (
            db.query(ItemDB)
            .filter(ItemDB.id == item_id)
            .first()
        )

        if not item:
            raise HTTPException(
                status_code=404,
                detail="Item not found",
            )

        return ItemResponse(
            id=str(item.id),
            name=item.name,
            price=float(item.price),
            tags=item.tags,
        )
    finally:
        db.close()


@app.delete("/items/{item_id}")
async def delete_item(item_id: str):

    db: Session = SessionLocal()

    try:

        item = (
            db.query(ItemDB)
            .filter(ItemDB.id == item_id)
            .first()
        )

        if not item:
            raise HTTPException(
                status_code=404,
                detail="Item not found",
            )

        db.delete(item)

        db.commit()

        return {"deleted": True}
    finally:
        db.close()


@app.get("/stats")
async def stats():

    db: Session = SessionLocal()

    try:

        total_items = db.query(func.count(ItemDB.id)).scalar()

        average_price = db.query(func.avg(ItemDB.price)).scalar()

        return {
            "total_items": total_items,
            "average_price": float(average_price or 0),
        }
    finally:
        db.close()


@app.get("/health")
async def health():
    uptime_seconds = int((datetime.now(timezone.utc) - START_TIME).total_seconds())
    return {
        "status": "healthy",
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "environment": ENVIRONMENT,
        "uptime_seconds": uptime_seconds,
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
    }
