//
//  ConfirmRequisicaoViewController.swift
//  Uber
//
//  Created by Tairone Dias on 25/05/19.
//  Copyright © 2019 DiasDevelopers. All rights reserved.

/* Lista de localização para ser colocado como teste no Debug -> Locations -> Custom Locations...
 Arena Fonte Nova:
 -12,981093
 -38,504585
 
 Perto da Baixa do Sapateiro:
 -12,976028
 -38,508694
 
 Baixa do Sapateiro:
 -12,975680
 -38,509008
 */

import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth

class ConfirmRequisicaoViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var btnConfirmRequisicao: UIButton!
    
    var gerenciadorLocalizacao = CLLocationManager()
    
    var nomePassageiro = ""
    var emailPassageiro = ""
    var localPassageiro = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    var localDestino = CLLocationCoordinate2D()
    
    // Configurando propriedade do Firebase
    let requisicoesDB = Database.database().reference().child("requisicoes")
    let auth = Auth.auth()
    
    var status: StatusCorrida = .EmRequisicao
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configurando o gerenciador de localizacao
        gerenciadorLocalizacao.delegate = self
        gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest
        gerenciadorLocalizacao.requestWhenInUseAuthorization()
        gerenciadorLocalizacao.startUpdatingLocation()
        // A instrução abaixo, permite capturar a geolocalizao em background. Para isso acontecer, em Info.plist deve-se adicionar "Required background modes" e como Item 0 o "App registers for location updates"
        gerenciadorLocalizacao.allowsBackgroundLocationUpdates = true

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
        
        let consultaRequisicao = self.requisicoesDB.queryOrdered(byChild: "status")
        consultaRequisicao.observe(.childChanged) { (snapshot) in
            if let dados = snapshot.value as? [String: Any] {
                if let statusR = dados["status"] as? String {
                    //print("if statusR viewDidLoad")
                    self.recarregaTelaStatus(statusCorrida: statusR, dados: dados)
                }
            }
        }
        
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        //print("viewDidAppear")
        let consultaRequisicao = self.requisicoesDB.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        consultaRequisicao.observeSingleEvent(of: .childAdded) { (snapshot) in
            if let dados = snapshot.value as? [String: Any] {
                if let statusR = dados["status"] as? String {
                    self.recarregaTelaStatus(statusCorrida: statusR, dados: dados)
                }
            }
        }
    }
    
    
    func recarregaTelaStatus(statusCorrida: String, dados: [String: Any]) {
        switch statusCorrida {
            
        case StatusCorrida.PegarPassageiro.rawValue:
            print("StatusCorrida: \(statusCorrida)")
            self.pegarPassageiro()
            self.exibeMotoristaPassageiro(localPartida: self.localMotorista, localDestino: self.localPassageiro, titlePartida: "Meu local", titleDestino: "Passageiro")
            break
            
        case StatusCorrida.IniciarViagem.rawValue:
            print("StatusCorrida: \(statusCorrida)")
            self.iniciarViagem()
            // Metodo abaixo descenessário pois já está sendo chamando em atualizarLocalMotorista(). Toda vez que o app starta primeiro vai pro atualizarLocalMotorista por conta do didUpdateLocations e depois vem pro viewDidAppear, mas é bom realizar testes!
            self.exibeMotoristaPassageiro(localPartida: self.localMotorista, localDestino: self.localPassageiro, titlePartida: "Meu local", titleDestino: "Passageiro")
            break
            
        case StatusCorrida.EmViagem.rawValue:
            print("StatusCorrida: \(statusCorrida)")
            // Alterando o status global
            self.status = .EmViagem
            // Atualizando o button na tela
            self.alternaButton(title: "Finalizar Viagem", enabled: true, redM: 1, greenM: 0.149, blueM: 0)
            break
            
        case StatusCorrida.ViagemFinalizada.rawValue:
            // Alterando o status global
            self.status = .ViagemFinalizada
            
            if let latDestino = dados["destinoLatitude"] as? Double {
                if let lonDestino = dados["destinoLongitude"] as? Double {
                    self.exibeMotoristaPassageiro(localPartida: self.localMotorista, localDestino: CLLocationCoordinate2D(latitude: latDestino, longitude: lonDestino), titlePartida: "Seu local", titleDestino: "Destino")
                }
            }
            
            if let precoViagem = dados["precoViagem"] as? Double {
                // Atualizando button na tela, mas antes formataremos o precoViagem para o padrão pt_BR
                let nf = NumberFormatter()
                nf.numberStyle = .decimal
                nf.maximumFractionDigits = 2
                nf.locale = Locale(identifier: "pt_BR")
                let precoFormatado = nf.string(from: NSNumber(value: precoViagem))
                if let precoFinal = precoFormatado {
                    self.alternaButton(title: "Viagem Finalizada - R$ \(precoFinal)", enabled: false, redM: 0.502, greenM: 0.502, blueM: 0.502)
                }
            }
            
            break
            
        default:
            print("StatusCorrida (default): \(statusCorrida)")
            self.status = .EmRequisicao
        }
    }
    
    
    @IBAction func aceitarCorrida(_ sender: Any) {
        
        if self.status == StatusCorrida.EmRequisicao {
            
            if let emailMotorista = self.auth.currentUser?.email {
                
                self.requisicoesDB.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro).observeSingleEvent(of: .childAdded) { (snapshot) in
                    
                    let dadosMotor = [
                        "motoristaEmail": emailMotorista,
                        "motoristaLatitude": self.localMotorista.latitude,
                        "motoristaLongitude": self.localMotorista.longitude,
                        "status": StatusCorrida.PegarPassageiro.rawValue
                        ] as [String: Any]
                    
                    // O snapshot.ref é o acesso direto no Firebase, por isso, para adicionar novos dados colocamos apenas o updateChildValues
                    snapshot.ref.updateChildValues(dadosMotor)
                    self.pegarPassageiro()
                }
            }
            
            
            // Exibir caminho para o passageiro no mapa nativo do iOS
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
            
        } // end if StatusCorrida.EmRequisicao
        else if self.status == StatusCorrida.IniciarViagem {
            self.emViagemDestino()
        } // end if StatusCorrida.IniciarViagem
        else if self.status == StatusCorrida.EmViagem {
            self.finalizarViagem()
        }  // end if StatusCorrida.EmViagem
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordenadas = manager.location?.coordinate {
            print("Conseguiu recuperar coordenadas")
            print(coordenadas)
            self.localMotorista = coordenadas
            self.atualizarLocalMotorista()
        }
    }
    
    
    func atualizarLocalMotorista() {
        // Atualizar a localização do motorista no Firebase
        if self.emailPassageiro == "" {
            print("E-mail do passageiro vazio")
            return
        }
        
        let consultaRequisicao = self.requisicoesDB.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        consultaRequisicao.observeSingleEvent(of: .childAdded) { (snapshot) in
            
            if let dados = snapshot.value as? [String: Any] {
                if let statusR = dados["status"] as? String {
                    
                    var pointB = self.localPassageiro
                    var titlePB = "Passageiro"
                    
                    // Status Pegar Passageiro
                    if statusR == StatusCorrida.PegarPassageiro.rawValue {
                        
                        let distanciaKM = self.calculaDistancia(latitudePointA: self.localMotorista.latitude, longitudePointA: self.localMotorista.longitude, latitudePointB: self.localPassageiro.latitude, longitudePointB: self.localPassageiro.longitude)
                        print("Status: \(statusR)")
                        print("Distancia = \(distanciaKM) km")
                        if distanciaKM <= 0.2 {
                            self.iniciarViagem()
                            self.updateStatusFirebase(newStatus: self.status.rawValue)
                            //self.recarregaTelaStatus(statusCorrida: self.status.rawValue, dados: dados)
                        }
                        
                    }
                    else if statusR == StatusCorrida.IniciarViagem.rawValue {
                        
                        let distanciaKM = self.calculaDistancia(latitudePointA: self.localMotorista.latitude, longitudePointA: self.localMotorista.longitude, latitudePointB: self.localPassageiro.latitude, longitudePointB: self.localPassageiro.longitude)
                        print("Status: \(statusR)")
                        print("Distancia = \(distanciaKM) km")
                        if distanciaKM > 0.2 {
                            self.pegarPassageiro()
                            self.updateStatusFirebase(newStatus: self.status.rawValue)
                        }
                        
                    }
                    else if statusR == StatusCorrida.EmViagem.rawValue {
                        
                        print("Status: \(statusR)")
                        if let latDestino = dados["destinoLatitude"] as? Double {
                            if let lonDestino = dados["destinoLongitude"] as? Double {
                                self.localDestino = CLLocationCoordinate2D(latitude: latDestino, longitude: lonDestino)
                                pointB = self.localDestino
                                titlePB = "Destino Passageiro"
                            }
                        }
                        
                        
                    }
                    
                    
                    self.exibeMotoristaPassageiro(localPartida: self.localMotorista, localDestino: pointB, titlePartida: "Seu local", titleDestino: titlePB)
                    
                    let dadosMotorista = [
                        "motoristaLatitude": self.localMotorista.latitude,
                        "motoristaLongitude": self.localMotorista.longitude
                        //"status": self.status.rawValue
                        ] as [String: Any]
                    
                    // Atualizando no Firebase
                    snapshot.ref.updateChildValues(dadosMotorista)
                    
                }
                else {
                    print("Ainda não tem status no Firebase")
                    
                    if let latDestino = dados["destinoLatitude"] as? Double {
                        if let lonDestino = dados["destinoLongitude"] as? Double {
                            self.localDestino = CLLocationCoordinate2D(latitude: latDestino, longitude: lonDestino)
                            
                            // Exibe alerta de viagem para o motorista
                            self.alertaViagemMotorista()
                        }
                    }
                } // end Ainda não tem status gravados no Firebase
                
            }
        } // end observeSingleEvent
    }
    
    
    func emViagemDestino() {
        // Alterando o status global
        self.status = .EmViagem
        // Atualizando o status no Firebase
        self.updateStatusFirebase(newStatus: StatusCorrida.EmViagem.rawValue)
        // Atualizando o button na tela
        self.alternaButton(title: "A caminho do destino do passageiro", enabled: false, redM: 0.502, greenM: 0.502, blueM: 0.502)
        
        /*
        // Exibir caminho para o passageiro no mapa nativo do iOS
        let locationDestinoCLL = CLLocation(latitude: self.localDestino.latitude, longitude: self.localDestino.longitude)
        
        CLGeocoder().reverseGeocodeLocation(locationDestinoCLL, completionHandler: { (local, error) in
            if error != nil {
                print("Erro no CLGeocoder em ConfirmRequisicaoViewController")
                return
            }
            
            if let dadosLocal = local?.first {
                let placeMark = MKPlacemark(placemark: dadosLocal)
                let mapaItem = MKMapItem(placemark: placeMark)
                mapaItem.name = "Destino Passageiro"
                
                let opcoes = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                mapaItem.openInMaps(launchOptions: opcoes)
            }
        })
        */
    }
    
    
    func finalizarViagem() {
        // Alterar o status do passageiro
        self.status = .ViagemFinalizada
        
        let precoRef = Database.database().reference().child("preco")
        precoRef.observeSingleEvent(of: .value) { (snapshot) in
            
            if snapshot.value == nil {
                print("Erro ao recuperar preco")
                return
            }
            
            if let dadosPreco = snapshot.value as? [String: Double] {
                if let precoKM = dadosPreco["km"] {
                    print("Preco: \(precoKM) reais por km")
                    
                    
                    // Calculando quilometragem
                    let consultaReq = self.requisicoesDB.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
                    consultaReq.observeSingleEvent(of: .childAdded) { (snapshot) in
                        if let dados = snapshot.value as? [String: Any] {
                            if let latPartida = dados["latitude"] as? Double {
                                if let lonPartida = dados["longitude"] as? Double {
                                    if let latDestino = dados["destinoLatitude"] as? Double {
                                        if let lonDestino = dados["destinoLongitude"] as? Double {
                                            
                                            let distanciaKM = self.calculaDistancia(latitudePointA: latPartida, longitudePointA: lonPartida, latitudePointB: latDestino, longitudePointB: lonDestino)
                                            
                                            let precoViagem = distanciaKM * precoKM
                                            
                                            let updateDados = [
                                                "precoViagem": precoViagem,
                                                "distanciaPercorrida": distanciaKM,
                                                "status": self.status.rawValue
                                                ] as [String: Any]
                                            
                                            snapshot.ref.updateChildValues(updateDados)
                                            
                                            // Atualizando button na tela, mas antes formataremos o precoViagem para o padrão pt_BR
                                            let nf = NumberFormatter()
                                            nf.numberStyle = .decimal
                                            nf.maximumFractionDigits = 2
                                            nf.locale = Locale(identifier: "pt_BR")
                                            let precoFormatado = nf.string(from: NSNumber(value: precoViagem))
                                            if let precoFinal = precoFormatado {
                                                self.alternaButton(title: "Viagem Finalizada! R$ \(precoFinal)", enabled: false, redM: 0.502, greenM: 0.502, blueM: 0.502)
                                            }
                                            
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    
                }
            }
        }
        
        
        
    }
    
    
    func pegarPassageiro() {
        // Alterar o status do passageiro
        self.status = .PegarPassageiro
        
        // Alterar o button
        self.alternaButton(title: "A caminho do passageiro", enabled: false, redM: 0.502, greenM: 0.502, blueM: 0.502)
    }
    
    
    func iniciarViagem() {
        // Alterar o status do passageiro
        self.status = .IniciarViagem
        
        // Alterar o button
        self.alternaButton(title: "Iniciar viagem", enabled: true, redM: 0.067, greenM: 0.576, blueM: 0.604)
    }
    
    
    func updateStatusFirebase(newStatus: String) {
        let consultaRequisicao = self.requisicoesDB.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        consultaRequisicao.observeSingleEvent(of: .childAdded) { (snapshot) in
            let status = [
                "status": newStatus
            ]
            // Atualizando no Firebase
            snapshot.ref.updateChildValues(status)
        }
    }
    
    
    func calculaDistancia(latitudePointA: Double, longitudePointA: Double, latitudePointB: Double, longitudePointB: Double) -> Double {
        
        let pointA = CLLocation(latitude: latitudePointA, longitude: longitudePointA)
        let pointB = CLLocation(latitude: latitudePointB, longitude: longitudePointB)
        
        let distancia = pointA.distance(from: pointB)
        let distanciaKM = distancia / 1000
        //let distanciaM = round(distancia / 100)
        //var distanciaFinal = distanciaKM
        
        return distanciaKM
    }
    
    
    func exibeMotoristaPassageiro(localPartida: CLLocationCoordinate2D, localDestino: CLLocationCoordinate2D, titlePartida: String, titleDestino: String) {
        
        // Fazendo o calculo para setar a visualizacao de ambos (motorista e passageiro) na tela. O  * 300000 é para a visualizacao está adequada conforme a diferença
        let latDiff = abs(localPartida.latitude - localDestino.latitude) * 300000
        let longDiff = abs(localPartida.longitude - localDestino.longitude)  * 300000
        
        // Criando a regiao para setar no mapa
        let regiao = MKCoordinateRegion.init(center: localPartida, latitudinalMeters: latDiff, longitudinalMeters: longDiff)
        self.mapa.setRegion(regiao, animated: true)
        
        // Remove anotacoes antes de criar
        self.mapa.removeAnnotations(self.mapa.annotations)
        
        // Anotação Partida
        let annotPartida = MKPointAnnotation()
        annotPartida.coordinate = localPartida
        annotPartida.title = titlePartida
        self.mapa.addAnnotation(annotPartida)
        
        // Anotação Destino
        let annotDestino = MKPointAnnotation()
        annotDestino.coordinate = localDestino
        annotDestino.title = titleDestino
        self.mapa.addAnnotation(annotDestino)
        
    }
    
    
    func alertaViagemMotorista() {
        //        let consultaRequisicao = self.requisicoesDB.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        //        consultaRequisicao.observeSingleEvent(of: .childAdded) { (snapshot) in
        //
        //            if let dados = snapshot.value as? [String: Any] {
        //                if let latDestino = dados["destinoLatitude"] as? Double {
        //                    if let lonDestino = dados["destinoLongitude"] as? Double {
        
        let locationCLL = CLLocation(latitude: self.localDestino.latitude, longitude: self.localDestino.longitude)
        CLGeocoder().reverseGeocodeLocation(locationCLL, completionHandler: { (placemark, error) in
            if error != nil {
                print("Erro in alertaViagemMotorista")
                return
            }
            
            if let dataPlacemark = placemark?.first {
                let endereco = self.recuperandoEndereco(dadosLocal: dataPlacemark)
                
                let alerta = UIAlertController(title: "Endereço da corrida", message: "O passageiro \(self.nomePassageiro) deseja ir para: "+endereco.enderecoCompleto(), preferredStyle: .alert)
                let actionOK = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alerta.addAction(actionOK)
                
                self.present(alerta, animated: true, completion: nil)
            }
            
        })
        //                    }
        //                }
        //            }
        //
        //
        //
        //        } // end clousere
    }
    
    
    func alternaButton(title: String, enabled: Bool, redM: CGFloat, greenM: CGFloat, blueM: CGFloat) {
        self.btnConfirmRequisicao.setTitle(title, for: .normal)
        self.btnConfirmRequisicao.isEnabled = enabled
        self.btnConfirmRequisicao.backgroundColor = UIColor(displayP3Red: redM, green: greenM, blue: blueM, alpha: 1)
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
    
    

}
