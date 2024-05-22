//
//  ViewController.swift
//  MapApp
//
//  Created by iOS-Lab11 on 14.05.2024.
//

import UIKit
import MapKit
import CoreLocation // Kişinin konumunu almak için gerekli kütüphane
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    @IBOutlet weak var isimTextField: UITextField!
    @IBOutlet weak var notTextField: UITextField!
    
    //harita görünümü alındı
    // MKMapView bir UIKit olmadığı için hata verdiği için MapKit kütüphanesi import edildi
    @IBOutlet weak var mapView: MKMapView!
    
    // Core Location framework'ünün bir parçası olan bir sınıftır ve konum bilgisini yönetmek için kullanılır
    var locationManager = CLLocationManager()
    
    // Kaydet butonuna tıklandığında gerekli olan enlem ve boylamın alınması için oluşturulan değişkenler
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    // Seçilen isim ve seçilen id'ye diğer taraftan erişme
    var secilenIsim = ""
    var secilenId : UUID?
    
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ViewController sınıfının harita görünümü üzerindeki delegasyon görevlerini yerine getireceğini belirtir
        // Harita görünümündeki kullanıcı etkileşimleri veya harita verilerinin güncellenmesi gibi olaylar gerçekleştiğinde, bu olayların işlenmesinden ViewController sınıfının sorumlu olduğu anlamına gelir.
        mapView.delegate = self
        
        // konum yöneticisinin de delegasyonunu VC'a verilmesi gerekmektedir direk yazıldığında hata vereceği için CLLocationManagerDelegate'ın VC sınıfına eklenmesi gerekir.
        locationManager.delegate = self
        
        //Location manager ayarları:
        
        // 1- locationManager.desiredAccuracy özelliği, cihazın ne kadar doğru bir konum sağlamaya çalışacağını belirler
        // Ancak, her zaman en doğru konumu almak uygun olmayabilir çünkü bu daha fazla pil tüketimi ve cihaz kaynaklarının daha yoğun kullanımı anlamına gelebilir
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // 2- Yalnızca konum servisleri için "uygulama kullanıldığı zaman" iznini talep eder, yani uygulama ön planda çalışırken. Arka planda konum bilgisi almak için farklı bir izin gerekebilir (requestAlwaysAuthorization())
        locationManager.requestWhenInUseAuthorization()
        // 3- konumu güncellemeye başlama
        locationManager.startUpdatingLocation()
        
        
        //Annotation: Haritada İşaretleme Yapma
        // Bir yere tıklandığında algılama için :gestureRecognizer
        // UITapGestureRecognizer: Üstüne bir defa tıklandığında algılama yapar. Bu yüzden uzun bastığında algılamak için UILongPressGestrueRecognizer kullanılır.
        // konumSec() fonksiyonu parametre aldığı için gestureRecognizer'ı gönderiyoruz.
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer: )))
        
        // kullanıcı kaç sn basacak
        gestureRecognizer.minimumPressDuration = 2
        
        //mapView'a gestureRecognizer ekleme
        mapView.addGestureRecognizer(gestureRecognizer)
        
        // Veri Çekme ve Veri Ekleme İşlemi
        if secilenIsim != "" {
            // Eğer isim eklendiyse Core Data'dan verileri çek
            if let uuidString = secilenId?.uuidString{
                // print(uuidString)
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let contex = appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                //filtreleme işlemi
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                
                fetchRequest.returnsObjectsAsFaults = false
                // tableView'da bulunan konumlara tıklandığında mapview üzerinde ilgili konum gösterilir ve textfield'lerin içlerine yer ve not yazılır
                do {
                    
                    let sonuclar = try contex.fetch(fetchRequest)
                    
                    if sonuclar.count > 0 
                    
                    {
                        for sonuc in sonuclar as! [NSManagedObject]{
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
                                            
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            isimTextField.text = annotationTitle
                                            notTextField.text = annotationSubTitle
                                            
                                            //stopUpdatingLocation() fonksiyonunu çağırma
                                            locationManager.stopUpdatingLocation()
                                            
                                            //mapView.setRegion demek için öncesinde region, coordinate ve span oluşturmak gereklidir.
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    
                }
                
            }
            
        } else {
            // Yeni Veri Ekleme
            
        }
    }
    
    //gestureRecognizer değişkenine konumSec() fonksiyonu içerisinde ulaşmak istiyoruz çünkü kullanıcının tıklandığı yeri buradan alacağız.
    @objc func konumSec(gestureRecognizer: UILongPressGestureRecognizer){
        
        //algılayıcı başladı mı?
        if gestureRecognizer.state == .began {
            // kullanıcının uzun tıkladığı yerdeki noktayı hesaplayıp konum olarak verir.
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            
            //dokunulanNokta (CGPoint)'nın özelliklerine ulaşmak için:
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView)
            
            //Enlem ve Boylam alındı
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            // İşaretleme
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKoordinat
            annotation.title = isimTextField.text
            annotation.subtitle = notTextField.text
            mapView.addAnnotation(annotation)
        }
        
    }
    
    // Konum Güncel Mi?
    // locations bir dizi ve her güncellemede tek tek konumlar geliyor
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        /* enlem (latitude)
         print(locations[0].coordinate.latitude)
         boylam (longitude)
         print(locations[0].coordinate.longitude)
         */
        
        //Kullanıcının konumu eğer İstanbul ise ve Pin'i eklediği yeri göremeyecektir. Bunu engellemek için aşağıdaki işlemleri if bloguna almamız gerekir ve stopUpdatingLocation() fonksiyonunu eklememiz gerekmektedir.
        if secilenIsim == "" {
            
            // Konum Oluşturma: Alınan enlem ve boylamdan bir konum oluşturulabilir. MKCoordinateRegion fonksiyonunda bulunan center özelliğine location yazılacak.
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            
            //Belirtilen bölgenin yükseklik ve genişliğini alır. Böylece zoom'lama yapılabilir.
            // 0.1 olduğunda daha özel bir alan açılır. 0.9'a göre daha az zoomlama yapılır. 0.9 olduğunda daha genel bir alan açılır. Daha fazla zoomlama yapılır
            let span = MKCoordinateSpan(latitudeDelta: 0.9, longitudeDelta: 0.9)
            
            //Haritadan bir yere gitmek için: setRegion() kullanılır
            let region = MKCoordinateRegion(center: location, span: span)
            //yukarıda oluşturulan region aşağıda yazılır
            mapView.setRegion(region, animated: true)
            
        }
        
        //Core Data kullanarak veri kaydı yapmak
    func kaydetTiklandi(_ sender: Any) {
            // 1- AppDelegate'e ulaşmak:
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            // 2- Bir veri depolama alanı olan NSManagedObjectContext'i al
            let context = appDelegate.persistentContainer.viewContext
            // 3- Veritabanına yeni bir öğe eklemek için kullanılır
            // NSEnttityDescription'ı kullanmak için import Core Data yapıldı.
            let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
            
            yeniYer.setValue(isimTextField.text, forKey: "isim")
            yeniYer.setValue(notTextField.text, forKey: "not")
            
            //secilen latitude ve longitude'ın alınması
            yeniYer.setValue(secilenLatitude, forKey: "latitude")
            yeniYer.setValue(secilenLongitude, forKey: "longitude")
            yeniYer.setValue(UUID(), forKey: "id")
            
            do {
                try context.save()
                print ("Kayıt İşlemi Tamamlandı")
                
            }catch {
                print("Hata!")
            }
            
            // Kaydetme işlemini bildirip TableView üzerinden gösterme
            NotificationCenter.default.post(name: NSNotification.Name("yeniYerOlusturuldu"), object: nil)
            navigationController?.popViewController(animated: true)
            
            
            
        }
        
        
    }
}
