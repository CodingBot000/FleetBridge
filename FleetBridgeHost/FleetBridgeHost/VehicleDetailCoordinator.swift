import Flutter
import UIKit

/// A presentation owns exactly one engine; closing it destroys the Dart isolate.
final class VehicleDetailCoordinator: NSObject, UIAdaptivePresentationControllerDelegate {
    private let repository: VehicleRepository
    private var engine: FlutterEngine?
    private var isClosing = false
    private var channel: FlutterMethodChannel?
    private var observer: NSObjectProtocol?
    private weak var controller: FlutterViewController?

    init(repository: VehicleRepository) {
        self.repository = repository
    }

    func present(id: String, from presenter: UIViewController) {
        guard engine == nil else { return }
        #if DEBUG
        let startTime = CACurrentMediaTime()
        var measuredFrameMs: Double?
        #endif
        let engine = FlutterEngine(name: "vehicle-detail")
        self.engine = engine
        var components = URLComponents()
        components.path = "/"
        components.queryItems = [URLQueryItem(name: "id", value: id)]
        #if DEBUG
        if ProcessInfo.processInfo.environment["FLEETBRIDGE_UI_TEST"] == "1" {
            components.queryItems?.append(URLQueryItem(name: "mapTestMode", value: "1"))
            if ProcessInfo.processInfo.environment["FLEETBRIDGE_MEASURE"] == "1" {
                components.queryItems?.append(URLQueryItem(name: "measure", value: "1"))
            }
        }
        #endif
        guard engine.run(withEntrypoint: nil, initialRoute: components.string) else {
            tearDown()
            let alert = UIAlertController(title: "상세 화면 오류", message: "화면을 시작할 수 없습니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            presenter.present(alert, animated: true)
            return
        }
        let channel = FlutterMethodChannel(name: "fleetbridge/vehicle", binaryMessenger: engine.binaryMessenger)
        self.channel = channel
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { result(FlutterError(code: "unavailable", message: nil, details: nil)); return }
            switch call.method {
            case "getVehicle":
                guard let args = call.arguments as? [String: Any], let id = args["id"] as? String,
                      let vehicle = self.repository.vehicle(id: id) else {
                    result(FlutterError(code: "not_found", message: "Vehicle not found", details: nil)); return
                }
                result(vehicle.payload)
            case "setRefrigeration":
                guard let args = call.arguments as? [String: Any],
                      let vehicleID = args["id"] as? String, vehicleID == id,
                      let enabled = args["enabled"] as? Bool,
                      let scenario = args["scenario"] as? String,
                      ["success", "failure", "timeout"].contains(scenario) else {
                    result(FlutterError(code: "invalid_command", message: nil, details: nil)); return
                }
                self.repository.setRefrigeration(id: vehicleID, enabled: enabled, scenario: scenario) { [weak self, weak engine] outcome in
                    guard let engine, self?.engine === engine else { return }
                    result(outcome)
                }
            #if DEBUG
            case "reportFirstFrame":
                result(measuredFrameMs)
            #endif
            case "openMapAttribution":
                guard let url = URL(string: "https://www.openstreetmap.org/copyright") else { result(false); return }
                UIApplication.shared.open(url) { result($0) }
            case "close":
                guard !self.isClosing else { result(nil); return }
                self.isClosing = true
                result(nil)
                guard let controller = self.controller else { self.tearDown(); return }
                controller.dismiss(animated: true) { [weak self] in self?.tearDown() }
            default: result(FlutterMethodNotImplemented)
            }
        }
        observer = NotificationCenter.default.addObserver(forName: .vehicleRepositoryDidChange, object: repository, queue: .main) { [weak self] _ in
            guard let self, let vehicle = self.repository.vehicle(id: id) else { return }
            self.channel?.invokeMethod("vehicleUpdated", arguments: vehicle.payload)
        }
        let controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        self.controller = controller
        #if DEBUG
        if ProcessInfo.processInfo.environment["FLEETBRIDGE_MEASURE"] == "1" {
            controller.setFlutterViewDidRenderCallback {
                if measuredFrameMs == nil { measuredFrameMs = (CACurrentMediaTime() - startTime) * 1000 }
            }
        }
        #endif
        controller.modalPresentationStyle = .fullScreen
        controller.presentationController?.delegate = self
        presenter.present(controller, animated: true)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { tearDown() }

    private func tearDown() {
        if let observer { NotificationCenter.default.removeObserver(observer); self.observer = nil }
        channel?.setMethodCallHandler(nil)
        channel = nil
        controller = nil
        engine?.destroyContext()
        engine = nil
        isClosing = false
    }
    deinit { tearDown() }
}
