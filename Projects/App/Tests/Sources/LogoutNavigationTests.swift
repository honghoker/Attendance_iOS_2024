//
//  LogoutNavigationTests.swift
//  TestsTests
//
//  Created by DDD on 9/4/26.
//

import Foundation
import Testing

@testable import DDDAttendance
@testable import DDDStorage
import AuthDomainInterface
import DDDStorageInterface

import ComposableArchitecture
import SQLiteData
import TCAFlow

@Suite("Logout navigation")
@MainActor
struct LogoutNavigationTests {
  @Test("계정 만료 시 SQLite 세션도 비워 다음 로그인에서 이전 캐시를 허용하지 않는다")
  func expirationPersistsEmptyIdentityBeforeNextLogin() async throws {
    let database = try DatabaseQueue()
    try AppDatabaseMigrator.migrate(database)
    let storage = SQLiteSharedValueStorage(database: database)
    try await database.write { db in
      try #sql("INSERT INTO legacyCacheImport VALUES (1, 42, 42)").execute(db)
    }
    let defaultsName = "LogoutNavigationTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: defaultsName))
    defer { defaults.removePersistentDomain(forName: defaultsName) }

    try await withDependencies {
      $0.context = .live
      $0.sharedValueStorage = storage
      $0.defaultAppStorage = defaults
    } operation: {
      @Shared(.userSession) var session
      @Shared(.staffRole) var role
      $session.withLock { $0 = UserSession(userID: 42, name: "이전 계정") }
      $role.withLock { $0 = .member }
      let store = Store(initialState: AppReducer.State.member(.init())) { AppReducer() }
      #expect(try await database.read { try LegacyCacheAccess.isAllowed(.profile, profileUserID: 42, in: $0) })

      await store.send(.async(.refreshTokenExpired)).finish()
      $role.withLock { $0 = .manager }

      let data = try #require(try storage.load(forKey: "UserSession"))
      let snapshot = try JSONDecoder().decode(SessionIdentity.self, from: data)
      #expect(snapshot.userID == 0)
      #expect(try await database.read { try !LegacyCacheAccess.isAllowed(.profile, profileUserID: 42, in: $0) })
      #expect(try await database.read { try !LegacyCacheAccess.isAllowed(.schedule, in: $0) })
    }
  }

  private struct SessionIdentity: Decodable { let userID: Int }

  @Test("로그아웃과 만료는 이전 계정 정보를 비운 뒤 인증 화면을 연다", arguments: [false, true])
  func authTransitionClearsPreviousIdentity(expired: Bool) async {
    await withDependencies {
      $0.defaultInMemoryStorage = InMemoryStorage()
    } operation: {
      @Shared(.userSession) var session
      @Shared(.staffRole) var role
      $session.withLock {
        $0 = UserSession(userID: 42, name: "이전 계정", userRole: .manager, accessToken: "old-token")
      }
      $role.withLock { $0 = .manager }
      let store = Store(initialState: AppReducer.State.member(.init())) { AppReducer() }

      await store.send(expired ? .async(.refreshTokenExpired) : .view(.presentAuth)).finish()

      #expect(session == .empty)
      #expect(role == nil)
      guard case .auth = store.state else {
        Issue.record("세션을 비운 뒤 인증 화면으로 전환해야 한다")
        return
      }
      // 다음 로그인에서 역할이 먼저 설정돼도 이전 사용자 ID가 복구되지 않는다.
      $role.withLock { $0 = .member }
      #expect(session.userID == 0)
    }
  }

  @Test("Profile 로그아웃은 화면을 pop하지 않고 로그인 전환을 요청한다")
  func profileLogoutRequestsLoginWithoutPoppingRoutes() async {
    let store = TestStore(initialState: ProfileCoordinator.State()) {
      ProfileCoordinator()
    }

    await store.send(
      .router(
        .routeAction(
          id: 0,
          action: .profile(.delegate(.presentLogOut))
        )
      )
    )
    await store.receive {
      guard case .navigation(.presentLogin) = $0 else { return false }
      return true
    }
  }

  @Test("Member 로그아웃은 이전 화면으로 가지 않고 로그인 전환을 전달한다")
  func memberLogoutRequestsLoginWithoutPoppingRoutes() async {
    var initialState = MemberCoordinator.State()
    initialState.routes.append(.push(.profile(.init())))

    let store = TestStore(initialState: initialState) {
      MemberCoordinator()
    }

    await store.send(
      .router(
        .routeAction(
          id: 1,
          action: .profile(.navigation(.presentLogin))
        )
      )
    )
    await store.receive {
      guard case .navigation(.presentLogin) = $0 else { return false }
      return true
    }
  }

  @Test("Staff 로그아웃은 이전 화면으로 가지 않고 로그인 전환을 전달한다")
  func staffLogoutRequestsLoginWithoutPoppingRoutes() async {
    var initialState = StaffCoordinator.State()
    initialState.routes.append(.push(.profile(.init())))

    let store = TestStore(initialState: initialState) {
      StaffCoordinator()
    }

    await store.send(
      .router(
        .routeAction(
          id: 1,
          action: .profile(.navigation(.presentLogin))
        )
      )
    )
    await store.receive {
      guard case .navigation(.presentLogin) = $0 else { return false }
      return true
    }
  }
}
