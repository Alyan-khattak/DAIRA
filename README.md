# Daira

AI-based risk, fraud & underwriting engine for Pakistan's informal committee (ROSCA) economy.

Predicts member default probability, detects fraud/Ponzi patterns, and models group-level
network risk. Goal: a proprietary committee default-outcome dataset + a risk-scoring API
that committee platforms and micro-lenders can license.
___

## Architecture

Three independently deployable services, orchestrated via Docker Compose:

| Service    | Stack                     | Purpose                                             |
|------------|---------------------------|------------------------------------------------------|
| `backend/` | FastAPI                   | Public-facing risk-scoring API, request validation   |
| `ml/`      | FastAPI + scikit-learn/LightGBM | Model training & inference, called internally by backend |
| `frontend/`| TBD                       | Dashboard / integration surface                      |

The backend never imports ML code directly -- it calls the ML service over HTTP. This lets
models be retrained and redeployed without touching the API layer.

### Model roadmap
1. **Phase 1** -- LightGBM/XGBoost baseline for individual member default prediction
2. **Phase 2** -- Rule-based + anomaly detection for fraud/Ponzi structural patterns
3. **Phase 3** -- Graph Neural Network for group-level network risk, once sufficient
   relational data exists
___

## Getting Started

### Prerequisites
- Docker & Docker Compose

### Run with Docker (recommended)
```bash
cp .env.example .env
docker compose up --build
```

- Backend API: http://localhost:8000/health
- ML service: http://localhost:8500/health
- Postgres: localhost:5432

### Running backend tests (Docker)
```bash
docker compose exec backend pytest
```
___

## Local Development (without Docker)

Useful when working on `backend/` or `ml/` in isolation (e.g. faster iteration, IDE debugging).
Each service gets its **own** virtual environment since their dependencies differ significantly.

### 1. Clone the repo
```bash
git clone <repo-url> daira
cd daira
```

### 2. Set up the backend
```bash
cd backend

# Arch Linux -- ensure python + pip are installed
sudo pacman -S python python-pip

python -m venv venv
source venv/bin/activate

pip install -r requirements.txt

# run the API
uvicorn app.main:app --reload
```
Backend runs at http://localhost:8000/health

Run tests:
```bash
pytest
```

Deactivate when done:
```bash
deactivate
```

### 3. Set up the ML service
```bash
cd ml

python -m venv venv
source venv/bin/activate

pip install -r requirements.txt

# run the service
uvicorn src.serve:app --reload --port 8500
```

- Backend API: http://localhost:8000/health
- ML service: http://localhost:8500/health
- Postgres: localhost:5432

### Running backend tests
```bash
docker compose exec backend pytest
```
___

## Project Structure
```
daira/
├── backend/        # FastAPI risk-scoring API
├── ml/             # Data, notebooks, training/inference code, model artifacts
├── frontend/        # (not yet scaffolded)
├── docker-compose.yml
└── BRANCHING.md     # Git workflow conventions
```

See `BRANCHING.md` for the branching strategy and PR conventions.
