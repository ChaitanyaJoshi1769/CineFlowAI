from fastapi import FastAPI
import logging

logger = logging.getLogger(__name__)
app = FastAPI(title='CineFlow AI - agent orchestrator')

@app.get('/health')
async def health():
    return {'status': 'healthy', 'service': 'agent-orchestrator'}

@app.get('/ready')
async def ready():
    return {'ready': True}
