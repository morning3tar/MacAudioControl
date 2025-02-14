# MacAudioControl

# **macOS & iOS Audio Control Apps**
#### **🎧 Control your Mac’s volume from your iPhone via MQTT & SwiftUI**
![License](https://img.shields.io/github/license/morning3tar/MacAudioControl?style=flat-square)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20iOS-blue?style=flat-square)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-orange?style=flat-square)

---

## **📢 Overview**
This is an **experimental** project that allows users to **remotely control their Mac’s audio** (volume, mute/unmute) using an **iOS app** via MQTT messaging.

- 📡 **Uses MQTT** for real-time communication between Mac & iPhone
- 🔊 **macOS Menu Bar App** for controlling volume, mute, and showing connected audio devices
- 📱 **iOS App** for adjusting Mac volume remotely
- 🌐 **Auto-Discovery with Bonjour** to connect without manually entering the Mac's IP
- ⚡ **Launch at Login support** for automatic startup on macOS

> ⚠️ **Note:** This is an **initial project** with known bugs and missing features. If I have time, I will fix them later. Contributions are welcome!

---

## **🛠️ Installation & Setup**
### **1⃣ Install Mosquitto MQTT Broker**
This project uses **Mosquitto** as the MQTT broker. Install it via Homebrew:

```bash
brew install mosquitto
```
Start the Mosquitto service:
```bash
brew services start mosquitto
```

### **2⃣ Clone the Repo**
```bash
git clone https://github.com/morning3tar/MacAudioControl.git
cd MacAudioControl
```

### **3⃣ Xcode**
- **For macOS app:** Open `MacAudioControl/`
- **For iOS app:** Open `iOSAudioControl/`

### **4⃣ Run the Apps**
- **macOS:** Run the `MacAudioControl` app, which will start MQTT & register Bonjour.
- **iOS:** Run the `iOSAudioControl` app, and it should auto-discover the Macbook.

---


## **🖼️ Screenshots**
<div align="center">
  <table>
    <tr>
      <td><strong>macOS Menu Bar App</strong></td>
      <td><img src="https://github.com/user-attachments/assets/da726537-6cd5-4b13-9c60-8e9b2d4017b9" width="300"></td>
    </tr>
    <tr>
      <td><strong>iOS Controller App</strong></td>
      <td><img src="https://github.com/user-attachments/assets/4c7bf32d-aefa-497f-a693-82ee212d2d7f" width="300"></td>
    </tr>
  </table>
</div>

---

## **🐛 Known Issues & TODOs**
- **Auto-Discovery might fail** → Requires manual IP entry if Bonjour is not working
- **No authentication yet** → Any iPhone on the network with the app can control the Mac (future fix: add authentication)
- **Volume updates might not be instant** → Needs better state management
- **Mosquitto needs to be manually installed** → Will automate in future updates

> If you experience issues, restart both apps and Mosquitto:
> ```bash
> brew services restart mosquitto
> ```

---

## **Future Improvements**
- **More polished UI** for the iOS app with an interactive volume knob
- **Better security** to prevent unauthorized volume control
- **iOS Widget** to quickly adjust Mac’s volume
- **Mac App Notarization** for easier installation

---

## **License**
This project is licensed under the **MIT License**. See the `LICENSE` file for details.

---

## **💡 Contributing**
Feel free to **fork this repo**, submit **PRs**, or report **issues**. Any help is appreciated!

---

