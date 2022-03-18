//
//  DiseaseError.swift
//  AccessilityDemo
//
//  Created by Erwan BOUET on 17/03/2022.
//

import Foundation

enum DiseaseError: Error {
    case insertError
    case missingData
    case wrongDataFormat(error: Error)
}
