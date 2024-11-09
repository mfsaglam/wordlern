//
//  RealmCardStore.swift
//  thousand
//
//  Created by Fatih Sağlam on 9.11.2024.
//

import LeitnerSwift
import RealmSwift

class RealmCardStore: CardStore {
    private let realm: Realm

    init(realm: Realm = try! Realm()) {
        self.realm = realm
    }

    // Save all boxes
    func saveBoxes(_ boxes: [Box]) throws {
        let realmBoxes = boxes.map { $0.toRealmBox() }
        
        try realm.write {
            realm.delete(realm.objects(RealmBox.self)) // Delete all existing RealmBox objects
            for realmBox in realmBoxes {
                realm.add(realmBox, update: .modified) // This will add new objects or update existing ones
            }
        }
    }

    // Read all Boxes
    func fetchBoxes() -> [Box] {
        let realmBoxes = realm.objects(RealmBox.self)
        return realmBoxes.map { $0.toBox() }
    }

    // Read a Box by ID (for single Box fetch)
    func fetchBox(byId id: String) -> Box? {
        if let realmBox = realm.object(ofType: RealmBox.self, forPrimaryKey: id) {
            return realmBox.toBox()
        }
        return nil
    }

    // Update a Box
    func updateBox(_ box: Box) throws {
        let realmBox = box.toRealmBox()
        try realm.write {
            if let existingBox = realm.object(ofType: RealmBox.self, forPrimaryKey: realmBox.id) {
                existingBox.cards.removeAll()
                existingBox.cards.append(objectsIn: realmBox.cards)
                existingBox.reviewInterval = box.reviewInterval
                existingBox.lastReviewedDate = box.lastReviewedDate
            }
        }
    }

    // Delete a Box
    func deleteBox(_ box: Box) throws {
        let realmBox = box.toRealmBox()
        try realm.write {
            if let existingBox = realm.object(ofType: RealmBox.self, forPrimaryKey: realmBox.id) {
                realm.delete(existingBox)
            }
        }
    }
}
