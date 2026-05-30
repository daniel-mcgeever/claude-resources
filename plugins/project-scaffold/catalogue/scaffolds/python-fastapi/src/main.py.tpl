from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(
    title="{{SLUG}}",
    description="{{DESCRIPTION}}",
    version="0.1.0",
)


class HealthResponse(BaseModel):
    status: str


@app.get("/health", response_model=HealthResponse, tags=["meta"])
async def health() -> HealthResponse:
    """Health check — used by CI and Uptime Kuma."""
    return HealthResponse(status="ok")


@app.get("/", tags=["meta"])
async def root() -> dict:
    return {"message": f"Hello from {{SLUG}}"}
