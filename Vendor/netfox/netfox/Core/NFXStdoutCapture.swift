//
//  NFXStdoutCapture.swift
//  netfox
//
//  Yerel fork eklentisi — stdout/stderr yakalama.
//

import Foundation

/// `stdout` ve `stderr`'i bir boruya yönlendirip okunan satırları
/// `NFXLogStore`'a aktarır.
///
/// Orijinal tanıtıcılar `dup` ile saklanır ve okunan her blok oraya geri yazılır;
/// bu sayede Xcode konsolu ve cihaz günlüğü etkilenmez. Binary olarak dağıtılan
/// SDK'nın `print` çıktısı da bu yolla yakalanır — SDK sürümünden bağımsızdır.
public class NFXStdoutCapture: NSObject {
    public static let shared = NFXStdoutCapture()

    private var isCapturing = false
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var originalStdout: Int32 = -1
    private var originalStderr: Int32 = -1
    private var partialLines: [Int32: String] = [:]
    private let lock = NSLock()

    private override init() {
        super.init()
    }

    /// Yakalamayı başlatır. Birden çok çağrı etkisizdir.
    public func start() {
        lock.lock()
        defer { lock.unlock() }
        guard !isCapturing else { return }
        isCapturing = true

        // Boru hedefi tam tamponlu olduğu için Swift `print` çıktısı aksi hâlde
        // satır satır değil blok blok gelir; tamponlama kapatılır.
        setvbuf(stdout, nil, _IONBF, 0)

        originalStdout = dup(STDOUT_FILENO)
        originalStderr = dup(STDERR_FILENO)

        stdoutPipe = redirect(descriptor: STDOUT_FILENO, mirrorTo: originalStdout)
        stderrPipe = redirect(descriptor: STDERR_FILENO, mirrorTo: originalStderr)
    }

    /// Yakalamayı durdurur ve orijinal tanıtıcıları geri yükler.
    public func stop() {
        lock.lock()
        defer { lock.unlock() }
        guard isCapturing else { return }
        isCapturing = false

        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stderrPipe?.fileHandleForReading.readabilityHandler = nil

        if originalStdout >= 0 {
            dup2(originalStdout, STDOUT_FILENO)
            close(originalStdout)
            originalStdout = -1
        }
        if originalStderr >= 0 {
            dup2(originalStderr, STDERR_FILENO)
            close(originalStderr)
            originalStderr = -1
        }

        stdoutPipe = nil
        stderrPipe = nil
        partialLines.removeAll()
    }

    private func redirect(descriptor: Int32, mirrorTo mirror: Int32) -> Pipe {
        let pipe = Pipe()
        dup2(pipe.fileHandleForWriting.fileDescriptor, descriptor)

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }

            // Önce orijinal tanıtıcıya geri yaz: Xcode konsolu olduğu gibi kalır.
            data.withUnsafeBytes { buffer in
                guard let base = buffer.baseAddress else { return }
                var written = 0
                while written < data.count {
                    let result = write(mirror, base.advanced(by: written), data.count - written)
                    if result <= 0 { break }
                    written += result
                }
            }

            guard let text = String(data: data, encoding: .utf8) else { return }
            self?.consume(text: text, from: descriptor)
        }
        return pipe
    }

    /// Blok hâlinde gelen metni satırlara ayırır; yarım kalan satır bir sonraki
    /// bloğa taşınır.
    private func consume(text: String, from descriptor: Int32) {
        lock.lock()
        let pending = (partialLines[descriptor] ?? "") + text
        var segments = pending.components(separatedBy: "\n")
        let remainder = segments.removeLast()
        partialLines[descriptor] = remainder
        lock.unlock()

        for line in segments {
            NFXLogStore.shared.addRaw(line: line)
        }
    }
}
