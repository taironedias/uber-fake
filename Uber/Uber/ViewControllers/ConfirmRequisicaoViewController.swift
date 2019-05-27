//
//  ConfirmRequisicaoViewController.swift
//  Uber
//
//  Created by Tairone Dias on 25/05/19.
//  Copyright © 2019 DiasDevelopers. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class ConfirmRequisicaoViewController: UIViewController {

    @IBOutlet weak var mapa: MKMapView!
    
    var nomePassageiro = ""
    var emailPassageiro = ""
    var localPassageiro = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configurar a área inicial do mapa
        let regiao = MKCoordinateRegion.init(center: self.localPassageiro, latitudinalMeters: 100, longitudinalMeters: 100)
        self.mapa.setRegion(regiao, animated: true)
        
        // Remove anotacoes antes de criar
        self.mapa.removeAnnotations(self.mapa.annotations)
        
        // Criando o anotacoes para o local do usuário
        let anotacaoPassageiro = MKPointAnnotation()
        anotacaoPassageiro.coordinate = self.localPassageiro
        anotacaoPassageiro.title = self.nomePassageiro
        self.mapa.addAnnotation(anotacaoPassageiro)
        
    }
    
    @IBAction func aceitarCorrida(_ sender: Any) {
        // Atualizar requisicao
        let db = Database.database().reference()
        let requisicoes = db.child("requisicoes")
        
        requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro).observeSingleEvent(of: .childAdded) { (snapshot) in
            
            let dadosMotor = [
                "latMotor": self.localMotorista.latitude,
                "longMotor": self.localMotorista.longitude
            ]
            
            // O snapshot.ref é o acesso direto no Firebase, por isso, para adicionar novos dados colocamos apenas o updateChildValues
            snapshot.ref.updateChildValues(dadosMotor)
            
            // Exibir caminho para o passageiro no mapa
            let passageiroCLL = CLLocation(latitude: self.localPassageiro.latitude, longitude: self.localPassageiro.longitude)
            CLGeocoder().reverseGeocodeLocation(passageiroCLL, completionHandler: { (local, error) in
                if error != nil {
                    print("Erro no CLGeocoder em ConfirmRequisicaoViewController")
                    return
                }
                
                if let dadosLocal = local?.first {
                    let placeMark = MKPlacemark(placemark: dadosLocal)
                    let mapaItem = MKMapItem(placemark: placeMark)
                    mapaItem.name = self.nomePassageiro
                    
                    let opcoes = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                    mapaItem.openInMaps(launchOptions: opcoes)
                }
            })
            
        }
        
    }
    

}
