//
//  FileDownloaderService.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/16/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class FileDownloaderService: NSObject {

    // MARK: Properties

    private var filePath: URL?
    private var url: URL?
    private var resumeData: Data?
    private var taskStartedAt: Date?

    private var eventsPublishSubject: PublishSubject<DownloadUpdateEvent>!
    private var session: URLSession!
    private var currentTask: URLSessionDownloadTask?


    // MARK: Life cycle

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
                progress: DownloadProgressData(progress: progress, speed: speed)
            )
        )
    }

}


extension FileDownloaderService: URLSessionDownloadDelegate {

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
            eventsPublishSubject.onError(DownloadError.savingError(.DOWNLOADER_ERROR_NO_DEST))
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

//        if !Reachability.isConnectedToNetwork() {
//            eventsPublishSubject.onNext(DownloadUpdateEvent.with(info: .DOWNLOADER_CONNECTION_WAITING))
//            repeat {
//                sleep(1)
//            } while !Reachability.isConnectedToNetwork()
//        }
//
//        self.resumeDownload()

        eventsPublishSubject.onError(error)

        guard let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data else {
            return
        }

        self.resumeData = resumeData
    }

}


extension FileDownloaderService {

    struct DownloadProgressData {

        // MARK: Properties

        let progress: Int
        let speed: Int
    }

    enum DownloadError: Error {

        // MARK: Cases

        case savingError(String)
    }


    enum DownloadUpdateEventType {

        // MARK: Cases

        case info
        case progress
    }


    struct DownloadUpdateEvent {

        // MARK: Static functions

        static func with(progress: DownloadProgressData) -> DownloadUpdateEvent {
            return DownloadUpdateEvent(type: .progress,
                                       messsage: nil,
                                       error: nil,
                                       progress: progress)
        }

        static func with(info: String) -> DownloadUpdateEvent {
            return DownloadUpdateEvent(type: .info,
                                       messsage: info,
                                       error: nil,
                                       progress: nil)
        }


        // MARK: Properties

        let type: DownloadUpdateEventType
        let messsage: String?
        let error: Error?
        let progress: DownloadProgressData?

    }

}
