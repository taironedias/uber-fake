//
//  EntrarViewController.swift
//  Uber
//
//  Created by Tairone Dias on 24/05/19.
//  Copyright © 2019 DiasDevelopers. All rights reserved.
//

import UIKit
import FirebaseAuth

class EntrarViewController: UIViewController {

    @IBOutlet weak var campoEmail: UITextField!
    @IBOutlet weak var campoSenha: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func entrar(_ sender: Any) {
        let validacao = self.validarCampos()
        if validacao != "" {
            print(validacao)
            return
        }
        
        let auth = Auth.auth()
        
        if let email = self.campoEmail.text {
            if let senha = self.campoSenha.text {
                auth.signIn(withEmail: email, password: senha) { (usuario, error) in
                    if error != nil {
                        print("Erro ao logar no sistema!")
                        return
                    }
                    
                    if usuario != nil {
                        print("Usuário logado com suceoss! E-mail: "+String(describing: usuario?.user.email))
                        self.performSegue(withIdentifier: "segueLogin", sender: nil)
                    }
                    
                }
            }
        }
        
    }
    
    func validarCampos() -> String {
        if (self.campoEmail.text?.isEmpty)! {
            return "O campo e-mail não foi preenchido!"
        } else if !(self.campoEmail.text!.contains("@")) {
            return "Não é um e-mail válido!"
        } else if (self.campoSenha.text?.isEmpty)! {
            return "O campo senha não foi preenchido!"
        }
        return ""
    }

}
