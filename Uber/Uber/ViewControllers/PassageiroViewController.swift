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
import FirebaseDatabase

class PassageiroViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var btnChamarUber: UIButton!
    var gerenciadorLocalizacao = CLLocationManager()
    var localUser = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    var uberChamado = false
    var uberACaminho = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gerenciadorLocalizacao.delegate = self
        gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest
        gerenciadorLocalizacao.requestWhenInUseAuthorization()
        gerenciadorLocalizacao.startUpdatingLocation()
        
        // Verifica se já tem uma requisicao de Uber
        let db = Database.database().reference()
        let requisicoes = db.child("requisicoes")
        let auth = Auth.auth()
        
        if let emailUser = auth.currentUser?.email {
            let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: emailUser)
            
            // Adicioando ouvinte para quando o usuario chamar o Uber
            consultaRequisicoes.observe(.childAdded) { (snapshot) in
                if snapshot.value == nil {
                    print("snapshot está vazio!")
                    return
                }
                
                // Essa estrutura trata o seguinte cenario: o usuario chamou o Uber, o motorista aceitou e o celular fechou. Caso o usuario chamou o Uber e o celular fechou, continua conforme a execucao anterior que só muda a cor e nome do button
                if self.analisaCorridaAceita(dataSnapshot: snapshot) {
                    self.exibirMotoristaAndPassageiro()
                } else {
                    self.alternaBtnChamarUber(title: "Cancelar Uber", redM: 0.831, greenM: 0.237, blueM: 0.146)
                    print("Não existe latMotor e longMotor no Firebase!")
                }
                
            }
            
            // Adicionando ouvinte para quando o motorista aceitar a corrida
            consultaRequisicoes.observe(.childChanged) { (snapshot) in
                if snapshot.value == nil {
                    print("snapshot está vazio!")
                    return
                }
                
                if self.analisaCorridaAceita(dataSnapshot: snapshot) {
                    self.exibirMotoristaAndPassageiro()
                } else {
                    print("Não foi possível recuperar latMotor e longMotor no Firebase!")
                }
                
            }
        }
        
        
        
    }
    
    func analisaCorridaAceita(dataSnapshot: DataSnapshot) -> Bool {
        if let dados = dataSnapshot.value as? [String: Any] {
            if let latMotor = dados["latMotor"] as? CLLocationDegrees {
                if let longMotor = dados["longMotor"] as? CLLocationDegrees {
                    self.localMotorista = CLLocationCoordinate2D(latitude: latMotor, longitude: longMotor)
                    return true
                }
            }
        }
        return false
    }
    
    func exibirMotoristaAndPassageiro() {
        
        /* Calcula a distância entre motorista e passageiro */
        let motoristaLocation = CLLocation(latitude: self.localMotorista.latitude, longitude: self.localMotorista.longitude)
        let passageiroLocation = CLLocation(latitude: self.localUser.latitude, longitude: self.localUser.longitude)
        
        let distancia = motoristaLocation.distance(from: passageiroLocation)
        let distanciaKM = round(distancia / 1000)
        self.btnChamarUber.setTitle("Motorista à \(distanciaKM) km", for: .normal)
        self.btnChamarUber.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        
        /* Exibir o passageiro e motorista no mapa */
        self.uberACaminho = true
        
            // Fazendo o calculo para setar a visualizacao de ambos (motorista e passageiro) na tela. O  * 300000 é para a visualizacao está adequada conforme a diferença
        let latDiff = abs(self.localUser.latitude - self.localMotorista.latitude) * 300000
        let longDiff = abs(self.localUser.longitude - self.localMotorista.longitude)  * 300000
        
            // Criando a regiao para setar no mapa
        let regiao = MKCoordinateRegion.init(center: self.localUser, latitudinalMeters: latDiff, longitudinalMeters: longDiff)
        self.mapa.setRegion(regiao, animated: true)
        
            // Remove anotacoes antes de criar
        self.mapa.removeAnnotations(self.mapa.annotations)
        
            // Criando o anotacoes para o local do usuário
        let annotMotorista = MKPointAnnotation()
        annotMotorista.coordinate = self.localMotorista
        annotMotorista.title = "Motorista"
        self.mapa.addAnnotation(annotMotorista)
        
        let annotPassageiro = MKPointAnnotation()
        annotPassageiro.coordinate = self.localUser
        annotPassageiro.title = "Seu local"
        self.mapa.addAnnotation(annotPassageiro)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Recupera as coordenadas do local atual
        if self.uberACaminho {
            self.exibirMotoristaAndPassageiro()
        } else {
            if let coordenadas = manager.location?.coordinate {
                self.localUser = coordenadas
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
    
    @IBAction func chamarUber(_ sender: Any) {
        /*
         // These rules allow only logged-in people to read and write to the database
         {
         "rules": {
         ".read": "auth != null",
         ".write": "auth != null"
         }
         }
         */
        // Iniciando a referencia do banco de dados
        let database = Database.database().reference()
        let requisicoes = database.child("requisicoes")
        
        // Iniciando a referencia ao Auth
        let auth = Auth.auth()
        
        if let emailUser = auth.currentUser?.email {
            
            if self.uberChamado {   // Uber chamado
                // Removendo a requisição
                requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: emailUser).observeSingleEvent(of: DataEventType.childAdded) { (snapshot) in
                    snapshot.ref.removeValue()
                }
                self.alternaBtnChamarUber(title: "Chamar Uber", redM: 0, greenM: 0, blueM: 0)
                
            } else {                // Uber não foi chamado ainda
                
                // Recuperando nome do usuário
                let usuarios = database.child("usuarios").child(auth.currentUser!.uid)
                usuarios.observeSingleEvent(of: .value) { (snapshot) in
                    
                    if let dados = snapshot.value as? NSDictionary {
                        
                        let nomeUser = dados["nome"] as? String
                        
                        let dadosUser = [
                            "email": emailUser,
                            "nome": nomeUser,
                            "latitude": self.localUser.latitude,
                            "longitude": self.localUser.longitude
                            ] as [String: Any]
                        
                        // Salvando a requisição
                        requisicoes.childByAutoId().setValue(dadosUser)
                        
                        self.alternaBtnChamarUber(title: "Cancelar Uber", redM: 0.831, greenM: 0.237, blueM: 0.146)
                    }
                }
            }
        }
    }
    
    
    
    func alternaBtnChamarUber(title: String, redM: CGFloat, greenM: CGFloat, blueM: CGFloat) {
        self.btnChamarUber.setTitle(title, for: .normal)
        self.btnChamarUber.backgroundColor = UIColor(displayP3Red: redM, green: greenM, blue: blueM, alpha: 1)
        self.uberChamado = !self.uberChamado
    }
    
}
