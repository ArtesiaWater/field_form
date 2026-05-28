import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "nl.artesia.field_form/native_ftp"
  private var ftpSessions: [String: NativeFtpSession] = [:]
  private let ftpQueue = DispatchQueue(label: "nl.artesia.field_form.native_ftp", qos: .userInitiated)

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("${mapsApiKey}")
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        self?.ftpQueue.async {
          self?.handleFtpCall(call: call, result: result)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleFtpCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "connect":
        try connect(call: call, result: result)
      case "list":
        try list(call: call, result: result)
      case "upload":
        try upload(call: call, result: result)
      case "download":
        try download(call: call, result: result)
      case "disconnect":
        try disconnect(call: call, result: result)
      case "changeDirectory":
        try changeDirectory(call: call, result: result)
      default:
        DispatchQueue.main.async {
          result(FlutterMethodNotImplemented)
        }
      }
    } catch {
      sendError(result: result, code: "native_ftp_error", message: error.localizedDescription)
    }
  }

  private func connect(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
    guard let args = call.arguments as? [String: Any] else {
      sendError(result: result, code: "invalid_argument", message: "Missing connect arguments")
      return
    }
    let host = (args["host"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let username = args["username"] as? String ?? ""
    let password = args["password"] as? String ?? ""
    let useFtps = args["useFtps"] as? Bool ?? false
    let useImplicitFtps = args["useImplicitFtps"] as? Bool ?? false
    let timeout = args["timeout"] as? Int ?? 5
    let path = normalizePath(args["path"] as? String ?? "")

    if host.isEmpty {
      sendError(result: result, code: "invalid_argument", message: "FTP host is empty")
      return
    }

    let scheme = (useFtps || useImplicitFtps) ? "ftps" : "ftp"
    let sessionId = UUID().uuidString
    let ftpSession = NativeFtpSession(
      id: sessionId,
      host: host,
      username: username,
      password: password,
      scheme: scheme,
      timeout: timeout,
      currentPath: path
    )

    do {
      _ = try requestData(session: ftpSession, path: path)
      ftpSessions[sessionId] = ftpSession
      sendSuccess(result: result, value: sessionId)
    } catch {
      sendError(result: result, code: "connect_failed", message: error.localizedDescription)
    }
  }

  private func changeDirectory(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
    guard let args = call.arguments as? [String: Any],
          let sessionId = args["sessionId"] as? String,
          var session = ftpSessions[sessionId] else {
      sendError(result: result, code: "session_not_found", message: "No FTP session found")
      return
    }

    let requestedPath = normalizePath(args["path"] as? String ?? "")
    if requestedPath.isEmpty {
      sendSuccess(result: result, value: true)
      return
    }

    let newPath = resolvePath(basePath: session.currentPath, inputPath: requestedPath)
    do {
      _ = try requestData(session: session, path: newPath)
      session.currentPath = normalizePath(newPath)
      ftpSessions[sessionId] = session
      sendSuccess(result: result, value: true)
    } catch {
      sendError(result: result, code: "path_not_found", message: error.localizedDescription)
    }
  }

  private func list(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
    guard let args = call.arguments as? [String: Any],
          let sessionId = args["sessionId"] as? String,
          let session = ftpSessions[sessionId] else {
      sendError(result: result, code: "session_not_found", message: "No FTP session found")
      return
    }

    let pathArg = args["path"] as? String ?? ""
    let effectivePath = resolvePath(basePath: session.currentPath, inputPath: pathArg)

    do {
      let data = try requestData(session: session, path: effectivePath)
      let listing = parseListing(data: data)
      sendSuccess(result: result, value: listing)
    } catch {
      sendError(result: result, code: "list_failed", message: error.localizedDescription)
    }
  }

  private func upload(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
    guard let args = call.arguments as? [String: Any],
          let sessionId = args["sessionId"] as? String,
          let session = ftpSessions[sessionId] else {
      sendError(result: result, code: "session_not_found", message: "No FTP session found")
      return
    }

    let localPath = args["localPath"] as? String ?? ""
    let remoteFileName = args["remoteFileName"] as? String ?? ""
    if localPath.isEmpty || remoteFileName.isEmpty {
      sendError(result: result, code: "invalid_argument", message: "localPath and remoteFileName are required")
      return
    }

    let remotePath = resolvePath(basePath: session.currentPath, inputPath: remoteFileName)
    do {
      try uploadFile(session: session, localPath: localPath, remotePath: remotePath)
      sendSuccess(result: result, value: true)
    } catch {
      sendError(result: result, code: "upload_failed", message: error.localizedDescription)
    }
  }

  private func download(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
    guard let args = call.arguments as? [String: Any],
          let sessionId = args["sessionId"] as? String,
          let session = ftpSessions[sessionId] else {
      sendError(result: result, code: "session_not_found", message: "No FTP session found")
      return
    }

    let localPath = args["localPath"] as? String ?? ""
    let remoteFileName = args["remoteFileName"] as? String ?? ""
    if localPath.isEmpty || remoteFileName.isEmpty {
      sendError(result: result, code: "invalid_argument", message: "localPath and remoteFileName are required")
      return
    }

    let remotePath = resolvePath(basePath: session.currentPath, inputPath: remoteFileName)
    do {
      try downloadFile(session: session, remotePath: remotePath, localPath: localPath)
      sendSuccess(result: result, value: true)
    } catch {
      sendError(result: result, code: "download_failed", message: error.localizedDescription)
    }
  }

  private func disconnect(call: FlutterMethodCall, result: @escaping FlutterResult) throws {
    guard let args = call.arguments as? [String: Any],
          let sessionId = args["sessionId"] as? String else {
      sendSuccess(result: result, value: true)
      return
    }
    ftpSessions.removeValue(forKey: sessionId)
    sendSuccess(result: result, value: true)
  }

  private func requestData(session: NativeFtpSession, path: String) throws -> Data {
    guard let url = makeUrl(session: session, path: path) else {
      throw NativeFtpError.invalidUrl
    }
    var request = URLRequest(url: url)
    request.timeoutInterval = TimeInterval(session.timeout)

    let semaphore = DispatchSemaphore(value: 0)
    var responseData: Data?
    var responseError: Error?

    let task = URLSession.shared.dataTask(with: request) { data, _, error in
      responseData = data
      responseError = error
      semaphore.signal()
    }
    task.resume()
    semaphore.wait()

    if let responseError {
      throw responseError
    }
    return responseData ?? Data()
  }

  private func uploadFile(session: NativeFtpSession, localPath: String, remotePath: String) throws {
    guard let url = makeUrl(session: session, path: remotePath) else {
      throw NativeFtpError.invalidUrl
    }

    let semaphore = DispatchSemaphore(value: 0)
    var uploadError: Error?
    var responseCode: Int?
    let localUrl = URL(fileURLWithPath: localPath)
    var request = URLRequest(url: url)
    request.timeoutInterval = TimeInterval(session.timeout)
    request.httpMethod = "PUT"

    let task = URLSession.shared.uploadTask(with: request, fromFile: localUrl) { _, response, error in
      uploadError = error
      responseCode = (response as? HTTPURLResponse)?.statusCode
      semaphore.signal()
    }
    task.resume()
    semaphore.wait()

    if let uploadError {
      throw uploadError
    }
    if let responseCode, !(200..<400).contains(responseCode) {
      throw NativeFtpError.serverError(code: responseCode)
    }
  }

  private func downloadFile(session: NativeFtpSession, remotePath: String, localPath: String) throws {
    guard let url = makeUrl(session: session, path: remotePath) else {
      throw NativeFtpError.invalidUrl
    }

    let semaphore = DispatchSemaphore(value: 0)
    var downloadError: Error?
    var tempUrl: URL?

    let task = URLSession.shared.downloadTask(with: url) { downloadedUrl, _, error in
      tempUrl = downloadedUrl
      downloadError = error
      semaphore.signal()
    }
    task.resume()
    semaphore.wait()

    if let downloadError {
      throw downloadError
    }
    guard let tempUrl else {
      throw NativeFtpError.emptyData
    }

    let localUrl = URL(fileURLWithPath: localPath)
    let dir = localUrl.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    if FileManager.default.fileExists(atPath: localUrl.path) {
      try FileManager.default.removeItem(at: localUrl)
    }
    try FileManager.default.moveItem(at: tempUrl, to: localUrl)
  }

  private func makeUrl(session: NativeFtpSession, path: String) -> URL? {
    let resolvedPath = normalizePath(path)
    let prefix = resolvedPath.isEmpty ? "" : "/\(resolvedPath)"
    var components = URLComponents()
    components.scheme = session.scheme
    components.host = session.host
    components.path = prefix
    if !session.username.isEmpty {
      components.user = session.username
    }
    if !session.password.isEmpty {
      components.password = session.password
    }
    return components.url
  }

  private func parseListing(data: Data) -> [String] {
    guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
      return []
    }
    let lines = text.components(separatedBy: .newlines)
    var names = Set<String>()
    for rawLine in lines {
      let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
      if line.isEmpty { continue }
      if line == "." || line == ".." { continue }
      if let last = line.split(separator: " ").last {
        let candidate = String(last).trimmingCharacters(in: .whitespacesAndNewlines)
        if !candidate.isEmpty && candidate != "." && candidate != ".." {
          names.insert(candidate)
        }
      } else {
        names.insert(line)
      }
    }
    return Array(names)
  }

  private func normalizePath(_ path: String) -> String {
    var value = path.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\\\", with: "/")
    while value.contains("//") {
      value = value.replacingOccurrences(of: "//", with: "/")
    }
    if value == "/" { return "" }
    return value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
  }

  private func resolvePath(basePath: String, inputPath: String) -> String {
    let trimmedInput = inputPath.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedInput.isEmpty {
      return normalizePath(basePath)
    }
    if trimmedInput.hasPrefix("/") {
      return normalizePath(trimmedInput)
    }
    let base = normalizePath(basePath)
    let suffix = normalizePath(trimmedInput)
    if base.isEmpty { return suffix }
    return "\(base)/\(suffix)"
  }

  private func sendSuccess(result: @escaping FlutterResult, value: Any?) {
    DispatchQueue.main.async {
      result(value)
    }
  }

  private func sendError(result: @escaping FlutterResult, code: String, message: String) {
    DispatchQueue.main.async {
      result(FlutterError(code: code, message: message, details: nil))
    }
  }
}

private struct NativeFtpSession {
  let id: String
  let host: String
  let username: String
  let password: String
  let scheme: String
  let timeout: Int
  var currentPath: String
}

private enum NativeFtpError: Error {
  case invalidUrl
  case emptyData
  case serverError(code: Int)
}

extension NativeFtpError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .invalidUrl:
      return "Unable to construct FTP URL"
    case .emptyData:
      return "No data received from FTP server"
    case .serverError(let code):
      return "Server responded with status code \(code)"
    }
  }
}
