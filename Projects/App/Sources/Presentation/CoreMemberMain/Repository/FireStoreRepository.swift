//
//  FireStoreRepository.swift
//  DDDAttendance
//
//  Created by 서원지 on 6/9/24.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase
import KeychainAccess
import Service

@Observable public class FireStoreRepository: FireStoreRepositoryProtocol {
    
    
    
    private let fireStoreDB = Firestore.firestore()
    private let ref = Database.database().reference()
    private var listener: ListenerRegistration?
    
    public init() {
        
    }
    
    //MARK: - firebase 데이터 베이스에서 members 값 가지고 오기
    public func fetchFireStoreData<T: Decodable>(from collection: String, as type: T.Type) async throws -> [T] {
        let querySnapshot = try await fireStoreDB.collection(collection).getDocuments()
        Log.debug("firebase 데이터 가져오기 성공", collection, querySnapshot.documents.forEach { Log.debug($0.data()) })
        return querySnapshot.documents.compactMap { document in
            do {
                return try document.data(as: T.self)
            } catch {
                Log.error("Failed to decode document to \(T.self): \(error)")
                return nil
            }
        }
    }
    
    
    //MARK: - firebase 유저 정보가져오기
    public func getCurrentUser() async throws -> User? {
        return Auth.auth().currentUser
    }
    
    //MARK: - firebase 실시간 정보 가져오기
    public func observeFireBaseChanges<T>(from collection: String, as type: T.Type) async throws -> AsyncStream<Result<[T], CustomError>> where T: Decodable {
        AsyncStream { continuation in
            let collectionRef = fireStoreDB.collection(collection)
            
            listener = collectionRef.addSnapshotListener { querySnapshot, error in
                let result: Result<[T], CustomError> = {
                    guard let snapshot = querySnapshot else {
                        let customError = error.map { CustomError.unknownError($0.localizedDescription) } ?? CustomError.unknownError("Unknown error")
                        return .failure(customError)
                    }
                    
                    do {
                        let records = try snapshot.documents.compactMap { document in
                            try document.data(as: T.self)
                        }
                        Log.debug("firebase 데이터 실시간 변경", records.map { $0 }, #function)
                        return .success(records)
                    } catch {
                        return .failure(.decodeFailed)
                    }
                }()
                
                switch result {
                case .success(let records):
                    continuation.yield(.success(records))
                case .failure(let error):
                    continuation.yield(.failure(error))
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                self.listener?.remove()
            }
        }
    }
    
    //MARK: - firebase 로 이벤트 만들기
    public func createEvent(event: DDDEvent, from collection: String) async throws -> DDDEvent? {
        var newEvent = event
        if let documentReference = try? await fireStoreDB.collection(collection).addDocument(data: event.toDictionary()) {
            newEvent.id = documentReference.documentID
            Log.debug("Document added with ID: ", "\(#function)", "\(documentReference.documentID)")
            try saveDocumentIDToKeychain(documentID: documentReference.documentID)
            return newEvent
        } else {
            Log.error("Error adding document")
            return nil
        }
    }
    //MARK: -  키체인에 배열에 값 추가 하기
    private func saveDocumentIDToKeychain(documentID: String) throws {
        do {
            var documentIDs: [String] = []
            if let data = try Keychain().getData("deleteEventIDs"),
               let existingIDs = try? JSONDecoder().decode([String].self, from: data) {
                documentIDs = existingIDs
            }
            
            documentIDs.append(documentID)
            
            let data = try JSONEncoder().encode(documentIDs)
            try Keychain().set(data, key: "deleteEventIDs")
            
            Log.debug("Document ID saved to Keychain: \(documentID)")
        } catch {
            Log.error("Error saving document ID to Keychain: \(error)")
            throw CustomError.unknownError("Error saving document ID to Keychain: \(error.localizedDescription)")
        }
    }
    
    //MARK: - event 수정하기
    public func editEventStream(event: DDDEvent, in collection: String) async throws -> AsyncStream<Result<DDDEvent, CustomError>> {
        AsyncStream { continuation in
            guard let eventID = event.id else {
                continuation.yield(.failure(.invalidEventId))
                continuation.finish()
                return
            }
            
            do {
                try fireStoreDB.collection(collection).document(eventID).setData(from: event) { error in
                    if let error = error {
                        continuation.yield(.failure(.firestoreError(error.localizedDescription)))
                    } else {
                        continuation.yield(.success(event))
                    }
                    continuation.finish()
                }
            } catch {
                continuation.yield(.failure(.firestoreError(error.localizedDescription)))
                continuation.finish()
            }
        }
    }
    
    //MARK: - evnet삭제 하기
    public func deleteEvent(from collection: String) async throws {
        guard let storedData = try Keychain().getData("deleteEventIDs"),
              let storedDocumentIDs = try? JSONDecoder().decode([String].self, from: storedData) else {
            throw CustomError.unknownError("No stored document IDs found in Keychain.")
        }
        
        // Query the collection for all documents
        let querySnapshot = try await fireStoreDB.collection(collection).getDocuments()
        
        Log.debug("Document IDs from Firestore: \(querySnapshot.documents.map { $0.documentID })")
        Log.debug("Stored document IDs: \(storedDocumentIDs)")
        // Loop through the documents and delete the first matched document
        for document in querySnapshot.documents {
            
            if storedDocumentIDs.contains(document.documentID) {
                do {
                    Log.debug("Deleting document with ID: \(document.documentID)")
                    try await fireStoreDB.collection(collection).document(document.documentID).delete()
                    Log.debug("Document successfully removed!")
                    
                    try removeDocumentIDFromKeychain(documentID: document.documentID)
                    
                    break
                } catch {
                    Log.error("Error removing document: \(error)")
                    throw CustomError.unknownError("Error removing document: \(error.localizedDescription)")
                }
            }
        }
    }
    
    //MARK: -  키체인에 배열에 값 삭제 하기
    private func removeDocumentIDFromKeychain(documentID: String) throws {
        do {
            // Retrieve the existing array from Keychain
            var documentIDs: [String] = []
            if let data = try Keychain().getData("deleteEventIDs"),
               let existingIDs = try? JSONDecoder().decode([String].self, from: data) {
                documentIDs = existingIDs
            }
            
            // Remove the document ID
            documentIDs.removeAll { $0 == documentID }
            
            // Save the updated array back to the Keychain
            let data = try JSONEncoder().encode(documentIDs)
            try Keychain().set(data, key: "deleteEventIDs")
            
            Log.debug("Document ID removed from Keychain: \(documentID)")
        } catch {
            Log.error("Error removing document ID from Keychain: \(error)")
            throw CustomError.unknownError("Error removing document ID from Keychain: \(error.localizedDescription)")
        }
    }
}
