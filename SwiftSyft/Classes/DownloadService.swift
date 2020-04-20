import Foundation
import Combine

class DownloadService: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    typealias SpeedTestCompletionHandler = (_ mbps: Double? , _ error: Error?) -> Void
    var speedTestCompletionBlock: SpeedTestCompletionHandler?
    var startTime: CFAbsoluteTime!
    var stopTime: CFAbsoluteTime!
    var bytesReceived: Int!
    private static let defaultTimeout: Double = 5
    public override init() {
        super.init()
    }
    public func downloadSpeedWithDefaultTimeOut(url:URL) -> Future<Double, Error> {
        let downloadFuture = Future<Double, Error> { promise in
            self.testDownloadSpeedWithTimout(url:url, timeout: DownloadService.defaultTimeout) { (speed, error) in
                guard let speedMBPS = speed else {
                    promise(.failure(error!))
                    return
                }
                promise(.success(speedMBPS))
            }
        }
        return downloadFuture
    }
    func testDownloadSpeedWithTimout(url:URL, timeout: TimeInterval, withCompletionBlock: @escaping SpeedTestCompletionHandler) {
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = startTime
        bytesReceived = 0
        speedTestCompletionBlock = withCompletionBlock
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession.init(configuration: configuration, delegate: self, delegateQueue: nil)
        session.dataTask(with: url).resume()
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bytesReceived! += data.count
        stopTime = CFAbsoluteTimeGetCurrent()
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let elapsed = stopTime - startTime
        if let tempError = error as NSError?, tempError.domain != NSURLErrorDomain && tempError.code != NSURLErrorTimedOut && elapsed == 0 {
            speedTestCompletionBlock?(nil, error)
            return
        }
        let speed = elapsed != 0 ? Double(bytesReceived) / elapsed / 1024.0 / 1024.0 : -1
        speedTestCompletionBlock?(speed, nil)
    }    
}
