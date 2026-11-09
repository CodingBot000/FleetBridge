import Foundation

struct Vehicle: Equatable {
    let id: String
    let name: String
    let model: String
}

struct VehicleRepository {
    let vehicles: [Vehicle]

    init(vehicles: [Vehicle] = (1...10).map {
        Vehicle(id: "vehicle-\($0)", name: "차량 \($0)", model: "Fleet Model \($0)")
    }) {
        self.vehicles = vehicles
    }

    func vehicle(id: String) -> Vehicle? {
        vehicles.first { $0.id == id }
    }
}
