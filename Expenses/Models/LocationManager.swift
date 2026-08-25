//
//  LocationManager.swift
//  Expenses
//
//  Created by Marcio Aun Migueis on 25/08/26.
//

import CoreLocation
import MapKit

@MainActor
final class LocationManager: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private var pendingContinuations: [CheckedContinuation<CLLocation?, Never>] = []

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // Suspends until the first location fix arrives, or returns nil if permission is denied.
    private func waitForLocation() async -> CLLocation? {
        if let location = currentLocation { return location }
        return await withCheckedContinuation { continuation in
            pendingContinuations.append(continuation)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                startUpdating()
            case .denied, .restricted:
                let pending = pendingContinuations
                pendingContinuations.removeAll()
                pending.forEach { $0.resume(returning: nil) }
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            currentLocation = locations.last
            let pending = pendingContinuations
            pendingContinuations.removeAll()
            pending.forEach { $0.resume(returning: currentLocation) }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func findAllNearbyPOIs(near location: CLLocation) async throws -> [PointOfInterest] {
        let request = MKLocalPointsOfInterestRequest(
            center: location.coordinate,
            radius: 1000
        )
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems.map { item in
            PointOfInterest(
                name: item.name ?? "Unknown",
                coordinate: item.placemark.coordinate,
                category: item.pointOfInterestCategory?.rawValue
            )
        }
    }

    func getPOI() async -> PointOfInterest? {
        guard let location = await waitForLocation() else { return nil }
        let request = MKLocalPointsOfInterestRequest(
            center: location.coordinate,
            radius: 1000
        )
        let search = MKLocalSearch(request: request)
        let response = try? await search.start()
        return response?.mapItems.compactMap { item in
            PointOfInterest(
                name: item.name ?? "Unknown",
                coordinate: item.placemark.coordinate,
                category: item.pointOfInterestCategory?.rawValue
            )
        }.first
    }
}

struct PointOfInterest: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let category: String?
}
