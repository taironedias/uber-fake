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
    
    
    // Referencias para setar o local de destino
    @IBOutlet weak var areaEndereco: UIView!
    @IBOutlet weak var marcadorLocalPassageiro: UIView!
    @IBOutlet weak var marcadorLocalDestino: UIView!
    @IBOutlet weak var campoLocalDestino: UITextField!
    
    // Constantes de acesso ao Banco de Dados
    let database = Database.database().reference()
    let auth = Auth.auth()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gerenciadorLocalizacao.delegate = self
        gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest
        gerenciadorLocalizacao.requestWhenInUseAuthorization()
        gerenciadorLocalizacao.startUpdatingLocation()
        
        // Verifica se já tem uma requisicao de Uber
        let requisicoes = self.database.child("requisicoes")
        
        if let emailUser = self.auth.currentUser?.email {
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
        
        // Configurando o arredondamento dos marcadores
        self.marcadorLocalPassageiro.layer.cornerRadius = 7.5
        self.marcadorLocalPassageiro.clipsToBounds = true
        
        self.marcadorLocalDestino.layer.cornerRadius = 7.5
        self.marcadorLocalDestino.clipsToBounds = true
        
        self.areaEndereco.layer.cornerRadius = 10
        self.areaEndereco.clipsToBounds = true
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
        // Verifica se o Uber está a caminho. Como é um método automatico quando o local é atualizado, foi necessário fazer essa verificação aqui também
        if self.uberACaminho {
            self.exibirMotoristaAndPassageiro()
        } else {
            // Recupera as coordenadas do local atual
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
        do {
            try self.auth.signOut()
            dismiss(animated: true, completion: nil)
        } catch {
            print("Não foi possível deslogar o usuário")
        }
    }
    
    
    @IBAction func chamarUber(_ sender: Any) {
        // NO FIREBASE - Realtime database
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
        let requisicoes = self.database.child("requisicoes")
        
        if let emailUser = self.auth.currentUser?.email {
            if self.uberChamado {   // Uber chamado
                // Removendo a requisição
                requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: emailUser).observeSingleEvent(of: DataEventType.childAdded) { (snapshot) in
                    snapshot.ref.removeValue()
                }
                
                self.alternaBtnChamarUber(title: "Chamar Uber", redM: 0, greenM: 0, blueM: 0)
                
            } else {                // Uber não foi chamado ainda
                
                // Recuperando endereco de destino
                if let enderecoDestino = self.campoLocalDestino.text {
                    if enderecoDestino == "" {
                        print("Endereço não digitado!")
                        return
                    }
                    
                    CLGeocoder().geocodeAddressString(enderecoDestino) { (local, error) in
                        if error != nil {
                            print("Erro ao recuperar endereço de destino")
                            return
                        }
                        
                        if let dadosLocal = local?.first {
                            
                            let endereco = self.recuperandoEndereco(dadosLocal: dadosLocal)
                            
                            let alerta = UIAlertController(title: "Confirme seu endereço!", message: endereco.enderecoCompleto(), preferredStyle: .alert)
                            let actionCancelar = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
                            let actionConfirmar = UIAlertAction(title: "Confirmar", style: .default, handler: { (alertAction) in
                                
                                // Recuperando nome do usuário
                                let usuarios = self.database.child("usuarios").child(self.auth.currentUser!.uid)
                                usuarios.observeSingleEvent(of: .value) { (snapshot) in
                                    
                                    if let dados = snapshot.value as? NSDictionary {
                                        
                                        let nomeUser = dados["nome"] as? String
                                        
                                        let dadosUser = [
                                            "email": emailUser,
                                            "nome": nomeUser!,
                                            "latitude": self.localUser.latitude,
                                            "longitude": self.localUser.longitude,
                                            "destinoLatitude": endereco.latitude,
                                            "destinoLongitude": endereco.longitude
                                            ] as [String: Any]
                                        
                                        // Salvando a requisição
                                        requisicoes.childByAutoId().setValue(dadosUser)
                                        
                                        self.alternaBtnChamarUber(title: "Cancelar Uber", redM: 0.831, greenM: 0.237, blueM: 0.146)
                                    }
                                }
                                
                            })
                            
                            alerta.addAction(actionCancelar)
                            alerta.addAction(actionConfirmar)
                            
                            self.present(alerta, animated: true, completion: nil)
                            
                        }
                    } // end CLGeocoder()
                } // fim do else "Uber não foi chamado ainda"
            }
        }
    }
    
    
    func recuperandoEndereco(dadosLocal: CLPlacemark) -> Endereco {
        let endereco = Endereco()
        
        if dadosLocal.thoroughfare != nil {
            endereco.rua = dadosLocal.thoroughfare!
        }
        
        if dadosLocal.subThoroughfare != nil {
            endereco.numero = dadosLocal.subThoroughfare!
        }
        
        if dadosLocal.subLocality != nil {
            endereco.bairro = dadosLocal.subLocality!
        }
        
        if dadosLocal.administrativeArea != nil {
            endereco.estado = dadosLocal.administrativeArea!
        }
        
        if dadosLocal.locality != nil {
            endereco.cidade = dadosLocal.locality!
        }
        
        if dadosLocal.postalCode != nil {
            endereco.cep = dadosLocal.postalCode!
        }
        
        if let lat = dadosLocal.location?.coordinate.latitude {
            endereco.latitude = lat
        }
        
        if let long = dadosLocal.location?.coordinate.longitude {
            endereco.longitude = long
        }
        
        
        return endereco
    }
    
    
    func alternaBtnChamarUber(title: String, redM: CGFloat, greenM: CGFloat, blueM: CGFloat) {
        self.btnChamarUber.setTitle(title, for: .normal)
        self.btnChamarUber.backgroundColor = UIColor(displayP3Red: redM, green: greenM, blue: blueM, alpha: 1)
        self.uberChamado = !self.uberChamado
    }
    
    

    
}
