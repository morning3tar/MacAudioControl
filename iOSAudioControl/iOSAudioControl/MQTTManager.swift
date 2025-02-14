import SwiftUI
import CocoaMQTT
import Network

class MQTTManager: NSObject, ObservableObject, NetServiceBrowserDelegate, CocoaMQTTDelegate {
    private var mqttClient: CocoaMQTT?
    private var serviceBrowser: NetServiceBrowser?

    @Published var discoveredHost: String? = nil

    override init() {
        super.init()
        discoverMac()
    }

    func discoverMac() {
        print("🔍 Searching for Mac's MQTT service...")
        serviceBrowser = NetServiceBrowser()
        serviceBrowser?.delegate = self
        serviceBrowser?.searchForServices(ofType: "_mqtt._tcp.", inDomain: "local.")
    }

    func connectToMQTT(host: String) {
        print("✅ Connecting to MQTT at \(host)")
        mqttClient = CocoaMQTT(clientID: "iPhoneController", host: host, port: 1883)
        mqttClient?.delegate = self
        mqttClient?.autoReconnect = true
        mqttClient?.connect()
    }

    func sendCommand(_ command: String) {
        print("📡 Sending command: \(command)")
        mqttClient?.publish("mac/audio", withString: command)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("✅ Found MQTT Service: \(service.name), Hostname: \(service.hostName ?? "Unknown")")

        if let hostName = service.hostName {
            DispatchQueue.main.async {
                self.discoveredHost = hostName
            }
            connectToMQTT(host: hostName)
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        print("❌ Bonjour search failed, trying fallback hostname...")

        DispatchQueue.main.async {
            self.discoveredHost = nil
        }

        let fallbackHost = "Your-Hostname-Here.local"
        connectToMQTT(host: fallbackHost)
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("✅ Connected to MQTT broker")
        DispatchQueue.main.async {
            self.discoveredHost = mqtt.host
        }
        mqtt.subscribe("mac/audio")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("✅ Published message: \(message.string ?? "")")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("✅ Message published with id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        print("📩 Received message: \(message.string ?? "")")
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        print("❌ Disconnected from MQTT broker: \(err?.localizedDescription ?? "No error")")

        DispatchQueue.main.async {
            self.discoveredHost = nil
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        print("✅ Subscribed to topics: \(success), failed topics: \(failed)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        print("🔄 Unsubscribed from topics: \(topics)")
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("📡 MQTT Ping Sent")
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("📡 MQTT Pong Received")
    }


    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        print("🔄 MQTT State Changed: \(state)")

        DispatchQueue.main.async {
            self.discoveredHost = (state == .connected) ? mqtt.host : nil
        }
    }


    func mqtt(_ mqtt: CocoaMQTT, didConnectError error: Error?) {
        print("❌ Connection Error: \(error?.localizedDescription ?? "Unknown error")")
    }

    func mqtt(_ mqtt: CocoaMQTT, didCompleteConnectWithError error: Error?) {
        if let error = error {
            print("❌ Connection Failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.discoveredHost = nil
            }
        } else {
            print("✅ Connection Successful")
        }
    }
}
