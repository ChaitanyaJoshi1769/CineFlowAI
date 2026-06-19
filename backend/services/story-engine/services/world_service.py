from sqlalchemy.orm import Session
from uuid import uuid4
from models import WorldState
from schemas import WorldStateCreate

class WorldService:
    def __init__(self, SessionLocal):
        self.SessionLocal = SessionLocal
    
    def create_world_state(self, db: Session, exp_id: str, req: WorldStateCreate) -> WorldState:
        world_state = WorldState(
            id=uuid4(),
            experience_id=exp_id,
            version=1,
            name=req.name,
            facts=req.facts,
            lore=req.lore
        )
        db.add(world_state)
        db.commit()
        db.refresh(world_state)
        return world_state
    
    def get_current_world_state(self, db: Session, exp_id: str) -> WorldState:
        return db.query(WorldState).filter(
            WorldState.experience_id == exp_id
        ).order_by(WorldState.version.desc()).first()
