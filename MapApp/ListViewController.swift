//
//  ListViewController.swift
//  MapApp
//
//  Created by iOS-Lab11 on 14.05.2024.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var isimDizisi = [String]()
    var idDizisi = [UUID]()
    // burada da secilen id ve ismi için tekrardan bir değişken oluşturulur
    var secilenYerIsmi = ""
    var secilenYerId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TableView ayarlarının yapılması:
        // 1- UITableViewDelegate ve UITableViewDataSource eklendi
        // 2- viewDidLoad() içerisinde aşağıdaki kodlar eklenir
        tableView.delegate = self
        tableView.dataSource = self
        
        // + işaretinin en üste eklenmesi
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(artiButtonuTiklandi))
        veriAl()
    }
    
    //TableView'da kaydedilen konumu gösterme
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(veriAl), name: NSNotification.Name("yeniYerOlusturuldu"), object: nil)
    }
    
    // Veri Alma İşlemleri
    @objc func veriAl()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let contex = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
        request.returnsObjectsAsFaults = false
        
        do {
            // contex.fetch ile sonuçların olduğu bir dizi verilir
            let sonuclar = try contex.fetch(request)
            //gelen bir sonuç varsa
            if sonuclar.count > 0 {
            // for blogu çalışmadan isimDizisini ve idDizisini boşaltma
                isimDizisi.removeAll(keepingCapacity: false)
                idDizisi.removeAll(keepingCapacity: false)
                
                // sonuclar: Any olduğu için NSManagedObject'e cast ediyoruz
                for sonuc in sonuclar as! [NSManagedObject] 
                {
                    // ismi String'e cast ediyoruz
                    if let isim = sonuc.value(forKey: "isim") as? String
                    {
                        isimDizisi.append(isim)
                    }
                    
                    // id'yi UUID'ye cast ediyoruz
                    if let id = sonuc.value(forKey: "id") as? UUID
                    {
                        idDizisi.append(id)
                    }
                    
                }
                // tableView'i yeni dizi geldiğinde yeniliyoruz
                tableView.reloadData()
            }
        } 
        catch
        {
            print("Hata")
        }
    }

    
    @objc func artiButtonuTiklandi(){
        // + butonuna tıklandığında secilen yer ismi "" gelsin ve yeni veri ekleneceği belli olsun
        secilenYerIsmi = ""
        //performSegue ekleme
        performSegue(withIdentifier: "toMapsVC", sender: nil)
       
        
        
        
    }
    
    // 3- Gerekli fonksiyonlar çağrılır (numberOfRowsInSection ve cellForRowAt)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isimDizisi.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 4- UITableViewCell () oluşturulur
        let cell = UITableViewCell()
        cell.textLabel?.text = isimDizisi[indexPath.row]
        return cell
    }
    
    // Table view'da herhangi bir row'a tıklandıysa
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        secilenYerIsmi = isimDizisi[indexPath.row]
        secilenYerId = idDizisi[indexPath.row]
        
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
    // segue'yi hazırlama
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapsVC"
        {
            // MapsViewController da bulunan özelliklere erişmek için:
            let destinationVC = segue.destination as! MapsViewController
            destinationVC.secilenIsim = secilenYerIsmi
            destinationVC.secilenId = secilenYerId
        }
    }


}
