//
//  AppCoordinator.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 4/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import SafariServices

class AppCoordinator: Coordinator {

    // MARK: Properties

    let window: UIWindow

    let navigationController: UINavigationController

    let fileRepository: FileRepository


    // MARK: Lifecycle

    init(window: UIWindow) {
        self.window = window
        fileRepository = FileRepository()
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
        let viewController = OverviewViewController(viewModel: OverviewViewModel(), delegate: self)
        navigationController.setViewControllers([viewController], animated: false)
        return navigationController
    }

    private func showSourceConfigViewController(viewModel: SourceConfigViewModel) {
        let viewController = SourceConfigViewController(viewModel: viewModel, delegate: self)
        navigationController.pushViewController(viewController, animated: true)
    }

    private func openActivityCorrespondingViewController(viewModel: SourceConfigViewModel) {
        let viewController: UIViewController
        switch viewModel.activityType {
        case .watching:
            let viewModel = WatchingViewModel(fileRepository: fileRepository)
            viewController = WatchingViewController(viewModel: viewModel, delegate: self)
        case .speaking: viewController = SpeakingViewController(delegate: self)
        case .writing: viewController = WritingViewController(delegate: self)
        }
        navigationController.pushViewController(viewController, animated: true)
    }

}


extension AppCoordinator: OverviewViewControllerDelegate {

    func onWatchingButtonTouched() {
        showSourceConfigViewController(viewModel: .watching)
    }

    func onSpeakingButtonTouched() {
        showSourceConfigViewController(viewModel: .speaking)
    }

    func onWritingButtonTouched() {
        showSourceConfigViewController(viewModel: .writing)
    }

}


extension AppCoordinator: SourceConfigViewControllerDelegate {

    func onPlayButtonTouched(viewController: SourceConfigViewController) {
        openActivityCorrespondingViewController(viewModel: viewController.viewModel)
    }

    func onCloseButtonTouched(viewController: SourceConfigViewController) {
        navigationController.popViewController(animated: true)
    }

}


extension AppCoordinator: WatchingViewControllerDelegate {

    func onCloseButtonTouched(watchingViewController: WatchingViewController) {
        navigationController.popViewController(animated: true)
    }

    func onOpenWebURLRequest(url: URL) {
        let webView = SFSafariViewController(url: url)
        navigationController.present(webView, animated: true)
    }

}


extension AppCoordinator: InputViewControllerDelegate {

    func onCloseButtonTouched(inputViewControllerDelegate: InputViewController) {
        navigationController.popViewController(animated: true)
    }

}
