//
//  LAVPlayerViewController.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 3/22/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import AVKit
import SnapKit
import RxCocoa
import RxSwift

class LAVPlayerViewController: AVPlayerViewController, PlayerViewController {

    // MARK: Properties

    weak var playingDelegate: PlayerViewControllerDelegate?

    var showsControls: Bool {
        set { showsPlaybackControls = newValue }
        get { return showsPlaybackControls }
    }

    var isPlaying: Bool {
        return player?.timeControlStatus == .playing
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


    // MARK: Private properties

    private let playerTimeBehaviorRelay = BehaviorRelay<Double>(value: 0)

    private var closeButton: DarkCrossButton!

    private var keyValueObservations: [NSKeyValueObservation] = []


    // MARK: Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }

    private func commonInit() {
        setValue(false, forKey: "canHidePlaybackControls")
    }

    override func didMove(toParent parent: UIViewController?) {
        configureView()
        configureCloseButton()
        if parent == nil {
            onRemoveFromParent()
        }
    }

    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            onRemoveFromParent()
        }
    }

    private func onRemoveFromParent() {
        removeCloseButtonIfNeeded()
        keyValueObservations.forEach {
            $0.invalidate()
        }
        keyValueObservations = []
    }

    // MARK: Public functions

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func togglePlaying() {
        isPlaying ? player?.pause() : player?.play()
    }

    func seek(byDelta delta: Double) {
        guard let player = player else {
            return
        }
        let newTime = CMTimeGetSeconds(player.currentTime()) + delta
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
        let avAsset = AVURLAsset(url: url!)
        let playerItem = AVPlayerItem(asset: avAsset)
        player = AVPlayer(playerItem: playerItem)
        let observer = player?.observe(\.timeControlStatus) { [weak playingDelegate] _, _ in
            playingDelegate?.onPlayingStateChanged(playerViewController: self)
        }
        if let observer = observer {
            keyValueObservations.append(observer)
        }
        addPlayerTimeListener()
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
        guard let player = player,
            let duration = player.currentItem?.duration else {
                return
        }
        var newTime = time
        if newTime < 0 {
            newTime = 0
        }
        if newTime < CMTimeGetSeconds(duration) {
            let time: CMTime = CMTimeMakeWithSeconds(newTime, preferredTimescale: Int32(NSEC_PER_SEC))
            player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }

    private func addPlayerTimeListener( ) {
        let interval = CMTimeMake(value: 1, timescale: 100)
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            let currentValue = Double(time.value) / Double(time.timescale)
            self?.playerTimeBehaviorRelay.accept(currentValue)
        }
    }

    @objc private func onCloseButtonTouched() {
        playingDelegate?.onCloseButtonTouched(playerViewController: self)
    }

}
