//
//  Endereco.swift
//  Uber
//
//  Created by Tairone Dias on 27/05/19.
//  Copyright © 2019 DiasDevelopers. All rights reserved.
//

import Foundation
import MapKit

class Endereco {
    var rua = ""
    var numero = ""
    var bairro = ""
    var cidade = ""
    var estado = ""
    var cep = ""
    var latitude = CLLocationDegrees()
    var longitude = CLLocationDegrees()
    
    func enderecoCompleto() -> String {
        let endereco = "\(self.rua), nº \(self.numero), \(self.bairro), \(self.cidade) - \(self.estado), \(self.cep)"
        return endereco
    }
}
