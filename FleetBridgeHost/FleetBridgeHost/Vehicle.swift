import Foundation

struct Vehicle: Equatable {
    let id: String
    let name: String
    let model: String
    var latitude: Double = 37.5665
    var longitude: Double = 126.9780
    var status: String = "idle"
    var battery: Int = 100
    var updatedAt: Date = Date()
    var refrigerationOn: Bool = false
    var revision: Int = 0

    var payload: [String: Any] {
        ["id": id, "name": name, "model": model, "latitude": latitude,
         "longitude": longitude, "status": status, "battery": battery,
         "updatedAt": updatedAt.timeIntervalSince1970 * 1000,
         "refrigerationOn": refrigerationOn, "revision": revision]
    }
}

final class VehicleRepository: NSObject {
    private(set) var vehicles: [Vehicle]
    var onChange: (() -> Void)?
    private var timer: Timer?
    private var pendingCommands: Set<String> = []

    init(vehicles: [Vehicle] = (1...10).map { index in
        Vehicle(id: "vehicle-\(index)", name: "차량 \(index)", model: "Fleet Model \(index)",
                latitude: 37.55 + Double(index) * 0.003,
                longitude: 126.96 + Double(index) * 0.003,
                status: ["driving", "idle", "offline"][(index - 1) % 3],
                battery: 95 - index * 3)
    }) { self.vehicles = vehicles; super.init() }

    func vehicle(id: String) -> Vehicle? { vehicles.first { $0.id == id } }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in self?.advance() }
    }
    func stop() { timer?.invalidate(); timer = nil }
    func advance(now: Date = Date()) {
        for i in vehicles.indices where vehicles[i].status != "offline" {
            if vehicles[i].status == "driving" {
                vehicles[i].latitude += 0.0001
                vehicles[i].longitude += 0.0001
            }
            vehicles[i].updatedAt = now
            vehicles[i].revision += 1
            if vehicles[i].revision % 6 == 0 {
                vehicles[i].status = vehicles[i].status == "driving" ? "idle" : "driving"
            }
            if vehicles[i].revision % 12 == 0 && vehicles[i].battery > 0 {
                vehicles[i].battery -= 1
            }
        }
        onChange?()
        NotificationCenter.default.post(name: .vehicleRepositoryDidChange, object: self)
    }
    /// Mock command only. Scenarios allow deterministic UI and timeout testing.
    func setRefrigeration(id: String, enabled: Bool, scenario: String, completion: @escaping (String) -> Void) {
        guard let vehicle = vehicle(id: id), vehicle.status != "offline" else { completion("failure"); return }
        guard pendingCommands.insert(id).inserted else { completion("busy"); return }
        let delay: TimeInterval = scenario == "timeout" ? 3 : 1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { completion("failure"); return }
            self.pendingCommands.remove(id)
            guard scenario == "success", let index = self.vehicles.firstIndex(where: { $0.id == id }) else {
                completion(scenario == "timeout" ? "timeout" : "failure"); return
            }
            self.vehicles[index].refrigerationOn = enabled
            self.vehicles[index].revision += 1
            self.onChange?()
            NotificationCenter.default.post(name: .vehicleRepositoryDidChange, object: self)
            completion("success")
        }
    }
    deinit { stop() }
}

extension Notification.Name {
    static let vehicleRepositoryDidChange = Notification.Name("vehicleRepositoryDidChange")
}
