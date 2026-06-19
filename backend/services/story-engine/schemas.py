from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime
import uuid

class ExperienceCreate(BaseModel):
    project_id: uuid.UUID
    title: str
    description: Optional[str] = None
    genre: Optional[str] = None

class ExperienceUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    genre: Optional[str] = None
    status: Optional[str] = None

class ExperienceResponse(BaseModel):
    id: uuid.UUID
    project_id: uuid.UUID
    title: str
    description: Optional[str]
    genre: Optional[str]
    status: str
    version: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class WorldStateCreate(BaseModel):
    name: Optional[str] = None
    facts: Dict[str, Any] = {}
    lore: Dict[str, Any] = {}

class CharacterCreate(BaseModel):
    name: str
    role: Optional[str] = None
    personality_archetype: Optional[str] = None
    goals: Dict[str, Any] = {}

class CharacterUpdate(BaseModel):
    name: Optional[str] = None
    status: Optional[str] = None
    goals: Optional[Dict[str, Any]] = None

class SceneCreate(BaseModel):
    title: str
    description: Optional[str] = None
    location: Optional[str] = None
    sequence_number: int
    prompt: Optional[str] = None

class SceneUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    prompt: Optional[str] = None
