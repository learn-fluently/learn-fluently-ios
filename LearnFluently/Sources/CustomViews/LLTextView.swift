//
//  LLTextView.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 12/27/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//
import UIKit


public protocol LLTextViewMenuDelegate: AnyObject {

    // MARK: public functions

    func onTranslateMenuItemSelected(_ textView: UITextView)
    func onImageMenuItemSelected(_ textView: UITextView)
    func onGoogleMenuItemSelected(_ textView: UITextView)
    func onSpeechMenuItemSelected(_ textView: UITextView)
}

class LLTextView: UITextView {

    // MARK: Properties

    weak var menuItemsDelegate: LLTextViewMenuDelegate?


    // MARK: Private properties

    var customMenuItems: [UIMenuItem] = []


    // MARK: Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addCustomMenu()
    }


    // MARK: Private method

    private func addCustomMenu() {
        let translateMenuItem = UIMenuItem(title: .MENU_ITEM_TRANSLATE, action: #selector(onTranslateMenuItemSelected))
        let imagesMenuItem = UIMenuItem(title: .MENU_ITEM_GOOGLE_IMAGES, action: #selector(onImageMenuItemSelected))
        let googleMenuItem = UIMenuItem(title: .MENU_ITEM_GOOGLE_SEARCH, action: #selector(onGoogleMenuItemSelected))
        let speechMenuItem = UIMenuItem(title: .MENU_ITEM_SPEECH, action: #selector(onSpeechMenuItemSelected))
        customMenuItems = [translateMenuItem, imagesMenuItem, googleMenuItem, speechMenuItem]
        UIMenuController.shared.menuItems = customMenuItems
    }

    @objc private func onTranslateMenuItemSelected() {
        menuItemsDelegate?.onTranslateMenuItemSelected(self)
    }

    @objc private func onImageMenuItemSelected() {
        menuItemsDelegate?.onImageMenuItemSelected(self)
    }

    @objc private func onGoogleMenuItemSelected() {
        menuItemsDelegate?.onGoogleMenuItemSelected(self)
    }

    @objc private func onSpeechMenuItemSelected() {
        menuItemsDelegate?.onSpeechMenuItemSelected(self)
    }


    // MARK: Event handeling

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if customMenuItems.first(where: { $0.action == action }) != nil {
            return true
        }

        return false
    }
}
