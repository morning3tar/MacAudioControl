import SwiftUI
import AVFoundation
import LaunchAtLogin

struct VolumeView: View {
    @State private var volume: Double = 50
    @State private var outputDevice: String = "Detecting..."
    @State private var isMuted: Bool = false
    @AppStorage("launchAtLoginEnabled") private var launchAtLoginEnabled: Bool = LaunchAtLogin.isEnabled

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button(action: { changeVolume(by: -5) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.gray.opacity(0.4)))
                        .padding(10)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Text("\(Int(volume))%")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 50, maxWidth: 70)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .truncationMode(.tail)
                
                Spacer()

                Button(action: { changeVolume(by: 5) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.gray.opacity(0.4)))
                        .padding(10)
                }
                .buttonStyle(PlainButtonStyle())
            }

            HStack(spacing: 4) {
                ForEach(0..<16) { index in
                    Rectangle()
                        .fill(volumeColor(for: index))
                        .frame(width: 10, height: 20)
                        .cornerRadius(3)
                        .opacity(index < Int(volume / 6.25) ? 1 : 0.2)
                }
            }
            .padding(.horizontal, 20)

            Button(action: toggleMute) {
                HStack {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text(isMuted ? "Unmute" : "Mute")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.gray.opacity(0.4))
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
            
            Toggle("Launch at Login", isOn: $launchAtLoginEnabled)
                .toggleStyle(SwitchToggleStyle())
                .onChange(of: launchAtLoginEnabled) { newValue in
                    LaunchAtLogin.isEnabled = newValue
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
                .padding(.top, 5)
            

            Text("Connected to:")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 5) {
                Image(systemName: getDeviceIcon())
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                Text(outputDevice)
                    .font(.callout)
                    .foregroundColor(Color.white.opacity(0.85))
                    .bold()
            }

            Button(action: quitApp) {
                HStack {
                    Image(systemName: "power")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("Quit App")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.gray.opacity(0.4))
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 5)

        }
        .padding()
        .frame(width: 250, height: 270)
        .background(Color.gray.opacity(0.8))
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.4), radius: 8, x: 0, y: 4)
        .onAppear {
            volume = getCurrentVolume()
            isMuted = getMuteStatus()
            outputDevice = getCurrentOutputDevice()
            launchAtLoginEnabled = LaunchAtLogin.isEnabled
        }
    }

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func toggleMute() {
        isMuted.toggle()
        let script = isMuted ? "set volume with output muted" : "set volume without output muted"
        runAppleScript(script)
    }

    private func changeVolume(by amount: Double) {
        volume = max(0, min(100, volume + amount))
        updateSystemVolume(to: volume)
    }

    private func updateSystemVolume(to value: Double) {
        let script = "set volume output volume \(Int(value))"
        runAppleScript(script)
    }

    private func getCurrentVolume() -> Double {
        let result = runAppleScript("output volume of (get volume settings)")
        return Double(result) ?? 50.0
    }
    
    private func getMuteStatus() -> Bool {
        let result = runAppleScript("output muted of (get volume settings)")
        return result == "true"
    }

    private func getCurrentOutputDevice() -> String {
        let script = "system_profiler SPAudioDataType | grep -A2 'Default Output Device' | awk -F': ' '/Output Source/ {print $2}'"
        let deviceName = runShellScript(script)
        return deviceName.isEmpty ? "MacBook Speakers" : deviceName
    }

    private func getDeviceIcon() -> String {
        switch outputDevice {
        case let str where str.contains("AirPods"):
            return "airpodspro"
        case let str where str.contains("Headphones"):
            return "headphones"
        default:
            return "speaker.wave.3.fill"
        }
    }

    private func volumeColor(for index: Int) -> Color {
        if index < 5 { return .green }
        if index < 10 { return .yellow }
        return .orange
    }
    
    private func runAppleScript(_ command: String) -> String {
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    private func runShellScript(_ command: String) -> String {
        let process = Process()
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
