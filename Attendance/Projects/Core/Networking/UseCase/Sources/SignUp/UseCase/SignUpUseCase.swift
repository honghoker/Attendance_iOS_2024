//
//  SignUpUseCase.swift
//  UseCase
//
//  Created by Wonji Suh  on 11/3/24.
//

import Model
import ComposableArchitecture
import DiContainer

public struct SignUpUseCase: SignUpUseCaseProtocol {
  
  private let repository: SignUpRepositoryProtcol
  
  public init(
    repository: SignUpRepositoryProtcol
  ) {
    self.repository = repository
  }
  
  //MARK: -  초대코드 확인
  public func validateInviteCode(
    code: String
  ) async throws -> InviteDTOModel? {
    try await repository.validateInviteCode(code: code)
  }
}


extension SignUpUseCase: DependencyKey {
  static public var liveValue: SignUpUseCase = {
    let signUpRepository = DependencyContainer.live.resolve(SignUpRepositoryProtcol.self) ?? DefaultSignUpRepository()
    return SignUpUseCase(repository: signUpRepository)
  }()
}
