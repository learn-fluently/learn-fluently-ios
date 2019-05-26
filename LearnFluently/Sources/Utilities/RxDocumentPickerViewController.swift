//
//  RxDocumentPickerViewController.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 4/18/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import RxSwift
import MobileCoreServices

class RxImportDocumentPickerViewController: UIDocumentPickerViewController {


    // MARK: Parameters

    private let allowedUTIs: [String] = [
        kUTTypeVideo as String, kUTTypeText as String,
        kUTTypeData as String, kUTTypeUTF8PlainText as String,
        kUTTypeText as String, kUTTypeUTF16PlainText as String,
        kUTTypeTXNTextAndMultimediaData as String,
        "public.text", "public.content", "public.data"
    ]

    private var presenterEvent: Single<URL>.SingleObserver?


    // MARK: Life cycle

    init() {
        super.init(documentTypes: allowedUTIs, in: .import)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not available")
    }


    // MARK: Public functions

    func createPresenter(viewController: UIViewController) -> Single<URL> {
        return .create { event in
            self.presenterEvent = event
            self.delegate = self
            self.modalPresentationStyle = .formSheet
            if let popoverController = self.popoverPresentationController {
                popoverController.sourceView = viewController.view
                popoverController.sourceRect = CGRect(origin: viewController.view.center, size: .zero)
                popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
            }
            viewController.present(self, animated: true, completion: nil)
            return Disposables.create()
        }
    }

}


extension RxImportDocumentPickerViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        presenterEvent?(.success(url))
    }
}
