from sqlalchemy import Column, String, DateTime, Integer, JSON, Boolean, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid

Base = declarative_base()

class Experience(Base):
    __tablename__ = "experiences"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    genre = Column(String(100))
    status = Column(String(50), default="draft")
    version = Column(Integer, default=1)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class WorldState(Base):
    __tablename__ = "world_states"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    experience_id = Column(UUID(as_uuid=True), ForeignKey("experiences.id"), nullable=False)
    version = Column(Integer, nullable=False)
    name = Column(String(255))
    facts = Column(JSON, default={})
    lore = Column(JSON, default={})
    economy_state = Column(JSON, default={})
    created_at = Column(DateTime, default=datetime.utcnow)

class Character(Base):
    __tablename__ = "characters"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    experience_id = Column(UUID(as_uuid=True), ForeignKey("experiences.id"), nullable=False)
    name = Column(String(255), nullable=False)
    role = Column(String(100))
    personality_archetype = Column(String(100))
    voice_id = Column(String(255))
    backstory = Column(Text)
    goals = Column(JSON, default={})
    beliefs = Column(JSON, default={})
    secrets = Column(JSON, default={})
    status = Column(String(50), default="alive")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Scene(Base):
    __tablename__ = "scenes"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    experience_id = Column(UUID(as_uuid=True), ForeignKey("experiences.id"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    location = Column(String(255))
    sequence_number = Column(Integer)
    duration_seconds = Column(Integer)
    prompt = Column(Text)
    status = Column(String(50), default="draft")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class Event(Base):
    __tablename__ = "events"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    experience_id = Column(UUID(as_uuid=True), ForeignKey("experiences.id"), nullable=False)
    event_type = Column(String(100), nullable=False)
    actor_id = Column(String(255))
    action = Column(String(255))
    payload = Column(JSON)
    timestamp = Column(DateTime, default=datetime.utcnow)
