//
//  PlayerViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import AVKit
import SnapKit
import RxCocoa
import RxSwift

protocol PlayerViewControllerDelegate: AnyObject {

    // MARK: Functions

    func onPlayingStateChanged(playerViewController: PlayerViewController)

    func onCloseButtonTouched(playerViewController: PlayerViewController)

}


protocol PlayerViewController {

    // MARK: Properties

    var url: URL? { get set }
    var playingDelegate: PlayerViewControllerDelegate? { get set }
    var showsControls: Bool { get set }

    var isPlaying: Bool { get }
    var playerTime: Double { get }
    var playerTimeObservable: Observable<Double> { get }


    // MARK: Functions

    func play()
    func pause()
    func togglePlaying()
    func seek(byDelta delta: Double)
    func seek(to time: Double)
}
