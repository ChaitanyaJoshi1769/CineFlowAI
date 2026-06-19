from sqlalchemy.orm import Session
from uuid import uuid4
from models import Character
from schemas import CharacterCreate, CharacterUpdate

class CharacterService:
    def __init__(self, SessionLocal):
        self.SessionLocal = SessionLocal
    
    def create_character(self, db: Session, exp_id: str, req: CharacterCreate) -> Character:
        character = Character(
            id=uuid4(),
            experience_id=exp_id,
            name=req.name,
            role=req.role,
            personality_archetype=req.personality_archetype,
            goals=req.goals
        )
        db.add(character)
        db.commit()
        db.refresh(character)
        return character
    
    def get_character(self, db: Session, char_id: str) -> Character:
        return db.query(Character).filter(Character.id == char_id).first()
    
    def update_character(self, db: Session, char_id: str, req: CharacterUpdate) -> Character:
        character = db.query(Character).filter(Character.id == char_id).first()
        if not character:
            return None
        
        if req.name:
            character.name = req.name
        if req.status:
            character.status = req.status
        if req.goals:
            character.goals = req.goals
        
        db.commit()
        db.refresh(character)
        return character
