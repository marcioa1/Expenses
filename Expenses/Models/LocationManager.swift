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
    private(set) var currentLocation: CLLocation?
    private var pendingContinuations: [CheckedContinuation<CLLocation?, Never>] = []
    /// `true` while waiting for the user to answer the permission prompt.
    private var isAwaitingAuthorization = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Suspends until a single location fix arrives; returns `nil` if permission is denied or the fix fails.
    ///
    /// Permission is only requested here, the first time a location is actually needed.
    /// `requestLocation()` delivers one fix (or an error) and then stops on its own, so the GPS
    /// doesn't keep running after the form gets its location.
    private func waitForLocation() async -> CLLocation? {
        if let currentLocation { return currentLocation }
        switch manager.authorizationStatus {
        case .denied, .restricted:
            return nil
        default:
            break
        }
        return await withCheckedContinuation { continuation in
            pendingContinuations.append(continuation)
            // Only the first caller starts a request; later callers share its result.
            guard pendingContinuations.count == 1 else { return }
            if manager.authorizationStatus == .notDetermined {
                // The fix is requested in `locationManagerDidChangeAuthorization` once the user answers.
                isAwaitingAuthorization = true
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestLocation()
            }
        }
    }

    /// Resumes every caller waiting in `waitForLocation()`, so none of them stays suspended forever.
    private func resumePending(with location: CLLocation?) {
        let pending = pendingContinuations
        pendingContinuations.removeAll()
        pending.forEach { $0.resume(returning: location) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            // Also called when the delegate is set; only react to the prompt we triggered.
            guard isAwaitingAuthorization else { return }
            switch self.manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                isAwaitingAuthorization = false
                self.manager.requestLocation()
            case .denied, .restricted:
                isAwaitingAuthorization = false
                resumePending(with: nil)
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            currentLocation = locations.last
            resumePending(with: currentLocation)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // `requestLocation()` ends after reporting an error, so waiting callers get `nil` instead of hanging.
        Task { @MainActor in
            resumePending(with: nil)
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
