//
//  RxSourceWebBrowserViewController.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 4/20/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import RxSwift

class RxSourceWebBrowserViewController: WebBrowserViewController {


    // MARK: Parameters

    private var presenterEvent: Single<SourceInfo>.SingleObserver?
    private var sourceInfo: SourceInfo?
    private let viewController: UIViewController


    // MARK: Life cycle

    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init(parentView: viewController.view)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not available")
    }


    // MARK: Public functions

    func createPresenter(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        return .create { event in
            self.presenterEvent = event
            self.sourceInfo = sourceInfo
            let alert = UIAlertController(style: .actionSheet)
            self.delegate = self
            alert.set(vc: self)
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
            }
            self.viewController.present(alert, animated: true, completion: nil)
            return Disposables.create()
        }
    }

}


extension RxSourceWebBrowserViewController: WebBrowserViewControllerDelegate {

    func onCloseButtonTouched(controller: WebBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }

    func onNewResponse(controller: WebBrowserViewController, mimeType: String, url: URL) {
        guard var sourceInfo = sourceInfo,
            let presenterEvent = presenterEvent else {
            return
        }
        sourceInfo.mimeType = SourceInfo.MimeType(rawValue: mimeType)
        sourceInfo.sourceURL = url
        if sourceInfo.isSupported {
            self.delegate = nil
            dismiss(animated: true) {
                presenterEvent(.success(sourceInfo))
            }
        }
    }

}
