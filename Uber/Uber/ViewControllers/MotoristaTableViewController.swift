//
//  MotoristaTableViewController.swift
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
import FirebaseAuth
import FirebaseDatabase
import MapKit

class MotoristaTableViewController: UITableViewController, CLLocationManagerDelegate {

    var listaRequisicoes: [DataSnapshot] = []
    var gerenciadorLocalizacao = CLLocationManager()
    var localMotorista = CLLocationCoordinate2D()
    
    // Configura banco de dados
    let requisicoesDB = Database.database().reference().child("requisicoes")
    let autenticacao = Auth.auth()
    
    // Timer
    var timerControle = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Iniciando o processo de geolocalização
        self.gerenciadorLocalizacao.delegate = self
        gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest
        gerenciadorLocalizacao.requestWhenInUseAuthorization()
        gerenciadorLocalizacao.startUpdatingLocation()
        
        // Recuperando os dados
        requisicoesDB.observe(.childAdded) { (snapshot) in
            // print("Snapshot1: "+String(describing: snapshot))
            self.listaRequisicoes.append(snapshot)
            self.tableView.reloadData()
        }
        
        // Limpar uma requisição
        requisicoesDB.observe(.childRemoved) { (snapshot) in
            var indice = 0
            for requisicao in self.listaRequisicoes {
                if requisicao.key == snapshot.key {
                    self.listaRequisicoes.remove(at: indice)
                }
                indice += 1
            }
            self.tableView.reloadData()
        }
        
        // Atualizando requisicao no tableView
        requisicoesDB.observe(.childChanged) { (snapshot) in
            var indice = 0
            for item in self.listaRequisicoes {
                if item.key == snapshot.key {
                    self.listaRequisicoes.remove(at: indice)
                }
                indice += 1
            }
            self.listaRequisicoes.append(snapshot)
            self.tableView.reloadData()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordenadas = manager.location?.coordinate {
            self.localMotorista = coordenadas
        }
    }

    
    @IBAction func deslogarMotorista(_ sender: Any) {
        do {
            try self.autenticacao.signOut()
            dismiss(animated: true, completion: nil)
        } catch {
            print("Não foi possível deslogar o usuário")
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let snapshot = self.listaRequisicoes[indexPath.row]
        self.performSegue(withIdentifier: "segueAceitarCorrida", sender: snapshot)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueAceitarCorrida" {
            if let confirmarViewController = segue.destination as? ConfirmRequisicaoViewController {
                if let snapshots = sender as? DataSnapshot {
                    if let dados = snapshots.value as? [String: Any] {
                        if let latPassageiro = dados["latitude"] as? Double {
                            if let longPassageiro = dados["longitude"] as? Double {
                                if let nomePassageiro = dados["nome"] as? String {
                                    if let emailPassageiro = dados["email"] as? String {
                                        // Após recuperar todos os dados do passageiro, enviaremos os dados para a próxima ViewController
                                        confirmarViewController.localPassageiro = CLLocationCoordinate2D(latitude: latPassageiro, longitude: longPassageiro)
                                        confirmarViewController.nomePassageiro = nomePassageiro
                                        confirmarViewController.emailPassageiro = emailPassageiro
                                        confirmarViewController.localMotorista = self.localMotorista
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listaRequisicoes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellMotorista", for: indexPath)
        
        let snapshot = self.listaRequisicoes[indexPath.row]
        
        if let dados = snapshot.value as? [String: Any] {
            
            if let latPassageiro = dados["latitude"] as? Double {
                if let longPassageiro = dados["longitude"] as? Double {
                    
                    let motorLocation = CLLocation(latitude: self.localMotorista.latitude, longitude: self.localMotorista.longitude)
                    let passageiroLocation = CLLocation(latitude: latPassageiro, longitude: longPassageiro)
                    
                    let distanciaMetros = motorLocation.distance(from: passageiroLocation)
                    let distanciaKM = round(distanciaMetros / 1000)
                    let mensagem = distanciaKM == 0.0 ? "\(round(distanciaMetros)) metros de distância" : "\(distanciaKM) km de distância"
                    
                    
                    var requisicaoMotorista = ""
                    if let emailMotorista = dados["motoristaEmail"] as? String {
                        if let emailMotoristaLogado = self.autenticacao.currentUser?.email {
                            if emailMotorista == emailMotoristaLogado {
                                requisicaoMotorista = "(ANDAMENTO)"
                                if let status = dados["status"] as? String {
                                    if status == StatusCorrida.ViagemFinalizada.rawValue {
                                        requisicaoMotorista = "(FINALIZADO)"
                                    }

                                }
                            }
                        }
                    }
                    
                    if let nomePassageiro = dados["nome"] as? String {
                        cell.textLabel?.text = "\(nomePassageiro) \(requisicaoMotorista)"
                        cell.detailTextLabel?.text = mensagem
                    }
                    
                }
            }
        }

        return cell
    }

}
