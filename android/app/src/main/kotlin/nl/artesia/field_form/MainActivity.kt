package nl.artesia.field_form

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.apache.commons.net.ftp.FTP
import org.apache.commons.net.ftp.FTPClient
import org.apache.commons.net.ftp.FTPFile
import org.apache.commons.net.ftp.FTPReply
import org.apache.commons.net.ftp.FTPSClient
import org.apache.commons.net.util.TrustManagerUtils
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.ConnectException
import java.net.SocketException
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import javax.net.ssl.SSLException
import java.time.Duration
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity: FlutterActivity() {
	private val channelName = "nl.artesia.field_form/native_ftp"
	private val logTag = "FieldFormNativeFtp"
	private val mainHandler = Handler(Looper.getMainLooper())
	private val executor: ExecutorService = Executors.newSingleThreadExecutor()
	private val sessions = ConcurrentHashMap<String, NativeFtpSession>()

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				executor.execute {
					handleCall(call, result)
				}
			}
	}

	override fun onDestroy() {
		sessions.values.forEach { session ->
			runCatching {
				if (session.client.isConnected) {
					session.client.logout()
					session.client.disconnect()
				}
			}
		}
		sessions.clear()
		executor.shutdownNow()
		super.onDestroy()
	}

	private fun success(result: MethodChannel.Result, value: Any?) {
		mainHandler.post { result.success(value) }
	}

	private fun error(result: MethodChannel.Result, code: String, message: String, details: Any? = null) {
		mainHandler.post { result.error(code, message, details) }
	}

	private fun handleCall(call: MethodCall, result: MethodChannel.Result) {
		try {
			when (call.method) {
				"connect" -> connect(call, result)
				"list" -> list(call, result)
				"upload" -> upload(call, result)
				"download" -> download(call, result)
				"disconnect" -> disconnect(call, result)
				"changeDirectory" -> changeDirectory(call, result)
				else -> mainHandler.post { result.notImplemented() }
			}
		} catch (e: Exception) {
			val mapped = mapNativeFtpException(e)
			error(result, mapped.code, mapped.message, mapped.details)
		}
	}

	private fun mapNativeFtpException(e: Exception, detailsOverride: Any? = null): NativeFtpMappedError {
		val root = generateSequence<Throwable>(e) { it.cause }.last()
		val defaultDetails = detailsOverride ?: root::class.java.simpleName
		return when (root) {
			is UnknownHostException -> NativeFtpMappedError(
				code = "unknown_host",
				message = "Unable to resolve FTP host: ${root.message ?: "unknown"}",
				details = defaultDetails,
			)
			is SocketTimeoutException -> NativeFtpMappedError(
				code = "timeout",
				message = "FTP connection timed out",
				details = defaultDetails,
			)
			is ConnectException -> NativeFtpMappedError(
				code = "connect_failed",
				message = root.message ?: "Unable to connect to FTP server",
				details = defaultDetails,
			)
			is SSLException -> {
				val msg = root.message ?: ""
				val code = if (msg.contains("cert", ignoreCase = true) || msg.contains("trust", ignoreCase = true) || msg.contains("validate", ignoreCase = true)) {
					"tls_cert_error"
				} else {
					"tls_error"
				}
				NativeFtpMappedError(
					code = code,
					message = root.message ?: "Failed to establish secure FTP connection",
					details = defaultDetails,
				)
			}
			is SocketException -> NativeFtpMappedError(
				code = "network_error",
				message = root.message ?: "Network error during FTP operation",
				details = defaultDetails,
			)
			else -> NativeFtpMappedError(
				code = "native_ftp_error",
				message = root.message ?: e.message ?: "Unknown native FTP error",
				details = detailsOverride ?: root::class.java.name,
			)
		}
	}

	private fun connect(call: MethodCall, result: MethodChannel.Result) {
		val host = call.argument<String>("host")?.trim().orEmpty()
		val username = call.argument<String>("username") ?: ""
		val password = call.argument<String>("password") ?: ""
		val useFtps = call.argument<Boolean>("useFtps") ?: false
		val useImplicitFtps = call.argument<Boolean>("useImplicitFtps") ?: false
		val acceptAnyCertificate = call.argument<Boolean>("acceptAnyCertificate") ?: false
		val timeoutSeconds = call.argument<Int>("timeout") ?: 5
		val initialPath = normalizePath(call.argument<String>("path") ?: "")
		val port = call.argument<Int>("port") ?: when {
			useImplicitFtps -> 990
			useFtps -> 21
			else -> 21
		}
		val diagnostics = NativeFtpConnectDiagnostics(
			host = host,
			port = port,
			useFtps = useFtps,
			useImplicitFtps = useImplicitFtps,
			acceptAnyCertificate = acceptAnyCertificate,
			timeoutSeconds = timeoutSeconds,
		)

		if (host.isEmpty()) {
			error(result, "invalid_argument", "FTP host is empty")
			return
		}

		val client: FTPClient = when {
			useImplicitFtps -> FTPSClient("TLS", true)
			useFtps -> FTPSClient("TLS", false)
			else -> FTPClient()
		}

		if (client is FTPSClient && acceptAnyCertificate) {
			(client as FTPSClient).setTrustManager(org.apache.commons.net.util.TrustManagerUtils.getAcceptAllTrustManager())
		}

		try {
			client.connectTimeout = timeoutSeconds * 1000
			client.defaultTimeout = timeoutSeconds * 1000
			client.dataTimeout = Duration.ofSeconds(timeoutSeconds.toLong())

			diagnostics.step = "connect"
			client.connect(host, port)

			diagnostics.step = "check_reply"
			val replyCode = client.replyCode
			if (!FTPReply.isPositiveCompletion(replyCode)) {
				runCatching { client.disconnect() }
				error(result, "connect_failed", "FTP server rejected connection (code $replyCode)")
				return
			}

			diagnostics.step = "login"
			if (!client.login(username, password)) {
				runCatching { client.disconnect() }
				error(result, "auth_failed", "FTP authentication failed")
				return
			}

			if (client is FTPSClient) {
				diagnostics.step = "ftps_protection"
				runCatching { client.execPBSZ(0) }
				runCatching { client.execPROT("P") }
			}

			diagnostics.step = "passive_mode"
			client.enterLocalPassiveMode()
			diagnostics.step = "set_binary_type"
			client.setFileType(FTP.BINARY_FILE_TYPE)

			if (initialPath.isNotEmpty()) {
				diagnostics.step = "change_directory"
				if (!client.changeWorkingDirectory(initialPath)) {
					runCatching {
						client.logout()
						client.disconnect()
					}
					error(result, "path_not_found", "Unable to change to FTP path: $initialPath")
					return
				}
			}

			diagnostics.step = "connected"
			val id = UUID.randomUUID().toString()
			sessions[id] = NativeFtpSession(id = id, client = client, currentPath = initialPath)
			success(result, id)
		} catch (e: Exception) {
			runCatching {
				if (client.isConnected) {
					client.logout()
					client.disconnect()
				}
			}
			val safeDetails = diagnostics.buildFailureDetails(e)
			Log.w(logTag, "FTP connect failed: $safeDetails")
			val mapped = mapNativeFtpException(e, safeDetails)
			error(result, mapped.code, mapped.message, mapped.details)
		}
	}

	private fun changeDirectory(call: MethodCall, result: MethodChannel.Result) {
		val session = requireSession(call, result) ?: return
		val path = normalizePath(call.argument<String>("path") ?: "")
		if (path.isEmpty()) {
			success(result, true)
			return
		}
		val absolutePath = resolvePath(session.currentPath, path)
		val ok = session.client.changeWorkingDirectory(absolutePath)
		if (ok) {
			session.currentPath = absolutePath
			success(result, true)
		} else {
			error(result, "path_not_found", "Unable to change directory to $absolutePath")
		}
	}

	private fun list(call: MethodCall, result: MethodChannel.Result) {
		val session = requireSession(call, result) ?: return
		val pathArg = call.argument<String>("path")
		val effectivePath = resolvePath(session.currentPath, pathArg ?: "")
		val names = mutableListOf<String>()

		val fileNames = session.client.listNames(effectivePath)
		if (fileNames != null) {
			fileNames.forEach { entry ->
				val cleaned = entry.substringAfterLast('/')
				if (cleaned.isNotBlank() && cleaned != "." && cleaned != "..") {
					names.add(cleaned)
				}
			}
			success(result, names)
			return
		}

		val files: Array<FTPFile> = session.client.listFiles(effectivePath)
		files.forEach { ftpFile ->
			val name = ftpFile.name
			if (name.isNotBlank() && name != "." && name != "..") {
				names.add(name)
			}
		}
		success(result, names)
	}

	private fun upload(call: MethodCall, result: MethodChannel.Result) {
		val session = requireSession(call, result) ?: return
		val localPath = call.argument<String>("localPath") ?: ""
		val remoteName = call.argument<String>("remoteFileName") ?: ""
		if (localPath.isEmpty() || remoteName.isEmpty()) {
			error(result, "invalid_argument", "localPath and remoteFileName are required")
			return
		}
		val remotePath = resolvePath(session.currentPath, remoteName)
		FileInputStream(localPath).use { stream ->
			val ok = session.client.storeFile(remotePath, stream)
			if (!ok) {
				error(result, "upload_failed", "FTP upload failed: $remotePath")
				return
			}
		}
		success(result, true)
	}

	private fun download(call: MethodCall, result: MethodChannel.Result) {
		val session = requireSession(call, result) ?: return
		val localPath = call.argument<String>("localPath") ?: ""
		val remoteName = call.argument<String>("remoteFileName") ?: ""
		if (localPath.isEmpty() || remoteName.isEmpty()) {
			error(result, "invalid_argument", "localPath and remoteFileName are required")
			return
		}
		val remotePath = resolvePath(session.currentPath, remoteName)
		FileOutputStream(localPath).use { stream ->
			val ok = session.client.retrieveFile(remotePath, stream)
			if (!ok) {
				error(result, "download_failed", "FTP download failed: $remotePath")
				return
			}
		}
		success(result, true)
	}

	private fun disconnect(call: MethodCall, result: MethodChannel.Result) {
		val sessionId = call.argument<String>("sessionId") ?: ""
		if (sessionId.isEmpty()) {
			success(result, true)
			return
		}
		val session = sessions.remove(sessionId)
		if (session != null) {
			runCatching {
				if (session.client.isConnected) {
					session.client.logout()
					session.client.disconnect()
				}
			}
		}
		success(result, true)
	}

	private fun requireSession(call: MethodCall, result: MethodChannel.Result): NativeFtpSession? {
		val id = call.argument<String>("sessionId") ?: ""
		if (id.isEmpty()) {
			error(result, "invalid_argument", "sessionId is required")
			return null
		}
		val session = sessions[id]
		if (session == null) {
			error(result, "session_not_found", "No FTP session found for id $id")
			return null
		}
		return session
	}

	private fun normalizePath(path: String): String {
		var value = path.trim().replace('\\', '/')
		while (value.contains("//")) {
			value = value.replace("//", "/")
		}
		if (value == "/") {
			return ""
		}
		return value.trim('/')
	}

	private fun resolvePath(basePath: String, inputPath: String): String {
		val normalizedInput = inputPath.trim().replace('\\', '/')
		if (normalizedInput.isEmpty()) {
			return if (basePath.isEmpty()) "/" else "/${normalizePath(basePath)}"
		}
		if (normalizedInput.startsWith("/")) {
			return "/${normalizePath(normalizedInput)}"
		}
		val base = normalizePath(basePath)
		val suffix = normalizePath(normalizedInput)
		return if (base.isEmpty()) "/$suffix" else "/$base/$suffix"
	}
}

data class NativeFtpSession(
	val id: String,
	val client: FTPClient,
	var currentPath: String,
)

data class NativeFtpMappedError(
	val code: String,
	val message: String,
	val details: Any? = null,
)

private data class NativeFtpConnectDiagnostics(
	val host: String,
	val port: Int,
	val useFtps: Boolean,
	val useImplicitFtps: Boolean,
	val acceptAnyCertificate: Boolean,
	val timeoutSeconds: Int,
	val startedAtMs: Long = System.currentTimeMillis(),
	var step: String = "init",
) {
	fun buildFailureDetails(error: Exception): Map<String, Any> {
		val root = generateSequence<Throwable>(error) { it.cause }.last()
		val now = System.currentTimeMillis()
		return mapOf(
			"operation" to "ftp_connect",
			"timestampEpochMs" to now,
			"elapsedMs" to (now - startedAtMs),
			"host" to host,
			"port" to port,
			"useFtps" to useFtps,
			"useImplicitFtps" to useImplicitFtps,
			"acceptAnyCertificate" to acceptAnyCertificate,
			"timeoutSeconds" to timeoutSeconds,
			"step" to step,
			"errorClass" to error::class.java.simpleName,
			"errorMessage" to (error.message ?: ""),
			"rootErrorClass" to root::class.java.simpleName,
			"rootErrorMessage" to (root.message ?: ""),
		)
	}
}
