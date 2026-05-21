import os
from dotenv import load_dotenv
from sqlalchemy import create_engine 
from sqlalchemy.orm import declarative_base, sessionmaker

# ONLY FOR LOCAL TESTING: enable this to Load .env variables
# load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')

# SQLAlchemy Engine
engine = create_engine(DATABASE_URL, echo=True ) #shows generated SQL in logs (great for learning)

# Session Factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

# Base class for ORM models
Base = declarative_base()
