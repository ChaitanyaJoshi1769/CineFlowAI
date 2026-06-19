from sqlalchemy.orm import Session
from uuid import uuid4
from models import Experience, Scene
from schemas import ExperienceCreate, ExperienceUpdate, SceneCreate

class StoryService:
    def __init__(self, SessionLocal):
        self.SessionLocal = SessionLocal
    
    def create_experience(self, db: Session, req: ExperienceCreate) -> Experience:
        experience = Experience(
            id=uuid4(),
            project_id=req.project_id,
            title=req.title,
            description=req.description,
            genre=req.genre
        )
        db.add(experience)
        db.commit()
        db.refresh(experience)
        return experience
    
    def get_experience(self, db: Session, exp_id: str) -> Experience:
        return db.query(Experience).filter(Experience.id == exp_id).first()
    
    def update_experience(self, db: Session, exp_id: str, req: ExperienceUpdate) -> Experience:
        experience = db.query(Experience).filter(Experience.id == exp_id).first()
        if not experience:
            return None
        
        if req.title:
            experience.title = req.title
        if req.description:
            experience.description = req.description
        if req.genre:
            experience.genre = req.genre
        if req.status:
            experience.status = req.status
        
        db.commit()
        db.refresh(experience)
        return experience
    
    def delete_experience(self, db: Session, exp_id: str):
        experience = db.query(Experience).filter(Experience.id == exp_id).first()
        if experience:
            db.delete(experience)
            db.commit()
    
    def create_scene(self, db: Session, exp_id: str, req: SceneCreate) -> Scene:
        scene = Scene(
            id=uuid4(),
            experience_id=exp_id,
            title=req.title,
            description=req.description,
            location=req.location,
            sequence_number=req.sequence_number,
            prompt=req.prompt
        )
        db.add(scene)
        db.commit()
        db.refresh(scene)
        return scene
    
    def get_scene(self, db: Session, scene_id: str) -> Scene:
        return db.query(Scene).filter(Scene.id == scene_id).first()
