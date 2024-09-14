//
//  SignupPartViewController.swift
//  DDDAttendance
//
//  Created by 고병학 on 6/6/24.
//

import ReactorKit

import UIKit

final class SignupPartViewController: UIViewController {
    
    typealias Reactor = SignupPartReactor
    
    // MARK: - UI properties
    private var mainView: SignupPartView { view as! SignupPartView }
    
    // MARK: - Properties
    var disposeBag: DisposeBag = .init()
    private lazy var feedbackGenerator: UIImpactFeedbackGenerator = .init()
    
    // MARK: - Lifecycles
    init(_ member: MemberRequestModel) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = Reactor(member: member)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = SignupPartView()
    }
    
    // MARK: - Public helpers
    
    // MARK: - Private helpers
    private func pushSignupInviteCodeViewController() {
//        let vc: SignupRoleViewController =
//        self.navigationController?.pushViewController(
//            vc,
//            animated: true
//        )
    }
}

extension SignupPartViewController: View {
    func bind(reactor: SignupPartReactor) {
        // Action
        mainView.iOSButton.rx.tap
            .map { Reactor.Action.selectPart(.iOS) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        mainView.webButton.rx.tap
            .map { Reactor.Action.selectPart(.web) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        mainView.serverButton.rx.tap
            .map { Reactor.Action.selectPart(.server) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        mainView.androidButton.rx.tap
            .map { Reactor.Action.selectPart(.android) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        mainView.designerButton.rx.tap
            .map { Reactor.Action.selectPart(.design) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        mainView.pmButton.rx.tap
            .map { Reactor.Action.selectPart(.pm) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        mainView.nextButton.rx.tap
            .bind { [weak self] in
                self?.pushSignupInviteCodeViewController()
            }.disposed(by: disposeBag)
        
        self.mainView.backButton.rx.throttleTap.bind { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }.disposed(by: self.disposeBag)
        
        reactor.state.map { $0.member.memberPart }
            .distinctUntilChanged()
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] part in
                self?.feedbackGenerator.impactOccurred()
                
                self?.mainView.iOSButton.isSelected = part == .iOS
                self?.mainView.webButton.isSelected = part == .web
                self?.mainView.serverButton.isSelected = part == .server
                self?.mainView.androidButton.isSelected = part == .android
                self?.mainView.designerButton.isSelected = part == .design
                self?.mainView.pmButton.isSelected = part == .pm
                
                self?.mainView.nextButton.isEnabled = part != nil
            })
            .disposed(by: self.disposeBag)
    }
}
