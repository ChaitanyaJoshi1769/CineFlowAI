models.py:
from sqlalchemy import Column, String, DateTime, Integer, JSON, ForeignKey, Text, BigInteger
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid

Base = declarative_base()

class Event(Base):
    __tablename__ = "events"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    experience_id = Column(UUID(as_uuid=True), nullable=False)
    event_type = Column(String(100), nullable=False)
    actor_id = Column(String(255))
    actor_type = Column(String(100))
    action = Column(String(255))
    payload = Column(JSON)
    timestamp = Column(DateTime, default=datetime.utcnow)
    sequence_number = Column(BigInteger)
    version = Column(Integer, default=1)

class EventSnapshot(Base):
    __tablename__ = "event_snapshots"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    experience_id = Column(UUID(as_uuid=True), nullable=False)
    entity_id = Column(String(255), nullable=False)
    entity_type = Column(String(100), nullable=False)
    snapshot_version = Column(Integer, nullable=False)
    state = Column(JSON, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class StateTimeline(Base):
    __tablename__ = "state_timelines"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    experience_id = Column(UUID(as_uuid=True), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)
    state_version = Column(Integer)
    state_hash = Column(String(64))

schemas.py:
from pydantic import BaseModel
from typing import Optional, Any, Dict
from datetime import datetime
import uuid

class EventCreate(BaseModel):
    event_type: str
    actor_id: Optional[str] = None
    action: Optional[str] = None
    payload: Optional[Dict[str, Any]] = None

class EventResponse(BaseModel):
    id: uuid.UUID
    experience_id: uuid.UUID
    event_type: str
    actor_id: Optional[str]
    action: Optional[str]
    timestamp: datetime
    sequence_number: Optional[int]
    
    class Config:
        from_attributes = True

class SnapshotCreate(BaseModel):
    entity_id: str
    entity_type: str
    state: Dict[str, Any]

class TimelineQuery(BaseModel):
    target_timestamp: datetime
    entity_id: Optional[str] = None

class StateQuery(BaseModel):
    from_timestamp: datetime
    to_timestamp: datetime

database.py:
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/cineflow")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
