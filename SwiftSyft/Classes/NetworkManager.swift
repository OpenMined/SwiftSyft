import Foundation
import Combine

class NetworkManager {

    /// This class will run bandwith tests. The tests results will be later submitted to PyGrid.
    /// This allows PyGrid to properly select candidates for pooling
    private var endPoint:String
    private static let defaultFileSize:Int = 64000000 // 64Mb
    /// NetworkManager init
    ///  - important:
    ///    The download speed is computed by downloading 64Mb of data from PyGrid and measure the time until the download it's finished.
    ///    The upload speed is computed similar to the download speed. A 64Mb of data is uploaded to PyGrid and measure the time until the upload it's finished.
    ///         An extra random query string value is added to the request in order to prevent caching from the worker or from the server.
    ///  - parameters:
    ///  url: the base url of PyGrid
    ///  port: the port of PyGrid (It  can be nil if not applicable)
    ///  - returns:
    ///  An instance of NetworkManager class
    public init(url:String, port:Int?){
        guard let pyGridPort = port else {
            self.endPoint = url
            return
        }
        self.endPoint = "\(url):\(pyGridPort)/federated/speed-test"
    }
    // Download Service
    var downloadService = DownloadService()
    // Upload Service
    var uploadService = UploadService()
    /// This method will run the download test.
    ///  - important:
    ///   The download speed is computed in megabytes per second
    ///  - parameters:
    /// workerId
    ///  - returns:
    ///  A publisher that produces a Double value or fails if the host is unreachable.
    public func downloadSpeedTest(workerId:String) -> Future<Double, Error> {
        let url = buildUrl(workerId: workerId)
        return self.downloadService.downloadSpeedWithDefaultTimeOut(url: url)
   }
    /// This method will run the upload test.
    ///  - important:
    ///   The upload speed is computed in megabytes per second
    ///  - parameters:
    /// workerId
    ///  - returns:
    ///  A publisher that produces a Double value or fails if the host is unreachable.
    public func uploadSpeedTest(workerId:String) -> Future<Double, Error> {
        let url = buildUrl(workerId: workerId)
        return self.uploadService.startUploadtest(url, fileSize: NetworkManager.defaultFileSize)
    }
    /// This method will run download and upload speed test.
    ///  - important:
    ///   The download and upload speed is computed in megabytes per second
    ///  - parameters:
    /// workerId
    ///  - returns:
    ///  A publisher that produces a Double value or fails if the host is unreachable.
    public func speedTest(workerId:String) -> Publishers.Zip<Future<Double, Error>, Future<Double, Error>>{
        let url = buildUrl(workerId: workerId)
        return Publishers.Zip(self.downloadService.downloadSpeedWithDefaultTimeOut(url: url),
                        self.uploadService.startUploadtest(url, fileSize: NetworkManager.defaultFileSize)
                        )
    }
    private func buildUrl(workerId: String) -> URL {
        let queryItems = [URLQueryItem(name: "random", value: randomString(length: 30)), URLQueryItem(name: "worker_id", value: workerId)]
        var urlComponents = URLComponents(string: self.endPoint)!
        urlComponents.queryItems = queryItems
        return urlComponents.url!
    }
    private func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map { _ in
            letters.randomElement()!
      })
    }
}
