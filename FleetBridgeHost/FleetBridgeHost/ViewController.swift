import UIKit

final class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let repository = VehicleRepository()
    private lazy var detailCoordinator = VehicleDetailCoordinator(repository: repository)
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "차량 목록"
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        repository.vehicles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "vehicle", for: indexPath)
        let vehicle = repository.vehicles[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = vehicle.name
        content.secondaryText = vehicle.model
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
