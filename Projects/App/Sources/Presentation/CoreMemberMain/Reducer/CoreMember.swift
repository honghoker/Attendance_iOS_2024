//
//  CoreMember.swift
//  DDDAttendance
//
//  Created by 서원지 on 6/6/24.
//

import Foundation
import Service

import ComposableArchitecture
import KeychainAccess
import FirebaseAuth
import SwiftUI

import Utill
import Model
import DesignSystem

@Reducer
public struct CoreMember {
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        public init() {}
        var headerTitle: String = "출석 현황"
        var selectPart: SelectPart? = nil
        var attendaceModel : [Attendance] = []
        var attendaceModels: [Attendance] = []
        var combinedAttendances: [Attendance] = []
        var attendanceStatuses: [AttendanceType] = []
        var disableSelectButton: Bool = false
        var isActiveBoldText: Bool = false
        var isLoading: Bool = false
        var qrcodeImage: ImageAsset = .qrCode
        var eventImage: ImageAsset = .eventGenerate
        var mangerProfilemage: ImageAsset = .mangeMentProfile

        var user: User? =  nil
        var errorMessage: String?
        var attenaceTypeImageName: String = "checkmark"
        var attenaceTypeColor: Color? = nil
        var attenaceNameColor: Color? = nil
        var attenaceGenerationColor: Color?  = nil
        var attenaceRoleTypeColor: Color? = nil
        var attenaceBackGroudColor: Color? = nil
        var attendanceCount: Int = 0
        
        @Presents var destination: Destination.State?
        var selectDate: Date = Date.now
        var selectDatePicker: Bool = false
        //        @Presents var alert: AlertState<Action.Alert>?
        
    }
    
    public enum Action : BindableAction, ViewAction, FeatureAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        case selectDate(date: Date)
        case view(View)
        case async(AsyncAction)
        case inner(InnerAction)
        case navigation(NavigationAction)
        
    }
    
    //MARK: - View action
    public enum View {
        case swipeNext
        case swipePrevious
        case selectPartButton(selectPart: SelectPart)
        case appearSelectPart(selectPart: SelectPart)
        case presntEventModal
        case closePresntEventModal
        case selectDate(date: Date)
        case fetchAttanceTypeImage(attenace: AttendanceType)
        case updateAttendanceCount(attenace: AttendanceType, count: Int)
        
    }
    
    //MARK: - 비동기 처리 액션
    public enum AsyncAction: Equatable {
        case fetchMember
        case fetchAttenDance
        case fetchAttendanceHistory(String)
        case updateAttendanceTypeModel([Attendance])
        case fetchAttendanceHistoryResponse(Result<[Attendance], CustomError>)
        case fetchCurrentUser
        case observeAttendance
        case observeAttendanceCheck
        case updateAttendanceModel([Attendance])
        case fetchUserDataResponse(Result<User, CustomError>)
        case fetchDataResponse(Result<[Attendance], CustomError>)
        case fetchAttendanceDataResponse(Result<[Attendance], CustomError>)
        
        case upDateFetchMember(selectPart: SelectPart)
        
    }
    
    //MARK: - 앱내에서 사용하는 액선
    public enum InnerAction: Equatable {
        
    }
    
    //MARK: - 네비게이션 연결 액션
    public enum NavigationAction: Equatable {
        case presentQrcode
        case presentSchedule
        case tapLogOut
    }
    
    @Reducer(state: .equatable)
    public enum Destination {
        case qrcode(QrCode)
        case makeEvent(MakeEvent)
        
    }
    
    
    @Dependency(FireStoreUseCase.self) var fireStoreUseCase
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(_):
                return .none
                
            case .selectDate(let date):
                if  state.selectDate == date {
                    state.selectDatePicker.toggle()
                } else {
                    state.selectDate = date
                    state.selectDatePicker.toggle()
                }
                
                return .run { @MainActor send in
                    let fetchedDataResult = await Result {
                        try await fireStoreUseCase.fetchFireStoreData(
                            from: .member,
                            as: Attendance.self,
                            shouldSave: false)
                    }
                    
                    switch fetchedDataResult {
                        
                    case let .success(fetchedData):
                        let filteredData = fetchedData.filter { $0.updatedAt.formattedDateToString() == date.formattedDateToString() }
                        Log.debug("날짜 홗인", fetchedData.map { $0.updatedAt.formattedDateToString() }, date.formattedDateToString(), filteredData)
                        send(.async(.updateAttendanceModel(fetchedData)))
                        send(.async(.fetchDataResponse(.success(filteredData))))
                        
                    case let .failure(error):
                        send(.async(.fetchDataResponse(.failure(CustomError.map(error)))))
                    }
                }
                
                
                
            case .destination(_):
                return .none
                
                //            case .alert(.presented(.presentAlert)):
                //                return .none
                
                
                //MARK: - ViewAction
            case .view(let View):
                switch View {
                case .swipeNext:
                    guard let selectPart = state.selectPart else { return .none }
                    if let currentIndex = SelectPart.allCases.firstIndex(of: selectPart),
                       currentIndex < SelectPart.allCases.count - 1 {
                        state.selectPart = SelectPart.allCases[currentIndex + 1]
                    }
                    return .none
                    
                case .swipePrevious:
                    guard let selectPart = state.selectPart else { return .none }
                    if let currentIndex = SelectPart.allCases.firstIndex(of: selectPart),
                       currentIndex > 0 {
                        state.selectPart = SelectPart.allCases[currentIndex - 1]
                    }
                    return .none
                    
                case let .appearSelectPart(selectPart: selectPart):
                    state.selectPart = selectPart
                    return .none
                    
                case let .selectPartButton(selectPart: selectPart):
                    if state.selectPart == selectPart {
                        state.selectPart = nil
                        state.isActiveBoldText = false
                    } else {
                        state.selectPart = selectPart
                        state.isActiveBoldText = true
                    }
                    return .none
                    
                case .presntEventModal:
                    state.destination = .makeEvent(MakeEvent.State())
                    return .none
                    
                case .closePresntEventModal:
                    state.destination = nil
                    return .none
                    
                case .selectDate(let date):
                    if  state.selectDate == date {
                        state.selectDatePicker.toggle()
                    } else {
                        state.selectDate = date
                        state.selectDatePicker.toggle()
                    }
                    
                    return .run { @MainActor send in
                        let fetchedDataResult = await Result {
                            try await fireStoreUseCase.fetchFireStoreData(
                                from: .member,
                                as: Attendance.self,
                                shouldSave: false)
                        }
                        
                        switch fetchedDataResult {
                            
                        case let .success(fetchedData):
                            let filteredData = fetchedData.filter { $0.updatedAt.formattedDateToString() == date.formattedDateToString() }
                            Log.debug("날짜 홗인", fetchedData.map { $0.updatedAt.formattedDateToString() }, date.formattedDateToString(), filteredData)
                            send(.async(.updateAttendanceModel(fetchedData)))
                            send(.async(.fetchDataResponse(.success(filteredData))))
                            
                        case let .failure(error):
                            send(.async(.fetchDataResponse(.failure(CustomError.map(error)))))
                        }
                    }
                    
                case .fetchAttanceTypeImage(let attenace):
                    switch attenace {
                    case .present:
                        state.attenaceTypeImageName = "checkmark"
                        state.attenaceTypeColor = Color.green.opacity(0.4)
                        state.attenaceNameColor = Color.basicBlack
                        state.attenaceGenerationColor = Color.gray600
                        state.attenaceRoleTypeColor = Color.basicBlack
                        state.attenaceBackGroudColor = Color.basicWhite
                        
                    case .absent:
                        state.attenaceTypeImageName = "checkmark"
                        state.attenaceTypeColor = Color.accentColor
                        state.attenaceNameColor = Color.basicBlack
                        state.attenaceGenerationColor = Color.gray600
                        state.attenaceRoleTypeColor = Color.basicBlack
                        state.attenaceBackGroudColor = Color.basicWhite
                    case .late:
                        state.attenaceTypeImageName = "checkmark"
                        state.attenaceTypeColor = Color.red.opacity(0.4)
                        state.attenaceNameColor = Color.gray600
                        state.attenaceGenerationColor = Color.gray600
                        state.attenaceRoleTypeColor = Color.gray600
                        state.attenaceBackGroudColor = Color.gray800
                        
                    case .none:
                        state.attenaceBackGroudColor = Color.gray800
                    
                    default :
                        if attenace == nil  {
                            state.attenaceNameColor = Color.gray600
                            state.attenaceGenerationColor = Color.gray600
                            state.attenaceRoleTypeColor = Color.gray600
                            state.attenaceBackGroudColor = Color.gray800
                        } else {
                            state.attenaceNameColor = Color.gray600
                            state.attenaceGenerationColor = Color.gray600
                            state.attenaceRoleTypeColor = Color.gray600
                            state.attenaceBackGroudColor = Color.gray800
                        }
                    }
                    return .none
                    
                case .updateAttendanceCount(attenace: let attenace, count: let count):
                    state.attendanceCount = count
                    if attenace == .present {
                        state.attendanceCount += 1
                    } else if attenace == .late {
                        state.attendanceCount -= 1
                    }
                    
                    return .none
                }
                
                //MARK: - AsyncAction
            case .async(let AsyncAction):
                switch AsyncAction {
                case .fetchMember:
                    return .run { @MainActor send  in
                        let fetchedDataResult = await Result {
                            try await fireStoreUseCase.fetchFireStoreData(
                                from: .member,
                                as: Attendance.self,
                                shouldSave: false)
                        }
                        
                        switch fetchedDataResult {
                            
                        case let .success(fetchedData):
                            let filterData = fetchedData.filter { $0.memberType == .member || $0.name != ""}
                            send(.async(.fetchDataResponse(.success(filterData))))
                        case let .failure(error):
                            send(.async(.fetchDataResponse(.failure(CustomError.map(error)))))
                        }
                        
                    }
                    
                
                case .fetchAttenDance:
                    // Swift 6 부터 nonisolated(unsafe)  해당 키원드 붙여야 dataRace 오류 안생김
                     // nonisolated(unsafe)  var attendaceModel = state.attendaceModel
                    return .run { @MainActor send  in
                        let fetchedDataResult = await Result {
                            try await fireStoreUseCase.fetchFireStoreData(
                                from: .attendance,
                                as: Attendance.self,
                                shouldSave: false)
                        }
                        switch fetchedDataResult {
                            
                        case let .success(fetchedData):
                            send(.async(.fetchMember))
                            send(.async(.fetchAttendanceDataResponse(.success(fetchedData))))
                            
                            let uids = Set(fetchedData.map { $0.memberId })
                            
                            for uid in uids {
                                send(.async(.fetchMember))
                                send(.async(.fetchAttendanceHistory(uid)))
                            }
                            
                        case let .failure(error):
                            send(.async(.fetchAttendanceDataResponse(.failure(CustomError.map(error)))))
                        }
                        
                    }
                    
                case let .fetchAttendanceHistory(uid):
                       return .run { @MainActor send in
                           for await result in try await fireStoreUseCase.fetchAttendanceHistory(uid, from: .attendance) {
                               send(.async(.fetchAttendanceHistoryResponse(result)))
                           }
                       }
                    
                case let .fetchAttendanceHistoryResponse(result):
                    switch result {
                    case let .success(attendances):
                        return .send(.async(.updateAttendanceTypeModel(attendances)))
                        
                    case let .failure(error):
                        return .send(.async(.fetchAttendanceDataResponse(.failure(error))))
                    }
                    
                case let .updateAttendanceTypeModel(attendances):
                    state.combinedAttendances = attendances
                    
                    // Create a dictionary to quickly find status by memberId
                    let statusDict = Dictionary(uniqueKeysWithValues: attendances.map { ($0.memberId, $0.status) })
                    
                    var updateAttendancesModel: [Attendance] = []
                    
                    for data in state.attendaceModel {
                        let updatedStatus = statusDict[data.memberId]
                        let updatedAttendance = Attendance(
                            id: data.id,
                            memberId: data.memberId,
                            memberType: data.memberType,
                            name: data.name,
                            roleType: data.roleType,
                            eventId: data.eventId,
                            createdAt: data.createdAt,
                            updatedAt: data.updatedAt,
                            status: updatedStatus ?? data.status, // Use the new status if available, otherwise keep the current status
                            generation: data.generation
                        )
                        updateAttendancesModel.append(updatedAttendance)
                    }
                    
                    state.attendaceModel = updateAttendancesModel
                    return .none

                case .fetchCurrentUser:
                    return .run { @MainActor send in
                        let fetchUserResult = await Result {
                            try await fireStoreUseCase.getCurrentUser()
                        }
                        
                        switch fetchUserResult {
                            
                        case let .success(fetchUserResult):
                            guard let fetchUserResult = fetchUserResult else {return}
                            send(.async(.fetchUserDataResponse(.success(fetchUserResult))))
                            
                        case let .failure(error):
                            send(.async(.fetchUserDataResponse(.failure(CustomError.map(error)))))
                        }
                    }
                    
                case .observeAttendance:
                    return .run { @MainActor send in
                        for await result in try await fireStoreUseCase.observeFireBaseChanges(
                            from:  .member,
                            as: Attendance.self
                        ) {
                            send(.async(.fetchDataResponse(result)))
                            
                        }
                    }
                    
                case .observeAttendanceCheck:
                    return .run { @MainActor send in
                        for await result in try await fireStoreUseCase.observeFireBaseChanges(
                            from: .attendance,
                            as: Attendance.self
                        ) {
                            send(.async(.fetchMember))
                            send(.async(.fetchAttendanceDataResponse(result)))
                            send(.async(.fetchMember))
                            send(.async(.fetchMember))
                        }
                    }
                    
                case let .upDateFetchMember(selectPart: selectPart):
                    return .run { @MainActor send in
                        let fetchedDataResult = await Result {
                            try await fireStoreUseCase.fetchFireStoreData(
                                from: .member,
                                as: Attendance.self,
                                shouldSave: false
                            )
                        }
                        
                        switch fetchedDataResult {
                            
                        case let .success(fetchedData):
                            let filteredData = fetchedData.filter { $0.roleType != .all && (selectPart == .all || $0.roleType == selectPart) && $0.memberType == .member && $0.name != ""  }
                            send(.async(.updateAttendanceModel(fetchedData)))
                            send(.async(.fetchDataResponse(.success(filteredData))))
                            
                        case let .failure(error):
                            send(.async(.fetchDataResponse(.failure(CustomError.map(error)))))
                        }
                    }
                    
                case let .fetchUserDataResponse(fetchUser):
                    switch fetchUser {
                    case let .success(fetchUser):
                        state.user = fetchUser
                        Log.error("fetching data", fetchUser.uid)
                    case let .failure(error):
                        Log.error("Error fetching User", error)
                        state.user = nil
                    }
                    return .none
                    
                case let .fetchAttendanceDataResponse(fetchedAttendanceData):
                    switch fetchedAttendanceData {
                    case let .success(fetchedData):
                        state.isLoading = false
                        
                        state.combinedAttendances = fetchedData
                        let statusDict = Dictionary(uniqueKeysWithValues: fetchedData.map { ($0.memberId, $0.status) })
                        
                        let combinedAttendances = state.combinedAttendances
                        var updateAttendancesModel: [Attendance] = []
                        
                        // Log only the first entry of combinedAttendances if it exists
                        Log.debug("combinedAttendances2", state.combinedAttendances)
                        
                        for data in state.attendaceModel {
                            let updatedStatus = statusDict[data.memberId] ?? .none
                            let updatedID = statusDict[data.id]
                            let updatedMemberID = statusDict[data.memberId]
                            let updatedAttendance = Attendance(
                                id: updatedID?.rawValue ?? data.id,
                                memberId: data.memberId,
                                memberType: data.memberType,
                                name: data.name,
                                roleType: data.roleType,
                                eventId: data.eventId,
                                createdAt: data.createdAt,
                                updatedAt: data.updatedAt,
                                status: updatedStatus,
                                generation: data.generation
                            )
                            updateAttendancesModel.append(updatedAttendance)
                            Log.debug("combinedAttendances2", updatedAttendance)
                        }
                        
//                        state.attendaceModel = updateAttendancesModel
                        state.combinedAttendances = combinedAttendances
                        Log.debug("combinedAttendances3",  state.combinedAttendances)
                        state.attendaceModel = combinedAttendances
 
                    case let .failure(error):
                        Log.error("Error fetching data", error)
                        state.isLoading = true
                    }
                    return .none


                    
                case let .updateAttendanceModel(newValue):
                    state.attendaceModel = [ ]
                    state.attendaceModel = newValue.filter { $0.memberType == .member && !$0.name.isEmpty }
                    return .none
                    
                case let .fetchDataResponse(fetchedData):
                    switch fetchedData {
                    case let .success(fetchedData):
                        state.isLoading = false
                        let filteredData = fetchedData.filter { $0.memberType == .member && !$0.name.isEmpty && $0.name != ""}
                        
                        state.attendaceModel = filteredData
                        
//                        state.combinedAttendances = state.attendaceModel
                    case let .failure(error):
                        Log.error("Error fetching data", error)
                        state.isLoading = true
                    }
                    return .none
                }
                
                //MARK: - InnerAction
            case .inner(let InnerAction):
                switch InnerAction {
                    
                }
                
                //MARK: - NavigationAction
            case .navigation(let NavigationAction):
                switch NavigationAction {
                case .presentQrcode:
                    state.destination = .qrcode(.init(userID: state.user?.uid ?? ""))
                    try? Keychain().set(state.user?.uid ?? "" , key: "userID")
                    return .none
                    
                case .presentSchedule:
                    return .none
                    
                case .tapLogOut:
                    return .run { @MainActor send  in
                        let fetchUserResult = await Result {
                            try await fireStoreUseCase.getUserLogOut()
                        }
                        
                        switch fetchUserResult {
                            
                        case let .success(fetchUserResult):
                            guard let fetchUserResult = fetchUserResult else {return}
                            send(.async(.fetchUserDataResponse(.success(fetchUserResult))))
                            
                        case let .failure(error):
                            send(.async(.fetchUserDataResponse(.failure(CustomError.map(error)))))
                        }
                    }
                }
                //            case .alert(.dismiss):
                //                state.alert = nil
                //                return .none
            }
        }
        
        .ifLet(\.$destination, action: \.destination)
        //        .ifLet(\.$alert, action: \.alert)
        .onChange(of: \.attendaceModel) { oldValue, newValue in
            Reduce { state, action in
                state.attendaceModel = newValue
                return .none
            }
        }
        .onChange(of: \.combinedAttendances) { oldValue, newValue in
            Reduce { state, action in
                state.combinedAttendances = newValue
                return .none
            }
        }
    }
}
