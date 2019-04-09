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


    // MARK: Lifecycle

    init(window: UIWindow) {
        self.window = window
        navigationController = UINavigationController()
    }


    // MARK: Public functions

    func start() {
        window.rootViewController = instantiateInitialViewController()
        window.makeKeyAndVisible()
    }


    // MARK: Private functions

    private func instantiateInitialViewController() -> UIViewController {
        let viewController = OverviewViewController.instantiate()
        navigationController.setViewControllers([viewController], animated: false)
        return navigationController
    }

}
