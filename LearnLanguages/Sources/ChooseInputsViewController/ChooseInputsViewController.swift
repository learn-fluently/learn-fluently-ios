//
//  ChooseInputsViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 12/23/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//
import AVFoundation
import AVKit

class ChooseInputsViewController: BaseViewController, NibBasedViewController {
    
    @IBOutlet weak var subtitle: UILabel!
    
    var player: AVPlayer!
    var playerController: AVPlayerViewController!
    var subtitles: Subtitles!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addPlayerAndPlay()
        addSubtitle()
        
        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.5, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil) { [weak self] (time:CMTime) in
            guard let strongSelf = self, let titles = strongSelf.subtitles.titles else {
                return
            }
            let currentValue = TimeInterval(time.value) / 1000000000
            let text = titles.first(where: { currentValue < $0.end! && currentValue > $0.start!})
            strongSelf.subtitle.text = text?.texts?.joined(separator: "\n")
        }
    }
    
    func addPlayerAndPlay(){
        let url: URL = Bundle.main.url(forResource: "Friends0301", withExtension: "mp4")!
        
        let avAsset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: avAsset)
        player = AVPlayer(playerItem: playerItem)
        playerController = AVPlayerViewController()
        playerController?.player = player
        playerController?.view.frame = CGRect(x:0, y:0, width: 200, height: 200)
        
        guard let videoView = playerController?.view else { return }
        view.addSubview(videoView)
        player?.play()
    }
    
    func addSubtitle(){
        
        let exampleSubtitlesUrl = Bundle.main.url(forResource: "Friends0301", withExtension: "srt")
        subtitles = Subtitles(fileUrl: exampleSubtitlesUrl!)
    }
}
