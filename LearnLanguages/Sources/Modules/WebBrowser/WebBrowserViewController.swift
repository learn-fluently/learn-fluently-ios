//
//  WebBrowserViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/22/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import WebKit
import SnapKit

protocol WebBrowserViewControllerDelegate: AnyObject {

    func getDownloadHandlerBlock(mimeType: String, url: URL) -> (() -> Void)?

}

class WebBrowserViewController: BaseViewController, NibBasedViewController {

    // MARK: Properties

    static var lastURL: URL?

    weak var delegate: WebBrowserViewControllerDelegate?

    private var parentView: UIView
    private var isDismissing: Bool = false

    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var inputTextField: UITextField!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!


    // MARK: Life cycle

    init(parentView: UIView) {
        self.parentView = parentView
        super.init(nibName: WebBrowserViewController.nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureInputTextField()
        configureWebView()
        loadingIndicator.isHidden = true
    }

    override func didMove(toParent parent: UIViewController?) {
        if parent != nil {
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        makeConstraintForView()
        if let lastURL = WebBrowserViewController.lastURL {
            webView.load(URLRequest(url: lastURL))
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputTextField.becomeFirstResponder()
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if !isDismissing {
            isDismissing = true
            super.dismiss(animated: flag) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion?()
                }
            }
        }
    }


    // MARK: Event handlers

    @IBAction private func onCloseButtonTouched() {
        dismiss(animated: true, completion: nil)
    }


    // MARK: Private functions

    private func makeConstraintForView() {
        if let superview = view.superview?.superview {
            view.snp.makeConstraints {
                $0.width.equalTo(superview)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    $0.height.equalTo(700)
                } else {
                    $0.top.equalTo(parentView).inset(parentView.safeAreaInsets.top).priority(.high)
                }
            }
        }
    }
    private func configureInputTextField() {
        inputTextField.keyboardType = .webSearch
        inputTextField.delegate = self
        setReturnKeyType(.done)
        inputTextField.addTarget(self, action: #selector(adjustInputTextFieldReturnKeyType), for: .editingChanged)
    }

    private func configureWebView() {
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        let top = topView.frame.height
        webView.scrollView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)
        webView.scrollView.scrollIndicatorInsets = webView.scrollView.contentInset
    }

    @objc private func adjustInputTextFieldReturnKeyType() {
        if inputTextField.text?.isValidURL == true {
            setReturnKeyType(.go)
        } else if inputTextField.text?.lengthOfBytes(using: .utf8) ?? 0 > 0 {
            setReturnKeyType(.google)
        } else {
            setReturnKeyType(.done)
        }
    }

    private func setReturnKeyType(_ returnKeyType: UIReturnKeyType) {
        if inputTextField.returnKeyType != returnKeyType {
            inputTextField.returnKeyType = returnKeyType
            inputTextField.reloadInputViews()
        }
    }

    private func loadWebViewFromTextFieldText() {
        guard var text = inputTextField.text else {
            return
        }

        switch inputTextField.returnKeyType {
        case .go:
            if !text.starts(with: "http"), !text.starts(with: "ftp") {
                text = "https://" + text
            }

        case .google:
            text = "https://www.google.com/search?q=\(text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")"

        default:
            return
        }

        webView.load(URLRequest(url: text.asURL!))
        view.endEditing(true)
    }

    private func setLoading(_ isLoading: Bool) {
        isLoading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
        self.loadingIndicator.alpha = isLoading ? 0 : 1
        UIView.animate(withDuration: 0.25) {
            self.loadingIndicator.isHidden = !isLoading
            self.loadingIndicator.alpha = isLoading ? 1 : 0
        }
    }

    private func saveCookies(navigationResponse: WKNavigationResponse) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse, let url = httpResponse.url {
            let allHeaders = httpResponse.allHeaderFields.reduce([String: String](), { result, next -> [String: String] in
                guard let stringKey = next.key as? String, let stringValue = next.value as? String else { return result }
                var buffer = result
                buffer[stringKey] = stringValue
                return buffer
            })
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: allHeaders, for: url)
            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }
}


extension WebBrowserViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        loadWebViewFromTextFieldText()
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        adjustInputTextFieldReturnKeyType()
        return true
    }

}


extension WebBrowserViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        setLoading(false)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        setLoading(false)
    }

    /*
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if let downloadHandler = delegate?.getDownloadHandlerBlock(mimeType: "", url: url) {
                dismiss(animated: true, completion: downloadHandler)
            }
        }
        decisionHandler(.allow)
    }*/

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let mimeType = navigationResponse.response.mimeType,
            let url = navigationResponse.response.url {
            if let downloadHandler = delegate?.getDownloadHandlerBlock(mimeType: mimeType, url: url) {
                saveCookies(navigationResponse: navigationResponse)
                dismiss(animated: true, completion: downloadHandler)
            }
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        setLoading(true)
        inputTextField.text = webView.url?.absoluteString
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if !isDismissing {
            WebBrowserViewController.lastURL = webView.url
        }
    }

}
