import os
import pickle
from flask import Flask, request, jsonify, render_template_string
from pathlib import Path

app = Flask(__name__)

# Get the absolute path to models directory
BASE_DIR = Path(__file__).parent.parent
MODELS_DIR = BASE_DIR / "models"

model_version = os.getenv("MODEL_VERSION", "v1")

# Load model package with error handling
try:
    model_package_path = MODELS_DIR / f"chai_sutta_model_{model_version}.pkl"
    with open(model_package_path, "rb") as f:
        model_package = pickle.load(f)
    
    # Extract components from package
    model = model_package["model"]
    le_gender = model_package["gender_encoder"]
    le_habit = model_package["habit_encoder"]
    
    print(f"✅ Models loaded successfully from {model_package_path}")
    print(f"   Version: {model_package.get('version', 'unknown')}")
    print(f"   Accuracy: {model_package.get('accuracy', 'N/A'):.4f}")
except FileNotFoundError as e:
    print(f"❌ Error loading models: {e}")
    raise
except Exception as e:
    print(f"❌ Error extracting model components: {e}")
    raise


# Simple HTML UI
HTML_PAGE = """
<!DOCTYPE html>
<html>
<head>
    <title>Chai Sutta Predictor</title>
</head>
<body>
    <h2>☕🚬 Chai Sutta Predictor</h2>
    <form method="post" action="/predict_form">
        Age: <input type="number" name="age" required><br><br>
        
        Gender:
        <select name="gender">
            <option value="male">Male</option>
            <option value="female">Female</option>
        </select><br><br>
        
        Taunts: <input type="number" name="taunts" required><br><br>
        
        <input type="submit" value="Predict">
    </form>

    {% if prediction %}
        <h3>Prediction: {{ prediction }}</h3>
    {% endif %}
</body>
</html>
"""

@app.route("/")
def home():
    return render_template_string(HTML_PAGE)

@app.route("/predict_form", methods=["POST"])
def predict_form():
    try:
        age = int(request.form["age"])
        gender = request.form["gender"]
        taunts = int(request.form["taunts"])

        # Encode gender
        gender_encoded = le_gender.transform([gender])[0]

        # Predict
        prediction = model.predict([[age, gender_encoded, taunts]])
        result = le_habit.inverse_transform(prediction)[0]

        return render_template_string(HTML_PAGE, prediction=result)
    except Exception as e:
        return render_template_string(HTML_PAGE, prediction=f"Error: {str(e)}")

# API endpoint (optional for future use)
@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.json

        age = data["age"]
        gender = data["gender"]
        taunts = data["taunts"]

        gender_encoded = le_gender.transform([gender])[0]
        prediction = model.predict([[age, gender_encoded, taunts]])
        result = le_habit.inverse_transform(prediction)

        return jsonify({"prediction": result[0]})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)
    