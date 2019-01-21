//
//  LLTextView.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 12/27/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//
import UIKit


public protocol LLTextViewMenuDelegate {
    
    func onTranslateMenuItemSelected(_ textView: UITextView, selectedText:String)
    func onImageMenuItemSelected(_ textView: UITextView, selectedText:String)
    func onGoogleMenuItemSelected(_ textView: UITextView, selectedText:String)
}

class LLTextView: UITextView {
    
    var menuItemsDelegate: LLTextViewMenuDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addCustomMenu()
    }
    
    
    func addCustomMenu() {
        let translateMenuItem = UIMenuItem(title: "Translate", action: #selector(onTranslateMenuItemSelected))
        let imagesMenuItem = UIMenuItem(title: "Images", action: #selector(onImageMenuItemSelected))
        let googleMenuItem = UIMenuItem(title: "Google", action: #selector(onGoogleMenuItemSelected))
        UIMenuController.shared.menuItems = [translateMenuItem, imagesMenuItem, googleMenuItem]
    }
    
    private func getSelectedText() -> String{
        if let range = self.selectedTextRange, let selectedText = self.text(in: range) {
            return selectedText
        }
        return ""
    }
    
    @objc func onTranslateMenuItemSelected() {
        menuItemsDelegate?.onTranslateMenuItemSelected(self, selectedText: getSelectedText())
    }
    
    @objc func onImageMenuItemSelected() {
        menuItemsDelegate?.onImageMenuItemSelected(self, selectedText: getSelectedText())
    }
    
    @objc func onGoogleMenuItemSelected() {
        menuItemsDelegate?.onGoogleMenuItemSelected(self, selectedText: getSelectedText())
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if UIMenuController.shared.menuItems?.first(where: {$0.action == action}) != nil {
            return true
        }
        
        return false
    }
}
