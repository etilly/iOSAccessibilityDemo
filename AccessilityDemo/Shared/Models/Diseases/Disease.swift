//
//  Disease.swift
//  AccessilityDemo
//
//  Created by Erwan BOUET on 17/03/2022.
//

import Foundation
import CoreData

/// Disease is the model class to inreacts with within the views. Object saved in CoreData.
class Disease: NSManagedObject, Identifiable {
    @NSManaged var date: Date
    @NSManaged var definition: String
    @NSManaged var code: Int
    @NSManaged var name: String
    
    var id: String {
        get {
            String(code)
        }
    }
}

/// DiseaseResponse is the response recevied from the webservice.
struct DiseaseResponse: Decodable {
    let date: Date
    let definition: String
    let code: Int
    let name: String
    
    
    private enum CodingKeys: String, CodingKey {
        case date = "Date"
        case definition = "Definition"
        case code = "ORPHAcode"
        case name = "Preferred term"
    }
    
    var dictionnaryValue: [String: Any] {
        get {
            ["date": date,
             "definition": definition,
             "code": code,
             "name": name
            ]
        }
    }
}
