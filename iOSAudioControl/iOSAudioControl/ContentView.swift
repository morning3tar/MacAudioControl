import SwiftUI

struct ContentView: View {
    @StateObject private var mqttManager = MQTTManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("Mac Audio Control")
                .font(.title)
                .bold()
                .foregroundColor(.white)

            HStack(spacing: 20) {
                Button(action: { mqttManager.sendCommand("decrease") }) {
                    Image(systemName: "minus.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }

                Button(action: { mqttManager.sendCommand("mute") }) {
                    Image(systemName: "speaker.slash.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }

                Button(action: { mqttManager.sendCommand("increase") }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }
            }

            HStack {
                Image(systemName: mqttManager.discoveredHost != nil ? "wifi" : "wifi.slash")
                    .foregroundColor(mqttManager.discoveredHost != nil ? .green : .red)
                    .animation(.easeInOut(duration: 0.3), value: mqttManager.discoveredHost)
                Text(mqttManager.discoveredHost != nil ? "✅ Connected to Mac" : "🔴 Not Connected")
                    .foregroundColor(mqttManager.discoveredHost != nil ? .green : .red)
                    .bold()
                    .animation(.easeInOut(duration: 0.3), value: mqttManager.discoveredHost)
            }
            
            Text("Tap the buttons to control Mac audio")
                .foregroundColor(.white.opacity(0.8))
                .font(.footnote)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
