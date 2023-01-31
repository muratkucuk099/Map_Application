//
//  ViewController.swift
//  HaritaUygulaması2
//
//  Created by Mac on 27.01.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var notTextfield: UITextField!
    @IBOutlet weak var isimTextfield: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    var locationManager = CLLocationManager()
    var secilenIsim = ""
    var secilenId : UUID?
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        mapView.showsUserLocation = false
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer: )))
        gestureRecognizer.minimumPressDuration = 1
        mapView.addGestureRecognizer(gestureRecognizer)
        
        let gestureRecognizerKeyboard = UITapGestureRecognizer(target: self, action: #selector(turnOffKeyboard))
        view.addGestureRecognizer(gestureRecognizerKeyboard)
        
        if secilenIsim != "" {
            saveButton.isHidden = true
            
            // CoreData veri çek
            if let uuidString = secilenId?.uuidString {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do{
                    let sonuclar = try context.fetch(fetchRequest)
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject] {
                            if let isim = sonuc.value(forKey: "isim") as? String {
                                annotationTitle = isim
                                if let not = sonuc.value(forKey: "not") as? String {
                                    annotationSubTitle = not
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubTitle
                                            let cootdinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = cootdinate
                                            mapView.addAnnotation(annotation)
                                            isimTextfield.text = annotationTitle
                                            notTextfield.text = annotationSubTitle
                                            
                                            locationManager.stopUpdatingLocation()
                                            let span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                                            let region = MKCoordinateRegion(center: cootdinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    print("Error")
                }
            }
        } else {
            saveButton.isHidden = false
            // yeni veri ekleme
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "annotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: 
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenIsim != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkDizisi, hata) in
                if let placemarks = placemarkDizisi {
                    if placemarks.count > 0 {
                        
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlacemark)
                        item.name = self.annotationTitle
                        // Hangi araçla gideceği seçiliyor
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
               
            }
        }
    }
    
    @objc func konumSec(gestureRecognizer : UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView)
            
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKoordinat
            annotation.title = isimTextfield.text
            annotation.subtitle = notTextfield.text
            mapView.addAnnotation(annotation)
            
        }
    }
    
    @objc func turnOffKeyboard() {
        view.endEditing(true)
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if secilenIsim == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude,
                                                  longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func kaydetButton(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        
       
        if isimTextfield.text != "" && notTextfield.text != "" && secilenLatitude != 0 && secilenLongitude != 0 {
            yeniYer.setValue(isimTextfield.text, forKey: "isim")
            yeniYer.setValue(notTextfield.text, forKey: "not")
            yeniYer.setValue(secilenLatitude, forKey: "latitude")
            yeniYer.setValue(secilenLongitude, forKey: "longitude")
            yeniYer.setValue(UUID(), forKey: "id")
            
            NotificationCenter.default.post(name: NSNotification.Name("yeniYerOlusturuldu"), object: nil)
            navigationController?.popViewController(animated: true)
        } else {
            let menu = UIAlertController(title: "CAN NOT SAVE!", message: "Please enter the information and choose pin!", preferredStyle: .alert)
            menu.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(menu, animated: true)
        }
        
        do {
           
                try context.save()
                print("kayıt edildi")
            
        } catch {
            print("error")
        }
        // Önceki sayfaya dönmek için
       
        
    }
    
}
