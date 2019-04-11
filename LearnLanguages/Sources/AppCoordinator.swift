//
//  AppCoordinator.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 4/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit

class AppCoordinator: Coordinator {

    // MARK: Properties

    let window: UIWindow

    let navigationController: UINavigationController

    private var currentActivity: Activity?


    // MARK: Lifecycle

    init(window: UIWindow) {
        self.window = window
        navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
    }


    // MARK: Public functions

    func start() {
        window.rootViewController = instantiateInitialViewController()
        window.makeKeyAndVisible()
    }


    // MARK: Private functions

    private func instantiateInitialViewController() -> UIViewController {
        let viewController = OverviewViewController(delegate: self)
        navigationController.setViewControllers([viewController], animated: false)
        return navigationController
    }

    private func showSourceConfigViewController(activity: Activity) {
        currentActivity = activity

        let title: String
        switch activity {
        case .watching: title = "Watching/Listening"
        case .speaking: title = "Speaking"
        case .writing: title = "Writing"
        }

        let subtitle: String
        switch activity {
        case .watching: subtitle = "Check translates\nlearn new words"
        case .speaking: subtitle = "Pronunciation training\nSentence structure"
        case .writing: subtitle = "Listening training\ndictation training"
        }

        let viewModel = SourceConfigViewModel(title: title, subtitle: subtitle)
        let viewController = SourceConfigViewController(viewModel: viewModel, delegate: self)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func openActivityCorrespondingViewController() {
        guard let currentActivity = currentActivity else {
            return
        }
        let viewController: UIViewController
        switch currentActivity {
        case .watching: viewController = WatchingViewController(delegate: self)
        case .speaking: viewController = SpeakingViewController(delegate: self)
        case .writing: viewController = WritingViewController(delegate: self)
        }
        navigationController.pushViewController(viewController, animated: true)
    }

}


extension AppCoordinator: OverviewViewControllerDelegate {

    func onWatchingButtonTouched() {
        showSourceConfigViewController(activity: .watching)
    }

    func onSpeakingButtonTouched() {
        showSourceConfigViewController(activity: .speaking)
    }

    func onWritingButtonTouched() {
        showSourceConfigViewController(activity: .writing)
    }

}


extension AppCoordinator: SourceConfigViewControllerDelegate {

    func onPlayButtonTouched() {
        openActivityCorrespondingViewController()
    }

    func onCloseButtonTouched() {
        navigationController.popViewController(animated: true)
    }

}


extension AppCoordinator: WatchingViewControllerDelegate {

    func onCloseButtonTouched(watchingViewController: WatchingViewController) {
        navigationController.popViewController(animated: true)
    }

}


extension AppCoordinator: InputViewControllerDelegate {

    func onCloseButtonTouched(inputViewControllerDelegate: InputViewController) {
        navigationController.popViewController(animated: true)
    }

}


extension AppCoordinator {

    // MARK: Constants

    private enum Activity {

        // MARK: Cases

        case watching
        case writing
        case speaking
    }

}
