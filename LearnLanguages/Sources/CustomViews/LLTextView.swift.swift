//
//  LLTextView.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 12/27/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//
import UIKit


public protocol LLTextViewMenuDelegate {
    
    //  MARK: public functions
    
    func onTranslateMenuItemSelected(_ textView: UITextView)
    func onImageMenuItemSelected(_ textView: UITextView)
    func onGoogleMenuItemSelected(_ textView: UITextView)
    func onSpeechMenuItemSelected(_ textView: UITextView)
}

class LLTextView: UITextView {
    
    // MARK: Properties
    
    var menuItemsDelegate: LLTextViewMenuDelegate?
    
    
    // MARK: Private properties
    
    var customMenuItems: [UIMenuItem] = []
    
    
    // MARK: Life Cycle
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addCustomMenu()
    }
    
    
    // MARK: Private method
    
    private func addCustomMenu() {
        let translateMenuItem = UIMenuItem(title: "Translate", action: #selector(onTranslateMenuItemSelected))
        let imagesMenuItem = UIMenuItem(title: "Images", action: #selector(onImageMenuItemSelected))
        let googleMenuItem = UIMenuItem(title: "Google", action: #selector(onGoogleMenuItemSelected))
        let speechMenuItem = UIMenuItem(title: "Speech", action: #selector(onSpeechMenuItemSelected))
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
        if customMenuItems.first(where: {$0.action == action}) != nil {
            return true
        }
        
        return false
    }
}
