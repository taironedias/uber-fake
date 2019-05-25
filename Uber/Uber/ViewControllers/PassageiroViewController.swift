//
//  PassageiroViewController.swift
//  Uber
//
//  Created by Tairone Dias on 24/05/19.
//  Copyright © 2019 DiasDevelopers. All rights reserved.
//

import UIKit
import FirebaseAuth
import MapKit

class PassageiroViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapa: MKMapView!
    var gerenciadorLocalizacao = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gerenciadorLocalizacao.delegate = self
        gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest
        gerenciadorLocalizacao.requestWhenInUseAuthorization()
        gerenciadorLocalizacao.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Recupera as coordenadas do local atual
        if let coordenadas = manager.location?.coordinate {
            let regiao = MKCoordinateRegion.init(center: coordenadas, latitudinalMeters: 200, longitudinalMeters: 200)
            self.mapa.setRegion(regiao, animated: true)
            
            // Remove anotacoes antes de criar
            self.mapa.removeAnnotations(self.mapa.annotations)
            
            // Criando o anotacoes para o local do usuário
            let anotacaoUsuario = MKPointAnnotation()
            anotacaoUsuario.coordinate = coordenadas
            anotacaoUsuario.title = "Seu local"
            self.mapa.addAnnotation(anotacaoUsuario)
        }
        
        
        
    }
    
    @IBAction func sairSistema(_ sender: Any) {
        let autenticar = Auth.auth()
        do {
            try autenticar.signOut()
            dismiss(animated: true, completion: nil)
        } catch {
            print("Não foi possível deslogar o usuário")
        }
    }
    
}
