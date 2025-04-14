//
//  MemberMain.swift
//  Presentation
//
//  Created by 홍은표 on 1/2/25.
//

import Foundation

import Networkings
import Model
import Utill

import ComposableArchitecture
import FirebaseAuth

@Reducer
public struct MemberMain {
  public init() {}
  
  @ObservableState
  public struct State: Equatable {
    @Shared(.appStorage("UserUID")) var userUid: String = ""
    @Shared(.appStorage("UserEmail")) var userEmail: String = ""
    var member: UserDTOMember? = nil
    var showWarningAlert: Bool = false
    var schedules: IdentifiedArrayOf<Schedule> = .init(uniqueElements: [
      .init(
        id: UUID().uuidString,
        month: 6,
        day: 11,
        title: "오리엔테이션",
        description: "커리큘럼에 대한 설명 문구 작성",
        status: .present
      ),
      .init(
        id: UUID().uuidString,
        month: 6,
        day: 22,
        title: "부스팅 데이 1",
        description: "커리큘럼에 대한 설명 문구 작성",
        status: .late
      ),
      .init(
        id: UUID().uuidString,
        month: 7,
        day: 06,
        title: "직군 모임 1",
        description: "커리큘럼에 대한 설명 문구 작성",
        status: .absent
      ),
      .init(
        id: UUID().uuidString,
        month: 7,
        day: 20,
        title: "오리엔테이션",
        description: "커리큘럼에 대한 설명 문구 작성",
        status: .tbd
      )
    ])
  }
  
  public enum Action: BindableAction, FeatureAction {
    case binding(BindingAction<State>)
    case view(View)
    case inner(InnerAction)
    case async(AsyncAction)
    case navigation(NavigationAction)
  }
  
  @CasePathable
  public enum View {
    case didTapAbesentButton
    case didTapDismissAlertButton
  }
  
  public enum AsyncAction: Equatable {
    case fetchCurrentUser
  }

  public enum InnerAction: Equatable {
    case onFetchUserResponse(Result<UserDTOMember, CustomError>)
  }
  
  public enum NavigationAction: Equatable {
    case presentQRCode
    case routeToProfile
  }
  
  @Dependency(FireStoreUseCase.self) var fireStoreUseCase
  @Dependency(AuthUseCase.self) var authUseCase
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      
      case .view(let action):
        return handleViewAction(state: &state, action: action)
        
      case .inner(let action):
        return handleInnerAction(state: &state, action: action)
        
      case .async(let action):
        return handleAsyncAction(state: &state, action: action)
        
      case .navigation(let action):
        return handleNavigationAction(state: &state, action: action)
      }
    }
  }
  
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .didTapAbesentButton:
      // TODO: - 조건이 만족할 때만 주의 모달 표시
      /// 명확한 조건 필요
      state.showWarningAlert = true
      return .none
      
    case .didTapDismissAlertButton:
      state.showWarningAlert = false
      return .none
    }
  }
  
  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
    case .onFetchUserResponse(let result):
      switch result {
      case .success(let member):
        state.member = member
        #logDebug("fetching data", member.uid)
        return .none
        
      case .failure(let error):
        state.member = nil
        #logError("Error fetching User", error)
        return .none
      }
    }
  }
  
  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
    case .fetchCurrentUser:
      return .run { [userEmail = state.userEmail] send in
        let result = await Result {
          try await authUseCase.fetchUser(uid: userEmail)
        }
        
        switch result {
        case .success(let member):
          if let member {
            await send(.inner(.onFetchUserResponse(.success(member))))
          }
          
        case .failure(let error):
          let error = CustomError.map(error)
          await send(.inner(.onFetchUserResponse(.failure(error))))
        }
      }
    }
  }
  
  private func handleNavigationAction(
    state: inout State,
    action: NavigationAction
  ) -> Effect<Action> {
    switch action {
    case .presentQRCode:
      // TODO: - present to profile View
      return .none
      
    case .routeToProfile:
      // TODO: - navigate to profile View
      return .none
    }
  }
}
