import os
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import RandomForestClassifier
import pickle
from pathlib import Path

# 🔥 MLflow
import mlflow
import mlflow.sklearn


# ==============================
# 🔹 ENV CONFIG
# ==============================

model_version = os.getenv("MODEL_VERSION", "v1")

# 🔥 MLflow tracking URI (dynamic for local + pipeline)
mlflow_tracking_uri = os.getenv("MLFLOW_TRACKING_URI", "file:./mlruns")
mlflow.set_tracking_uri(mlflow_tracking_uri)

mlflow.set_experiment("chai-sutta-predictor")


# ==============================
# 🔹 PATHS
# ==============================

BASE_DIR = Path(__file__).resolve().parents[1]

models_dir = BASE_DIR / "models"
models_dir.mkdir(parents=True, exist_ok=True)

data_path = BASE_DIR / "data" / "chai_sutta_data.csv"

print(f"[INFO] Loading dataset from: {data_path}")
df = pd.read_csv(data_path)


# ==============================
# 🔹 PREPROCESSING
# ==============================

le_gender = LabelEncoder()
df['gender'] = le_gender.fit_transform(df['gender'])

le_habit = LabelEncoder()
df['habit'] = le_habit.fit_transform(df['habit'])

X = df[['age', 'gender', 'taunts']]
y = df['habit']

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)


# ==============================
# 🔹 TRAINING + MLFLOW
# ==============================

with mlflow.start_run(run_name=f"model_{model_version}"):

    print(f"[INFO] Training model version: {model_version}")

    model = RandomForestClassifier(random_state=42)
    model.fit(X_train, y_train)

    accuracy = model.score(X_test, y_test)
    print(f"[INFO] Model Accuracy: {accuracy}")

    # 🔥 VALIDATION (CRITICAL)
    if accuracy < 0.6:
        raise Exception(f"[ERROR] Accuracy too low: {accuracy}")


    mlflow.set_tag("stage", "dev")
    mlflow.set_tag("source", "github_actions")
    mlflow.set_tag("model_version", model_version)
    
    # ==============================
    # 🔹 MLFLOW LOGGING
    # ==============================

    mlflow.log_param("model_type", "RandomForest")
    mlflow.log_param("random_state", 42)
    mlflow.log_param("model_version", model_version)

    mlflow.log_metric("accuracy", accuracy)

    # Model log (MLflow artifact)
    mlflow.sklearn.log_model(model, "model")

    run_id = mlflow.active_run().info.run_id
    print(f"[INFO] MLflow run_id: {run_id}")

    # ==============================
    # 🔹 SAVE MODEL PACKAGE
    # ==============================

    model_path = models_dir / f"chai_sutta_model_{model_version}.pkl"

    model_package = {
        "model": model,
        "gender_encoder": le_gender,
        "habit_encoder": le_habit,
        "version": model_version,
        "accuracy": accuracy,
        "run_id": run_id
    }

    with open(model_path, "wb") as f:
        pickle.dump(model_package, f)

    run_id_file = BASE_DIR / "mlflow_run_id.txt"
    run_id_file.write_text(run_id)

    print(f"[SUCCESS] Model saved at: {model_path}")
    print(f"[INFO] Run ID written to: {run_id_file}")