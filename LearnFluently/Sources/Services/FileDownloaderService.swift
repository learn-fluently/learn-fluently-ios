//
//  FileDownloader.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 2/16/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class FileDownloader: NSObject {

    // MARK: Properties

    private var filePath: URL?
    private var url: URL?
    private var resumeData: Data?
    private var taskStartedAt: Date?

    private var eventsPublishSubject: PublishSubject<DownloadUpdateEvent>!
    private var session: URLSession!
    private var currentTask: URLSessionDownloadTask?


    // MARK: Lifecycle

    override init() {
        super.init()
        self.resetSession()
    }


    // MARK: Functions

    func downloadFile(fromURL url: URL, toPath path: URL, subject: PublishSubject<DownloadUpdateEvent>? = nil) -> PublishSubject<DownloadUpdateEvent> {
        eventsPublishSubject = subject ?? PublishSubject<DownloadUpdateEvent>()
        filePath = path
        self.url = url
        resumeData = nil
        taskStartedAt = Date()
        currentTask = session.downloadTask(with: url)
        currentTask?.resume()
        return eventsPublishSubject
    }


    // MARK: Private functions

    private func resetSession() {
        self.session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    }

    private func resumeDownload() {
        self.resetSession()

        if let resumeData = self.resumeData {
            eventsPublishSubject.onNext(DownloadUpdateEvent.with(info: .DOWNLOADER_RESUMING))
            currentTask = session.downloadTask(withResumeData: resumeData)
            currentTask?.resume()
            self.resumeData = nil
        } else {
            eventsPublishSubject.onNext(DownloadUpdateEvent.with(info: .DOWNLOADER_RETRYING))
            _ = self.downloadFile(fromURL: self.url!, toPath: self.filePath!, subject: eventsPublishSubject)
        }
    }

    private func updateProgress(progress: Int, speed: Int) {
        eventsPublishSubject.onNext(
            DownloadUpdateEvent.with(
                progress: .init(progress: progress, speed: speed)
            )
        )
    }

    private func waitForNetworkConnection() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if Reachability.isConnectedToNetwork() {
                self?.resumeDownload()
            } else {
                self?.waitForNetworkConnection()
            }
        }
    }

}


extension FileDownloader: URLSessionDownloadDelegate {

    func urlSession(_: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        let now = Date()
        let timeDownloaded = now.timeIntervalSince(taskStartedAt!)
        let kbs = Int( floor( Float(totalBytesWritten) / 1_024.0 / Float(timeDownloaded) ) )
        updateProgress(progress: Int(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100.0), speed: kbs)
    }

    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard self.filePath != nil else {
            eventsPublishSubject.onError(Errors.Download.saving(.DOWNLOADER_ERROR_NO_DEST))
            return
        }

        eventsPublishSubject.onNext(DownloadUpdateEvent.with(info: .DOWNLOADER_MOVING_FILE))

        do {
            try? FileManager.default.removeItem(at: filePath!)
            try FileManager.default.moveItem(at: location, to: filePath!)
        } catch let error {
            eventsPublishSubject.onError(error)
        }
        eventsPublishSubject.onCompleted()
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            // No error.
            // Already handled in URLSession(session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingToURL location: URL)
            return
        }
        let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data

        if Reachability.isConnectedToNetwork() || resumeData == nil {
            eventsPublishSubject.onError(error)
        } else {
            self.resumeData = resumeData
            waitForNetworkConnection()
        }
    }

}
