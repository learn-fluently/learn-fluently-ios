//
//  DarkCrossButton.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 1/25/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import SnapKit

class DarkCrossButton: UIButton {
    
    // MARK: Life Cyle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height/3.7
    }
    
    // MARK: Private functions
    
    private func commonInit() {
        layer.masksToBounds = true
        backgroundColor = .clear
        
        //add blur view
        let containerEffect = UIBlurEffect(style: .dark)
        let containerView = UIVisualEffectView(effect: containerEffect)
        containerView.isUserInteractionEnabled = false
        
        let vibrancy = UIVibrancyEffect(blurEffect: containerEffect)
        let vibrancyView = UIVisualEffectView(effect: vibrancy)
        containerView.contentView.addSubview(vibrancyView)
        
        insertSubview(containerView, belowSubview: imageView!)
        
        containerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalToSuperview()
        }
        vibrancyView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalToSuperview()
        }
    }
    
}
