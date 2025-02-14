import Cocoa
import CocoaMQTT
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var mqttClient: CocoaMQTT?
    var popover = NSPopover()
    let volumeController = NSHostingController(rootView: VolumeView())
    let bonjourService = BonjourService() 
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "speaker.3.fill", accessibilityDescription: "Audio Control")
            button.action = #selector(togglePopover)
        }
        
        popover.contentViewController = volumeController
        popover.behavior = .transient

        startMosquitto()
        setupMQTT()
        bonjourService.start()
    }

    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    func startMosquitto() {
        print("🔍 Checking if Mosquitto is installed...")


        let checkMosquitto = Process()
        checkMosquitto.launchPath = "/bin/zsh"
        checkMosquitto.arguments = ["-c", "source ~/.zshrc; env | grep PATH; command -v mosquitto"]

        let pathPipe = Pipe()
        checkMosquitto.standardOutput = pathPipe
        checkMosquitto.launch()
        checkMosquitto.waitUntilExit()

        let pathData = pathPipe.fileHandleForReading.readDataToEndOfFile()
        let mosquittoPath = String(data: pathData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if mosquittoPath.isEmpty {
            print("❌ Mosquitto is not installed or not in PATH. Please install it with 'brew install mosquitto'.")
            return
        }

        print("✅ Mosquitto is installed at: \(mosquittoPath)")
        print("🔍 Checking if Mosquitto is running...")

        let checkProcess = Process()
        checkProcess.launchPath = "/bin/zsh"
        checkProcess.arguments = ["-c", "source ~/.zshrc; pgrep mosquitto"]

        let pipe = Pipe()
        checkProcess.standardOutput = pipe
        checkProcess.launch()
        checkProcess.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if output.isEmpty {
            print("⚡ Starting Mosquitto in the background...")
            let startProcess = Process()
            startProcess.launchPath = "/bin/zsh"
            startProcess.arguments = ["-c", "source ~/.zshrc; mosquitto -c /opt/homebrew/etc/mosquitto/mosquitto.conf -d"]
            startProcess.launch()
        } else {
            print("✅ Mosquitto is already running.")
        }
    }


    func setupMQTT() {
        let clientID = "MacAudioController-" + String(ProcessInfo().processIdentifier)
        mqttClient = CocoaMQTT(clientID: clientID, host: "localhost", port: 1883)
        mqttClient?.delegate = self
        mqttClient?.connect()
    }

    @objc func increaseVolume() {
        runAppleScript("set volume output volume ((output volume of (get volume settings)) + 5)")
    }

    @objc func decreaseVolume() {
        runAppleScript("set volume output volume ((output volume of (get volume settings)) - 5)")
    }

    @objc func toggleMute() {
        let script = """
        set currentMute to output muted of (get volume settings)
        if currentMute is false then
            set volume with output muted
        else
            set volume without output muted
        end if
        """
        runAppleScript(script)
    }

    func runAppleScript(_ command: String) {
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        process.launch()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        print("AppleScript Output: \(output)")
    }
}


class BonjourService: NSObject, NetServiceDelegate {
    var service: NetService?

    func start() {
        print("📢 Advertising Mac via Bonjour...")
        service = NetService(domain: "local.", type: "_mqtt._tcp.", name: "MacAudioController", port: 1883)
        service?.delegate = self
        service?.publish()
    }

    func netServiceDidPublish(_ sender: NetService) {
        print("✅ Bonjour service published: \(sender.name).local")
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        print("❌ Failed to publish Bonjour service: \(errorDict)")
    }
}


extension AppDelegate: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("Connected to MQTT broker")
        mqtt.subscribe("mac/audio")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("Published message: \(message.string ?? "")")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("Message published with id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        guard let payload = message.string else { return }
        print("Received message: \(payload)")
        
        DispatchQueue.main.async { [weak self] in
            switch payload {
            case "increase":
                self?.increaseVolume()
            case "decrease":
                self?.decreaseVolume()
            case "mute":
                self?.toggleMute()
            default:
                print("Unknown command: \(payload)")
            }
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        print("Subscribed to topics: \(success), failed topics: \(failed)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        print("Unsubscribed from topics: \(topics)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("MQTT Ping")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("MQTT Pong received")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        print("Disconnected from MQTT broker: \(err?.localizedDescription ?? "No error")")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            print("Attempting to reconnect...")
            self?.mqttClient?.connect()
        }
    }
}
