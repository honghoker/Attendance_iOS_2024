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
    private var listener: ListenerRegistration?
    
    public init() {
        
    }
    
    //MARK: - firebase 데이터 베이스에서 members 값 가지고 오기
    public func fetchFireStoreData<T: Decodable>(
        from collection: FireBaseCollection,
        as type: T.Type,
        shouldSave: Bool
    ) async throws -> [T] {
        let querySnapshot = try await fireStoreDB.collection(collection.desc).getDocuments()
        Log.debug("firebase 데이터 가져오기 성공", collection, querySnapshot.documents.map { $0.data() })
        
        return querySnapshot.documents.compactMap { document in
            do {
                let data = try document.data(as: T.self)
                
                if shouldSave {
                    try Keychain().saveDocumentIDToKeychain(documentID: document.documentID)
                }
                
                return data
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
    
    public func getUserLogOut() async throws -> User? {
        do {
            try Auth.auth().signOut()
            Log.debug("User successfully signed out")
            try? Keychain().removeAll()
            return nil
        } catch let signOutError as NSError {
            Log.error("로그아웃 에러: \(signOutError)")
            throw CustomError.unknownError(signOutError.localizedDescription)
        }
    }
    
    //MARK: - firebase 실시간 정보 가져오기
    public func observeFireBaseChanges<T>(
        from collection: FireBaseCollection,
        as type: T.Type
    ) async throws -> AsyncStream<Result<[T], CustomError>> where T: Decodable {
        AsyncStream { continuation in
            let collectionRef = fireStoreDB.collection(collection.desc)
            
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
    public func createEvent(
        event: DDDEvent,
        from collection: FireBaseCollection
    ) async throws -> DDDEvent? {
        var newEvent = event
        if let documentReference = try? await fireStoreDB.collection(collection.desc).addDocument(data: event.toDictionary()) {
            newEvent.id = documentReference.documentID
            Log.debug("Document added with ID: ", "\(#function)", "\(documentReference.documentID)")
            try Keychain().saveDocumentIDToKeychain(documentID: documentReference.documentID)
            return newEvent
        } else {
            Log.error("Error adding document")
            return nil
        }
    }
    
    //MARK: - event 수정하기
    public func editEvent(
            event: DDDEvent,
            in collection: FireBaseCollection
    ) async throws -> DDDEvent? {
        var updateEvent = event
        guard let storedData = try Keychain().getData("deleteEventIDs"),
              let storedDocumentIDs = try? JSONDecoder().decode([String].self, from: storedData) else {
            throw CustomError.unknownError("No stored document IDs found in Keychain.")
        }
        Log.debug("Document IDs from Firestore: \(storedDocumentIDs)")
        let querySnapshot = try await fireStoreDB.collection(collection.desc).getDocuments()
        
        Log.debug("Document IDs from Firestore: \(querySnapshot.documents.map { $0.documentID })")
        Log.debug("update document IDs: \(storedDocumentIDs)")
        
        for document in querySnapshot.documents {
            do {
                Log.debug("Deleting document with ID: \(document.documentID)")
                try await fireStoreDB.collection(collection.desc).document(document.documentID).updateData(updateEvent.toDictionary())
                Log.debug("Document successfully removed!")
                return updateEvent
            } catch {
                Log.error("Error removing document: \(error)")
                throw CustomError.unknownError("Error removing document: \(error.localizedDescription)")
            }
        }
        return updateEvent
        
    }
    
    //MARK: - evnet삭제 하기
    public func deleteEvent(from collection: FireBaseCollection) async throws {
        guard let storedData = try Keychain().getData("deleteEventIDs"),
              let storedDocumentIDs = try? JSONDecoder().decode([String].self, from: storedData) else {
            throw CustomError.unknownError("No stored document IDs found in Keychain.")
        }
        
        let querySnapshot = try await fireStoreDB.collection(collection.desc).getDocuments()
        
        Log.debug("Document IDs from Firestore: \(querySnapshot.documents.map { $0.documentID })")
        Log.debug("Stored document IDs: \(storedDocumentIDs)")
        
        for document in querySnapshot.documents {
            
            if storedDocumentIDs.contains(document.documentID) {
                do {
                    Log.debug("Deleting document with ID: \(document.documentID)")
                    try await fireStoreDB.collection(collection.desc).document(document.documentID).delete()
                    Log.debug("Document successfully removed!")
                    try? Keychain().remove("startTime")
                    
                    try Keychain().removeDocumentIDFromKeychain(documentID: document.documentID)
                    
                    break
                } catch {
                    Log.error("Error removing document: \(error)")
                    throw CustomError.unknownError("Error removing document: \(error.localizedDescription)")
                }
            }
        }
    }
}
    
    
    
    
