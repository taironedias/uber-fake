//
//  MotoristaTableViewController.swift
//  Uber
//
//  Created by Tairone Dias on 25/05/19.
//  Copyright © 2019 DiasDevelopers. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import MapKit

class MotoristaTableViewController: UITableViewController, CLLocationManagerDelegate {

    var listaRequisicoes: [DataSnapshot] = []
    var gerenciadorLocalizacao = CLLocationManager()
    var localMotorista = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 
        self.gerenciadorLocalizacao.delegate = self
        gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest
        gerenciadorLocalizacao.requestWhenInUseAuthorization()
        gerenciadorLocalizacao.startUpdatingLocation()
        
        // Configura banco de dados
        let db = Database.database().reference()
        let requisicoes = db.child("requisicoes")
        
        // Recuperando os dados
        requisicoes.observe(.childAdded) { (snapshot) in
            print("Snapshot1: "+String(describing: snapshot))
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
        let autenticar = Auth.auth()
        do {
            try autenticar.signOut()
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
                    
                    cell.textLabel?.text = dados["nome"] as? String
                    cell.detailTextLabel?.text = "\(distanciaKM) km de distância"
                    
                }
            }
        }

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
