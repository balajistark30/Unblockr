from fastapi import FastAPI
from app.routes.report import router as report_router

app = FastAPI(title="Unblockr Backend")

app.include_router(report_router)


@app.get("/")
def root():
    return {"message": "Unblockr backend running"}