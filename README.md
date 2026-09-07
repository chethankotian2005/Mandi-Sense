# 🌾 MandiSense

<div align="center">
  <h3>Find the Best Market. Maximize Your Returns.</h3>
  <p>A smart, localized, and accessible mobile application designed to help farmers make data-driven decisions on where and when to sell their crops.</p>

  **[📱 Download & Try the Application](https://drive.google.com/file/d/1EjM2II44yR6aKQu78occko8HPxMQnKy6/view?usp=sharing)**
</div>

---

## 📖 Overview

**MandiSense** solves a critical problem for farmers: deciding which nearby market (Mandi) will yield the highest actual profit after factoring in transportation costs, and whether it's the right time to sell based on market trends.

The platform consists of a **Flutter mobile application** (supporting Android, iOS, and Web) and a fast **Python/FastAPI backend** that calculates dynamic net returns, projects price trends, and provides actionable intelligence.

## ✨ Key Features

- 📍 **Smart Market Comparison**: Automatically detects the farmer's location and compares crop prices across all markets within a 50km radius.
- 💰 **Net Return Calculation**: It doesn't just show the highest price; it calculates the **actual net return** by automatically deducting distance-based transportation costs for the specified crop quantity.
- 📈 **Decision Timing Strategy ("Sell or Wait")**: Uses historical price data and linear projection to advise farmers whether to sell today or wait 2 days for potentially higher profits.
- 🌍 **Fully Localized**: Complete UI and dynamic insights translated into **English, Hindi, and Kannada** to ensure accessibility for regional farmers.
- 🗣️ **Voice Narration (TTS)**: Built-in Text-to-Speech allows farmers to listen to the market insights and recommendations aloud in their preferred language.
- 📡 **Offline-Aware**: Fails gracefully when the internet drops, displaying a clear offline banner and utilizing cached market data.
- 📱 **Interactive UI**: Tap on any market card to instantly reveal detailed timing strategies and personalized rationales.
- 🗺️ **Market Map View**: Visualize the farmer's location and compare nearby markets on an interactive, color-coded OpenStreetMap.
- 👓 **Simple Mode (Accessibility)**: A one-tap toggle that globally scales fonts by 40%, replaces text dropdowns with visual emoji cards, and uses giant directional arrows for trends to radically reduce cognitive load.
- 💬 **WhatsApp Sharing**: One-tap sharing generates a fully translated, emoji-rich summary of the best market recommendation for quick communication with peers.
- 🏆 **Hero Savings Banner**: Instantly motivates the farmer by animating the exact Rupee amount saved by choosing the recommended market over their geographically nearest option.
## 🛠️ Tech Stack

### Frontend (Mobile & Web)
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Localization**: `easy_localization`
- **Accessibility**: `flutter_tts` (Text-to-Speech)
- **Location**: `geolocator`

### Backend
- **Framework**: [FastAPI](https://fastapi.tiangolo.com/) (Python)
- **Database**: SQLite with `SQLAlchemy` ORM
- **Algorithms**: Haversine distance calculation, Linear price projection

## 🚀 Getting Started

### 1. Running the Backend
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   .\venv\Scripts\activate  # Windows
   source venv/bin/activate # Mac/Linux
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run the FastAPI server:
   ```bash
   uvicorn main:app --port 8000 --reload
   ```

### 2. Running the Flutter App
1. Navigate to the app directory:
   ```bash
   cd app
   ```
2. Get Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the app (on Web, Android, or iOS):
   ```bash
   flutter run -d web-server --web-port 3000
   ```
   *(Ensure the backend is running and accessible at the URL specified in `api_service.dart`)*

## 🗺️ Future Roadmap

MandiSense is built with scale in mind. Upcoming features include:
- **Price Forecasting**: Short-horizon Machine Learning price predictions.
- **Transport Pooling**: Cost-sharing logistics with nearby farmers heading to the same market.
- **Spoilage-Adjusted Returns**: Dynamic penalty models for perishable crops over distance/time.

---
*Built with ❤️ for farmers.*
