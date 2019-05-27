//
//  ViewController.swift
//  Uber
//
//  Created by Tairone Dias on 24/05/19.
//  Copyright © 2019 DiasDevelopers. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let autenticacao = Auth.auth()
        
        self.login(auth: autenticacao)
        //self.logout(auth: autenticacao)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func login(auth: Auth) {
        
        let db = Database.database().reference()
        let usuarios = db.child("usuarios")
        
        auth.addStateDidChangeListener { (autenticacao, usuario) in
            if usuario != nil {
                let refNode = usuarios.child(usuario!.uid)
                refNode.observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    let dados = snapshot.value as? NSDictionary
                    let tipoUser = dados!["tipo"] as! String
                    
                    let segueName = tipoUser == "Passageiro" ? "seguePrincipal" : "segueLoginPrincipalMotor"
                    self.performSegue(withIdentifier: segueName, sender: nil)
                })
                
            }
        }
    }
    
    func logout(auth: Auth) {
        do {
            try auth.signOut()
        } catch {
            print("Erro ao deslogar o usuário!")
        }
    }


}

