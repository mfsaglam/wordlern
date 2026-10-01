//
//  CardStore.swift
//  thousand
//
//  Created by Fatih Sağlam on 9.11.2024.
//

import LeitnerSwift

protocol CardStore {
    func saveBoxes(_ box: [Box]) throws
    func fetchBoxes() -> [Box]
}
