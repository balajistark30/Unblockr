import os
import shutil
import uuid
from typing import Annotated

from fastapi import APIRouter, File, Form, UploadFile

from app.schemas.response import FinalReportResponse
from app.services.pipeline import run_single_image_pipeline
from app.services.fusion import fuse_results

router = APIRouter(prefix="/report", tags=["report"])

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.post("/analyze", response_model=FinalReportResponse)
async def analyze_report(
    images: Annotated[list[UploadFile], File(...)],
    issue_type: Annotated[str | None, Form()] = None,
    selected_vehicle: Annotated[str | None, Form()] = None,
    entered_plates: Annotated[str | None, Form()] = None,
):
    saved_paths = []

    for image in images:
        extension = os.path.splitext(image.filename)[1] or ".jpg"
        filename = f"{uuid.uuid4().hex}{extension}"
        path = os.path.join(UPLOAD_DIR, filename)

        with open(path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)

        saved_paths.append(path)

    per_image_results = []
    for path in saved_paths:
        result = run_single_image_pipeline(path)
        per_image_results.append(result["parsed_result"])

    fused = fuse_results(per_image_results)

    plates = []
    if entered_plates:
        plates = [p.strip() for p in entered_plates.split(",") if p.strip()]

    return FinalReportResponse(
        success=True,
        is_blocked=fused["is_blocked"],
        confidence=fused["confidence"],
        blocked_vehicle=fused["blocked_vehicle"],
        blocking_vehicles=fused["blocking_vehicles"],
        issue_type=issue_type,
        selected_vehicle=selected_vehicle,
        entered_plates=plates,
        image_count=len(images),
    )