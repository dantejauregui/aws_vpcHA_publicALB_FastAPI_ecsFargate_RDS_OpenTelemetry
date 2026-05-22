import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

# FOR LOCAL TESTING enable this to load .env vars, & disable "?sslmode=require":
# from dotenv import load_dotenv
# load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

DATABASE_URL = (
    f"postgresql+psycopg://"
    f"{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    f"?sslmode=require"
)

# SQLAlchemy Engine
engine = create_engine(
    DATABASE_URL, echo=True
)  # shows generated SQL in logs (great for learning)

# Session Factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

# Base class for ORM models
Base = declarative_base()
