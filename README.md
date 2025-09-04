# Soil-Health-Monitoring
A simple Flutter + Firebase application that monitors soil temperature and moisture using a Bluetooth sensor. It stores readings in Firestore and shows history with real-time updates.

Clone the repo
git clone https://github.com/your-username/soil-health-monitoring.git
cd soil-health-monitoring

Install dependencies
flutter pub get

Setup Firebase
Add your own firebase_options.dart (from Firebase Console setup).
Enable Authentication (Email/Password).
Enable Firestore Database.

Run the app
flutter run

📌 Assumptions
The app assumes a Bluetooth-enabled soil sensor that sends temperature and moisture readings.
If Bluetooth or Firebase is not connected, the app can still showcase dummy data for demo purposes.
