//
//  MemberCoordinator.swift
//  Presentation
//
//  Created by 홍은표 on 1/2/25.
//

import Foundation

import Networkings
import Utill

import ComposableArchitecture
import KeychainAccess
import TCACoordinators

@Reducer
public struct MemberCoordinator {
  public init() {}
  
  @ObservableState
  public struct State: Equatable {
    var routes: [Route<MemberScreen.State>]
    
    public init() {
      routes = [.root(.member(.init()), embedInNavigationView: true)]
    }
  }
 
  public enum Action: ViewAction, BindableAction, FeatureAction {
    case binding(BindingAction<State>)
    case router(IndexedRouterActionOf<MemberScreen>)
    case view(View)
    case inner(InnerAction)
    case async(AsyncAction)
    case navigation(NavigationAction)
  }
  
  @CasePathable
  public enum View {
    
  }
  
  public enum AsyncAction: Equatable {
    
  }

  public enum InnerAction: Equatable {
    
  }
  
  public enum NavigationAction: Equatable {
    
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
        
      case .router(let action):
        return handleRouterAction(state: &state, action: action)
        
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
  
  private func handleRouterAction(
    state: inout State,
    action: IndexedRouterActionOf<MemberScreen>
  ) -> Effect<Action> {
//    switch action {
//    case .routeAction(id: _, action: .)
//      state.routes.push()
      return .none
//    }
  }
  
  private func handleViewAction(
    state: inout State,
    action: View
  ) -> Effect<Action> {
    return .none
  }
  
  private func handleInnerAction(
    state: inout State,
    action: InnerAction
  ) -> Effect<Action> {
    return .none
  }
  
  private func handleAsyncAction(
    state: inout State,
    action: AsyncAction
  ) -> Effect<Action> {
    return .none
  }
  
  private func handleNavigationAction(
    state: inout State,
    action: NavigationAction
  ) -> Effect<Action> {
    return .none
  }
}

extension MemberCoordinator {
  @Reducer(state: .equatable)
  public enum MemberScreen {
    case member(MemberMain)
  }
}
