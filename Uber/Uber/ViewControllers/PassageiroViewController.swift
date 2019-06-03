//
//  PassageiroViewController.swift
//  Uber
//
//  Created by Tairone Dias on 24/05/19.
//  Copyright © 2019 DiasDevelopers. All rights reserved.

/* Lista de localização para ser colocado como teste no Debug -> Locations -> Custom Locations...
 Arena Fonte Nova:
 -12,981093
 -38,504585
 
 Campo da Pólvora:
 -12,979211
 -38,507500
 
 Baixa do Sapateiro:
 -12,976028
 -38,508694
 */


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
    var status: StatusCorrida = .EmRequisicao
    
    
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
                
                if let dados = snapshot.value as? [String: Any] {
                    if let statusR = dados["status"] as? String {
                        self.loadingTelaStatus(statusCorrida: statusR, dados: dados)
                    } else {
                        print("Não existe motoristaLatitude e motoristaLongitude no Firebase!")
                        self.setAlternaButton(title: "Cancelar Uber", enabled: true, redM: 0.831, greenM: 0.237, blueM: 0.146, opacidade: 1)
                    }
                }
                
            }
            
            
            consultaRequisicoes.observe(.childChanged) { (snapshot) in
                if let dados = snapshot.value as? [String: Any] {
                    if snapshot.value == nil {
                        print("snapshot está vazio!")
                        return
                    }
                    
                    if let statusR = dados["status"] as? String {
                        print("viewDidLoad -> if statusR")
                        self.loadingTelaStatus(statusCorrida: statusR, dados: dados)
                    }
                    
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
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        let requisicoes = self.database.child("requisicoes")
        if let emailUser = self.auth.currentUser?.email {
            let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: emailUser)
            
            // Adicioando ouvinte para quando o usuario chamar o Uber
            consultaRequisicoes.observe(.childAdded) { (snapshot) in
                if snapshot.value == nil {
                    print("snapshot está vazio!")
                    return
                }
                
                if let dados = snapshot.value as? [String: Any] {
                    if let statusR = dados["status"] as? String {
                        self.loadingTelaStatus(statusCorrida: statusR, dados: dados)
                    } else {
                        print("Não existe motoristaLatitude e motoristaLongitude no Firebase!")
                        self.setAlternaButton(title: "Cancelar Uber", enabled: true, redM: 0.831, greenM: 0.237, blueM: 0.146, opacidade: 1)
                    }
                }
                
            }
            
        }
    }
    
    
    
    func loadingTelaStatus(statusCorrida: String, dados: [String: Any]) {
        
        if let motoristaLatitude = dados["motoristaLatitude"] as? CLLocationDegrees {
            if let motoristaLongitude = dados["motoristaLongitude"] as? CLLocationDegrees {
                self.localMotorista = CLLocationCoordinate2D(latitude: motoristaLatitude, longitude: motoristaLongitude)
            }
        }
        
        switch statusCorrida {
            
        case StatusCorrida.PegarPassageiro.rawValue:
            print("StatusCorrida: \(statusCorrida)")
            self.status = .PegarPassageiro
            self.exibePointAPointB(localA: self.localUser, localB: self.localMotorista, titleA: "Seu local", titleB: "Motorista")
            self.exibeChangedButton()
            break
            
        case StatusCorrida.IniciarViagem.rawValue:
            print("StatusCorrida: \(statusCorrida)")
            self.status = .IniciarViagem
            self.exibePointAPointB(localA: self.localUser, localB: self.localMotorista, titleA: "Seu local", titleB: "Motorista")
            self.exibeChangedButton()
            break
            
        case StatusCorrida.EmViagem.rawValue:
            print("StatusCorrida: \(statusCorrida)")
            self.status = .EmViagem
            
            if let latDestino = dados["destinoLatitude"] as? Double {
                if let lonDestino = dados["destinoLongitude"] as? Double {
                    let location2D = CLLocationCoordinate2D(latitude: latDestino, longitude: lonDestino)
                    self.exibePointAPointB(localA: self.localMotorista, localB: location2D, titleA: "Partida", titleB: "Destino")
                }
            }
            
            self.setAlternaButton(title: "Em Viagem", enabled: false, redM: 1, greenM: 0.149, blueM: 0)
            break
            
        case StatusCorrida.ViagemFinalizada.rawValue:
            print("StatusCorrida: \(statusCorrida)")
            self.status = .ViagemFinalizada
            
            if let latDestino = dados["destinoLatitude"] as? Double {
                if let lonDestino = dados["destinoLongitude"] as? Double {
                    let location2D = CLLocationCoordinate2D(latitude: latDestino, longitude: lonDestino)
                    self.exibePointAPointB(localA: self.localMotorista, localB: location2D, titleA: "Partida", titleB: "Destino")
                }
            }
            
            self.finalizadaViagem()
            break
        default:
            print("StatusCorrida (default): \(statusCorrida)")
            self.status = .EmRequisicao
        }
    }
    
    
    
    func setAlternaButton(title: String, enabled: Bool, redM: CGFloat, greenM: CGFloat, blueM: CGFloat, opacidade: CGFloat? = 0.6) {
        self.btnChamarUber.setTitle(title, for: .normal)
        self.btnChamarUber.isEnabled = enabled
        self.btnChamarUber.backgroundColor = UIColor(displayP3Red: redM, green: greenM, blue: blueM, alpha: opacidade!)
    }
    
    
    
    func exibePointAPointB(localA: CLLocationCoordinate2D, localB: CLLocationCoordinate2D, titleA: String, titleB: String) {
        
        // Fazendo o calculo para setar a visualizacao de ambos (motorista e passageiro) na tela. O  * 300000 é para a visualizacao está adequada conforme a diferença
        let latDiff = abs(localA.latitude - localB.latitude) * 300000
        let longDiff = abs(localA.longitude - localB.longitude)  * 300000
        
        // Criando a regiao para setar no mapa
        let regiao = MKCoordinateRegion.init(center: localA, latitudinalMeters: latDiff, longitudinalMeters: longDiff)
        self.mapa.setRegion(regiao, animated: true)
        
        // Remove anotacoes antes de criar
        self.mapa.removeAnnotations(self.mapa.annotations)
        
        // Anotação Partida
        let annotPartida = MKPointAnnotation()
        annotPartida.coordinate = localA
        annotPartida.title = titleA
        self.mapa.addAnnotation(annotPartida)
        
        // Anotação Destino
        let annotDestino = MKPointAnnotation()
        annotDestino.coordinate = localB
        annotDestino.title = titleB
        self.mapa.addAnnotation(annotDestino)
        
    }
    
    
    
    func calculaDistancia(latitudePointA: Double, longitudePointA: Double, latitudePointB: Double, longitudePointB: Double) -> Double {
        
        let pointA = CLLocation(latitude: latitudePointA, longitude: longitudePointA)
        let pointB = CLLocation(latitude: latitudePointB, longitude: longitudePointB)
        
        let distancia = pointA.distance(from: pointB)
        
        return distancia
    }
    
    
    
    func exibeChangedButton() {
        let distancia = self.calculaDistancia(latitudePointA: self.localUser.latitude, longitudePointA: self.localUser.longitude, latitudePointB: self.localMotorista.latitude, longitudePointB: self.localMotorista.longitude)
        print("Distancia: \(distancia)")
        let distanciaKM = round(distancia / 1000)
        var distanciaFinal = distanciaKM
        var mensagem = "Motorista está a \(distanciaFinal) Km"
        if distanciaKM == 0.0 {
            distanciaFinal = round(distancia)
            mensagem = "Motorista está a \(distanciaFinal) metros"
        }
        self.setAlternaButton(title: mensagem, enabled: false, redM: 0.502, greenM: 0.502, blueM: 0.502)
    }
    
    
    
    func finalizadaViagem() {
        let requisicoes = self.database.child("requisicoes")
        if let emailUser = self.auth.currentUser?.email {
            let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: emailUser)
            
            // Adicioando ouvinte para quando o usuario chamar o Uber
            consultaRequisicoes.observeSingleEvent(of: .childAdded, with: { (snapshot) in
                if snapshot.value == nil {
                    print("snapshot está vazio!")
                    return
                }
                
                if let dados = snapshot.value as? [String: Any] {
                    if let precoR = dados["precoViagem"] as? Double {
                    
                        // Atualizando button na tela, mas antes formataremos o precoViagem para o padrão pt_BR
                        let nf = NumberFormatter()
                        nf.numberStyle = .decimal
                        nf.maximumFractionDigits = 2
                        nf.locale = Locale(identifier: "pt_BR")
                        let precoFormatado = nf.string(from: NSNumber(value: precoR))
                        if let precoFinal = precoFormatado {
                            self.setAlternaButton(title: "Viagem Finalizada! Pagar: R$ \(precoFinal)", enabled: false, redM: 0.502, greenM: 0.502, blueM: 0.502, opacidade: 1)
                        }
                    
                    }
                }
                
            })
            
        }
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Recupera as coordenadas do local atual
        if let coordenadas = manager.location?.coordinate {
            self.localUser = coordenadas
            // Atualizando local com base nos status
            self.atualizarLocation()
        }
    }
    
    
    
    func atualizarLocation() {
        if let emailUser = self.auth.currentUser?.email {
            let requisicoesDB = self.database.child("requisicoes")
            let consultaRequisicao = requisicoesDB.queryOrdered(byChild: "email").queryEqual(toValue: emailUser)
            consultaRequisicao.observeSingleEvent(of: .childAdded) { (snapshot) in
                if let dados = snapshot.value as? [String: Any] {
                    if let statusR = dados["status"] as? String {
                        self.loadingTelaStatus(statusCorrida: statusR, dados: dados)
                    } // end if statusR
                } // end if dados
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
            print("status uber chamado")
            print(self.uberChamado)
            print("status uber a caminho")
            print(self.uberACaminho)
            
            /* Essa estrutura de if, é para o caso onde o passageiro chamou e uber e no mesmo instante quer desistir da viagem */
            if self.uberChamado {   // Uber chamado
                // Removendo a requisição
                requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: emailUser).observeSingleEvent(of: DataEventType.childAdded) { (snapshot) in
                    snapshot.ref.removeValue()
                }
                
                self.alternaBtnChamarUber(title: "Chamar Uber", condition: false, redM: 0, greenM: 0, blueM: 0)
                
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
                                        
                                        self.alternaBtnChamarUber(title: "Cancelar Uber", condition: true, redM: 0.831, greenM: 0.237, blueM: 0.146)
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
    
    
    
    func alternaBtnChamarUber(title: String, condition: Bool, redM: CGFloat, greenM: CGFloat, blueM: CGFloat) {
        self.btnChamarUber.setTitle(title, for: .normal)
        self.uberChamado = condition
        self.btnChamarUber.backgroundColor = UIColor(displayP3Red: redM, green: greenM, blue: blueM, alpha: 1)
    }
    
    
    
}
