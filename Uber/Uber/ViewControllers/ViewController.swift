//
//  ViewController.swift
//  Uber
//
//  Created by Tairone Dias on 24/05/19.
//  Copyright © 2019 DiasDevelopers. All rights reserved.
//

import UIKit
import FirebaseAuth

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
        auth.addStateDidChangeListener { (autenticacao, usuario) in
            if usuario != nil {
                self.performSegue(withIdentifier: "seguePrincipal", sender: nil)
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

