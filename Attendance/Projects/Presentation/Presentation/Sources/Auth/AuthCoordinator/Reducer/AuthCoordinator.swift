//
//  AuthCoordinator.swift
//  Presentation
//
//  Created by Wonji Suh  on 11/2/24.
//

import Foundation

import Networkings
import Utill

import ComposableArchitecture
import TCACoordinators

@Reducer
public struct AuthCoordinator {
  public init() {}
  
  @ObservableState
  public struct State: Equatable {
    
    var routes: [Route<AuthScreen.State>]
    @Shared(.inMemory("Member")) var userSignUpMember: Member = .init()
    
    public init() {
      self.routes = [.root(.login(.init()), embedInNavigationView: true)]
    }
  }
  
  public enum Action: FeatureAction, BindableAction {
    case binding(BindingAction<State>)
    case router(IndexedRouterActionOf<AuthScreen>)
    case view(View)
    case async(AsyncAction)
    case inner(InnerAction)
    case navigation(NavigationAction)
  }
  
  // MARK: - ViewAction
  
  @CasePathable
  public enum View {
    case backAction
    case backToRootAction
  }
  
  // MARK: - AsyncAction 비동기 처리 액션
  
  public enum AsyncAction: Equatable {
    
  }
  
  // MARK: - 앱내에서 사용하는 액션
  
  public enum InnerAction: Equatable {
    
  }
  
  // MARK: - NavigationAction
  
  public enum NavigationAction: Equatable {
    case presentCoreMember
    case presentMember
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(_):
        return .none
        
      case .router(let routeAction):
        return routerAction(state: &state, action: routeAction)
        
      case .view(let viewAction):
        return handleViewAction(state: &state, action: viewAction)
        
      case .async(let asyncAction):
        return handleAsyncAction(state: &state, action: asyncAction)
        
      case .inner(let innerAction):
        return handleInnerAction(state: &state, action: innerAction)
        
      case .navigation(let navigationAction):
        return handleNavigationAction(state: &state, action: navigationAction)
      }
    }
    .forEachRoute(\.routes, action: \.router)
  }
  
  private func routerAction(
    state: inout State,
    action: IndexedRouterActionOf<AuthScreen>
  ) -> Effect<Action> {
    switch action {
      
    // MARK: - 초대코드 입력
      
    case .routeAction(id: _, action: .login(.navigation(.presentSignUpInviteView))):
      state.routes.push(.signUpInviteCode(.init(userSignUp: state.userSignUpMember)))
      return .none
      
    case .routeAction(id: _, action: .login(.navigation(.presentCoreMemberMain))):
      return .send(.navigation(.presentCoreMember))
      
    case .routeAction(id: _, action: .login(.navigation(.presentMemberMain))):
      return .send(.navigation(.presentMember))
      
    // MARK: - 이름 입력
      
    case .routeAction(id: _, action: .signUpInviteCode(.navigation(.presentSignUpName))):
      state.routes.push(.signUpName(.init()))
      return .none
      
    case .routeAction(id: _, action: .signUpName(.navigation(.presentSignUpPart))):
      state.routes.push(.signUpPart(.init()))
      return .none
      
    // MARK: - 운영진 담당업무 선택
      
    case .routeAction(id: _, action: .signUpPart(.navigation(.presentManging))):
      state.routes.push(.signUpManging(.init()))
      return .none
      
    case .routeAction(id: _, action: .signUpManging(.navigation(.presentCoreMember))):
      return .send(.navigation(.presentCoreMember))
      
    // MARK: - 멤버 선택 할팀 선택
      
    case .routeAction(id: _, action: .signUpPart(.navigation(.presentSelectTeam))):
      state.routes.push(.signUpSelectTeam(.init()))
      return .none
      
    case .routeAction(id: _, action: .signUpSelectTeam(.navigation(.presentMember))):
      return .send(.navigation(.presentMember))
      
    default:
      return .none
    }
  }
  
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    switch action {
    case .backAction:
      state.routes.goBack()
      return .none
      
    case .backToRootAction:
      return .routeWithDelaysIfUnsupported(state.routes, action: \.router) {
        $0.goBackToRoot()
      }
    }
  }
  
  private func handleNavigationAction(
    state: inout State,
    action: NavigationAction
  ) -> Effect<Action> {
    switch action {
    case .presentCoreMember:
      return .none
      
    case .presentMember:
      return .none
    }
  }
  
  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    switch action {
      
    }
  }
  
  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    switch action {
      
    }
  }
}

extension AuthCoordinator {
  @Reducer(state: .equatable)
  public enum AuthScreen {
    case login(Login)
    case signUpInviteCode(SignUpInviteCode)
    case signUpName(SignUpName)
    case signUpPart(SignUpPart)
    case signUpManging(SignUpSelectManging)
    case signUpSelectTeam(SignUpSelectTeam)
  }
}
