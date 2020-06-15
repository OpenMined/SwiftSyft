import Foundation
import Combine

class UploadService: NSObject, URLSessionDataDelegate, URLSessionTaskDelegate {
    typealias UploadServiceCompletionHandler = (_ mbps: Double? , _ error: Error?) -> Void
    var uploadCompletionBlock : UploadServiceCompletionHandler?
    var fileSize:Int = 0
    private static let defaultTimeout: Double = 60
    private var startTime: CFAbsoluteTime!
    private var stopTime: CFAbsoluteTime!
    func startUploadtest(_ url: URL, fileSize: Int) -> Future<Double, Error> {
        let uploadFuture = Future<Double, Error> { promise in
            self.uploadTest(url, fileSize: fileSize, timeout: UploadService.defaultTimeout, withCompletionBlock: {(speed, error) in
                guard let speedMBPS = speed else {
                    promise(.failure(error!))
                    return
                }
                promise(.success(speedMBPS))
            })
        }
        return uploadFuture
    }
    func uploadTest(_ url: URL, fileSize: Int, timeout: TimeInterval, withCompletionBlock: @escaping UploadServiceCompletionHandler ) {
        self.uploadCompletionBlock = withCompletionBlock
        var request = URLRequest(url: url)
        let boundary = "Boundary-\(UUID().uuidString)"
        self.fileSize = fileSize
        let httpBody = NSMutableData()
        startTime = CFAbsoluteTimeGetCurrent()
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        httpBody.append(convertFileData(fieldName: "file",
                                        fileName: "swiftsyt_speedtest",
                                        mimeType: "application/octet-stream",
                                        fileData: Data(count: fileSize),
                                        using: boundary))
        httpBody.appendString("--\(boundary)--")
        request.httpBody = httpBody as Data
        URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: self, delegateQueue: OperationQueue.main)
            .dataTask(with: request)
            .resume()
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        stopTime = CFAbsoluteTimeGetCurrent()
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        // This is for unit tests where the stub returns status code 200 immediately
        // and will not trigger `urlsession(session:task:didSendBodyData)` anymore.
        if stopTime == nil {
            stopTime = CFAbsoluteTimeGetCurrent()
        }

        let elapsed = stopTime - startTime
        if let tempError = error as NSError?, tempError.domain != NSURLErrorDomain && tempError.code != NSURLErrorTimedOut && elapsed == 0 {
            uploadCompletionBlock?(nil, error)
            return
        }
        let speed = elapsed != 0 ? Double(fileSize) / elapsed / 1024.0 / 1024.0 : -1
        uploadCompletionBlock?(speed, nil)
    }
    // Based on the examples from:
    // https://www.donnywals.com/uploading-images-and-forms-to-a-server-using-urlsession/
    func convertFormField(named name: String, value: String, using boundary: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"
        return fieldString
    }
    func convertFileData(fieldName: String, fileName: String, mimeType: String, fileData: Data, using boundary: String) -> Data {
        let data = NSMutableData()        
        data.appendString("--\(boundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        data.appendString("Content-Type: \(mimeType)\r\n\r\n")
        data.append(fileData)
        data.appendString("\r\n")
        return data as Data
    }
}
extension NSMutableData {
    func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
