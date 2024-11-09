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
    func fetchBox(byId id: String) -> Box?
    func updateBox(_ box: Box) throws
    func deleteBox(_ box: Box) throws
}
