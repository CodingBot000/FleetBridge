import UIKit

final class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let repository = VehicleRepository()
    private lazy var detailCoordinator = VehicleDetailCoordinator(repository: repository)
    private var lifecycleObservers: [NSObjectProtocol] = []
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "차량 목록"
        repository.onChange = { [weak self] in self?.tableView.reloadData() }
        repository.start()
        let center = NotificationCenter.default
        lifecycleObservers = [
            center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in self?.repository.stop() },
            center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in self?.repository.start() }
        ]
        view.backgroundColor = .systemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "vehicle")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    deinit {
        lifecycleObservers.forEach { NotificationCenter.default.removeObserver($0) }
        repository.stop()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        repository.vehicles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "vehicle", for: indexPath)
        let vehicle = repository.vehicles[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = vehicle.name
        let state = ["driving": "운행 중", "idle": "대기", "offline": "오프라인"][vehicle.status] ?? vehicle.status
        content.secondaryText = "\(vehicle.model) · \(state) · 배터리 \(vehicle.battery)%"
        cell.contentConfiguration = content
        cell.accessibilityIdentifier = vehicle.id
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vehicle = repository.vehicles[indexPath.row]
        #if DEBUG
        let id = ProcessInfo.processInfo.arguments.contains("-ui-test-invalid-vehicle") ? "invalid-vehicle" : vehicle.id
        #else
        let id = vehicle.id
        #endif
        detailCoordinator.present(id: id, from: self)
    }
}
