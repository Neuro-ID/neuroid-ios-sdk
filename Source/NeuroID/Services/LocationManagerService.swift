//
//  LocationManagerService.swift
//  NeuroID
//
//  Created by Kevin Sites on 1/3/25.
//
import CoreLocation

protocol LocationManagerServiceProtocol {
    var latitude: Double? { get }
    var longitude: Double? { get }
    var authorizationStatus: String { get }

    func checkLocationAuthorization()
}

class LocationManagerService: NSObject, CLLocationManagerDelegate, LocationManagerServiceProtocol {
    let manager = CLLocationManager()
    var latitude: Double?
    var longitude: Double?
    var authorizationStatus: String = "unknown"

    override init() {
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func checkLocationAuthorization() {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
            case .notDetermined:
                self.authorizationStatus = "notDetermined"
            case .restricted, .denied:
                self.authorizationStatus = status == .restricted ? "restricted" : "denied"
            case .authorizedWhenInUse, .authorizedAlways:
                self.authorizationStatus = status == .authorizedWhenInUse ? "authorizedWhenInUse" : "authorizedAlways"
                self.manager.startUpdatingLocation()
            @unknown default:
                break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.checkLocationAuthorization()
    }
}
