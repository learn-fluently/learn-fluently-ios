//
//  VLCPlayerViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 3/22/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import AVKit
import SnapKit
import RxCocoa
import RxSwift

class VLCPlayerViewController: UIViewController, PlayerViewController {

    // MARK: Properties

    weak var playingDelegate: PlayerViewControllerDelegate?

    var isPlaying: Bool {
        return mediaPlayer.isPlaying
    }

    var playerTime: Double {
        return playerTimeBehaviorRelay.value
    }

    var playerTimeObservable: Observable<Double> {
        return playerTimeBehaviorRelay.asObservable()
    }

    var url: URL? = nil {
        didSet {
            setupPlayer(url: url)
        }
    }

    var showsControls: Bool {
        set {  }
        get { return false }
    }


    // MARK: Private properties

    private let mediaPlayer = VLCMediaPlayer()

    private let playerTimeBehaviorRelay = BehaviorRelay<Double>(value: 0)

    private var closeButton: DarkCrossButton!


    // MARK: Life cycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }

    private func commonInit() {
        mediaPlayer.delegate = self
        mediaPlayer.drawable = self.view
    }

    override func didMove(toParent parent: UIViewController?) {
        configureView()
        configureCloseButton()
    }


    // MARK: Public functions

    func play() {
        mediaPlayer.play()
    }

    func pause() {
        mediaPlayer.pause()
    }

    func togglePlaying() {
        isPlaying ? pause() : play()
    }

    func seek(byDelta delta: Double) {
        let newTime = playerTime + delta
        seek(to: newTime)
    }

    func seek(to time: Double) {
        adjustAndSeek(to: time)
    }


    // MARK: - Event handlers

    @IBAction private func closeButtonTouched() {
        dismiss(animated: true, completion: nil)
    }


    // MARK: Private functions

    private func setupPlayer(url: URL?) {
        guard url != nil else {
            return
        }
        let media = VLCMedia(url: url!)
        mediaPlayer.media = media
    }

    private func configureView() {
        guard view.superview != nil else {
            return
        }
        view.snp.makeConstraints {
            $0.size.equalToSuperview()
            $0.center.equalToSuperview()
        }
    }

    private func removeCloseButtonIfNeeded() {
        closeButton.removeFromSuperview()
    }

    private func configureCloseButton() {
        guard view.superview != nil else {
            return
        }
        closeButton = DarkCrossButton()
        view.superview?.addSubview(closeButton)
        closeButton.snp.makeConstraints {
            $0.width.equalTo(45)
            $0.height.equalTo(31)
            $0.rightMargin.equalToSuperview().inset(57)
            $0.topMargin.equalToSuperview().inset(6)
        }
        closeButton.addTarget(self, action: #selector(onCloseButtonTouched), for: .touchUpInside)
    }

    private func adjustAndSeek(to time: Double) {
        var newTime = time * 1_000
        if newTime < 0 {
            newTime = 0
        }
        //let duration = (-mediaPlayer.remainingTime.value.doubleValue + mediaPlayer.time.value.doubleValue)
        if mediaPlayer.isSeekable {
            mediaPlayer.time = VLCTime(number: NSNumber(value: time))
        }
    }

    @objc private func onCloseButtonTouched() {
        playingDelegate?.onCloseButtonTouched(playerViewController: self)
    }

}


extension VLCPlayerViewController: VLCMediaPlayerDelegate {

    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        playingDelegate?.onPlayingStateChanged(playerViewController: self)
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        playerTimeBehaviorRelay.accept(mediaPlayer.time.value.doubleValue / 1_000)
    }
}
