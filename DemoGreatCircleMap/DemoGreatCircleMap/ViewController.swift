//
//  ViewController.swift
//  DemoGreatCircleMap
//
//  Created by Satheesh Prabhu Gurusamy on 12/10/25.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    let cityAField = UITextField()
    let cityBField = UITextField()
    let drawButton = UIButton(type: .system)
    let mapView = MKMapView()
    let geocoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        cityAField.placeholder = "Enter City A"
        cityAField.borderStyle = .roundedRect
        cityAField.frame = CGRect(x: 20, y: 60, width: view.frame.width - 40, height: 40)
        view.addSubview(cityAField)

        cityBField.placeholder = "Enter City B"
        cityBField.borderStyle = .roundedRect
        cityBField.frame = CGRect(x: 20, y: 110, width: view.frame.width - 40, height: 40)
        view.addSubview(cityBField)

        drawButton.setTitle("Show Great Circle", for: .normal)
        drawButton.frame = CGRect(x: 20, y: 160, width: view.frame.width - 40, height: 44)
        drawButton.addTarget(self, action: #selector(drawButtonTapped), for: .touchUpInside)
        view.addSubview(drawButton)

        mapView.frame = CGRect(x: 0, y: 220, width: view.frame.width, height: view.frame.height - 220)
        view.addSubview(mapView)
    }

    @objc func drawButtonTapped() {
        guard let cityA = cityAField.text, !cityA.isEmpty, let cityB = cityBField.text, !cityB.isEmpty else { return }
        geocodeCities(cityA: cityA, cityB: cityB)
    }

    func geocodeCities(cityA: String, cityB: String) {
        geocoder.geocodeAddressString(cityA) { [weak self] (placemarksA, errorA) in
            guard let self = self, let locationA = placemarksA?.first?.location else { return }
            self.geocoder.geocodeAddressString(cityB) { (placemarksB, errorB) in
                guard let locationB = placemarksB?.first?.location else { return }
                
                self.mapView.removeOverlays(self.mapView.overlays)
                self.mapView.removeAnnotations(self.mapView.annotations)
                
                // Add pins for both cities
                let annoA = MKPointAnnotation()
                annoA.coordinate = locationA.coordinate
                annoA.title = cityA
                let annoB = MKPointAnnotation()
                annoB.coordinate = locationB.coordinate
                annoB.title = cityB
                self.mapView.addAnnotations([annoA, annoB])

                // Draw great circle
                self.drawGreatCircle(from: locationA.coordinate, to: locationB.coordinate)

                // Adjust region
                let midLat = (locationA.coordinate.latitude + locationB.coordinate.latitude) / 2
                let midLon = (locationA.coordinate.longitude + locationB.coordinate.longitude) / 2
                let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: midLat, longitude: midLon), latitudinalMeters: 5000000, longitudinalMeters: 5000000)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }

    func drawGreatCircle(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        let points = interpolateGreatCircle(from: from, to: to, steps: 100)
        let polyline = MKPolyline(coordinates: points, count: points.count)
        mapView.addOverlay(polyline)
        mapView.delegate = self
    }

    // Interpolates a great circle route as a list of coordinates
    func interpolateGreatCircle(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, steps: Int) -> [CLLocationCoordinate2D] {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        var coords: [CLLocationCoordinate2D] = []
        for i in 0...steps {
            let f = Double(i) / Double(steps)
            let delta = 2 * asin(sqrt(pow(sin((lat2-lat1)/2),2) + cos(lat1)*cos(lat2)*pow(sin((lon2-lon1)/2),2)))
            let A = sin((1-f)*delta)/sin(delta)
            let B = sin(f*delta)/sin(delta)
            let x = A*cos(lat1)*cos(lon1) + B*cos(lat2)*cos(lon2)
            let y = A*cos(lat1)*sin(lon1) + B*cos(lat2)*sin(lon2)
            let z = A*sin(lat1) + B*sin(lat2)
            let lat = atan2(z, sqrt(x*x+y*y)) * 180 / .pi
            let lon = atan2(y, x) * 180 / .pi
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return coords
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
