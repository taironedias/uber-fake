//
//  CadastroViewController.swift
//  Uber
//
//  Created by Tairone Dias on 24/05/19.
//  Copyright © 2019 DiasDevelopers. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class CadastroViewController: UIViewController {
    
    @IBOutlet weak var campoEmail: UITextField!
    @IBOutlet weak var campoNomeCompleto: UITextField!
    @IBOutlet weak var campoSenha: UITextField!
    @IBOutlet weak var campoConfirmarSenha: UITextField!
    @IBOutlet weak var switchTipoUsuario: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {    self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func cadastrar(_ sender: Any) {
        let validacaoCampos = self.validarCampos()
        let validacaoSenhas = self.validarSenhas()
        
        if validacaoCampos != "" {
            print(validacaoCampos)
            return
        }
        
        if !validacaoSenhas {
            print("As senhas não são iguais!")
            self.campoSenha.text = ""
            self.campoConfirmarSenha.text = ""
            return
        }
        
        // Cadastrar usuario no Firebase
        let auth = Auth.auth()
        if let email = self.campoEmail.text {
            if let nome = self.campoNomeCompleto.text {
                if let senha = self.campoSenha.text {
                    auth.createUser(withEmail: email, password: senha) { (usuario, error) in
                        if error != nil {
                            print("Erro ao criar a conta do usuário!")
                            return
                        }
                        
                        /*
                         Valida se o usuário está logado.
                         Caso o usuário esteja logado, será redirecionado automaticamente de acordo
                         com o tipo de usuário com o evento criado na ViewController
                         */
                        if usuario == nil {
                            print("Erro ao autenticar usuário, em cadastro")
                            return
                        }
                        
                        print("Sucesso ao cadastrar o usuário e usuário logado!")
                        
                        // Recupera o valor do switch e seta a variávei tipoUser
                        let tipoUser = self.switchTipoUsuario.isOn ? "Passageiro" : "Motorista"
                        
                        // Configura o database
                        let db = Database.database().reference()
                        let usuarios = db.child("usuarios")
                        
                        if let uidUser = auth.currentUser?.uid {
                            
                            let dadosUser = [
                                "email": usuario!.user.email,
                                "nome": nome,
                                "tipo": tipoUser
                            ]
                            
                            usuarios.child(uidUser).setValue(dadosUser)
                        }
                        
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
        } else if (self.campoNomeCompleto.text?.isEmpty)! {
            return "O campo nome completo não foi preenchido!"
        } else if (self.campoSenha.text?.isEmpty)! {
            return "O campo senha não foi preenchido!"
        } else if (self.campoConfirmarSenha.text?.isEmpty)! {
            return "O campo confirmar senha não foi preenchido!"
        }
        return ""
    }
    
    func validarSenhas() -> Bool {
        if self.campoSenha.text == self.campoConfirmarSenha.text {
            return true
        }
        return false
    }
    
}
