import Darwin
import Foundation
import Security

/// Runs external tools safely. Spacebar can hold Full Disk Access, and child processes
/// inherit it, so a tool must never be something another program could swap or redirect:
/// absolute paths only, a clean environment (no DYLD_*, DEVELOPER_DIR, PATH tricks), and a
/// code-signature check for tools outside the system's protected folders.
public enum Tools {
    public struct Result {
        public let status: Int32
        public let output: Data
        public let errors: String
    }

    /// The only environment child processes get.
    public static var cleanEnvironment: [String: String] {
        ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "HOME": NSHomeDirectory(), "LANG": "en_US.UTF-8",
         "TMPDIR": NSTemporaryDirectory()]
    }

    /// Runs `path` and waits (at most `timeout` seconds). nil if it can't start.
    public static func run(_ path: String, _ arguments: [String], timeout: TimeInterval = 120,
                           extraEnvironment: [String: String] = [:]) -> Result? {
        guard path.hasPrefix("/") else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.environment = cleanEnvironment.merging(extraEnvironment) { _, new in new }
        process.currentDirectoryURL = URL(fileURLWithPath: "/")
        let output = Pipe()
        let errors = Pipe()
        process.standardOutput = output
        process.standardError = errors
        process.standardInput = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        let timer = DispatchWorkItem { if process.isRunning { process.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timer)
        // Read stderr alongside stdout so a chatty tool can't fill one pipe and stall.
        let errorDone = DispatchGroup()
        nonisolated(unsafe) var errorData = Data()
        errorDone.enter()
        DispatchQueue.global().async {
            errorData = errors.fileHandleForReading.readDataToEndOfFile()
            errorDone.leave()
        }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        errorDone.wait()
        process.waitUntilExit()
        timer.cancel()
        return Result(status: process.terminationStatus, output: data,
                      errors: String(decoding: errorData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// True if the code at `path` is validly signed and satisfies `requirement`
    /// (e.g. `anchor apple`, or a Developer ID team).
    public static func isTrusted(_ path: String, requirement: String) -> Bool {
        var code: SecStaticCode?
        var compiled: SecRequirement?
        guard SecStaticCodeCreateWithPath(URL(fileURLWithPath: path) as CFURL, [], &code) == errSecSuccess, let code,
              SecRequirementCreateWithString(requirement as CFString, [], &compiled) == errSecSuccess else { return false }
        return SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate),
                                          compiled) == errSecSuccess
    }

    /// Owned by root and not writable by anyone else: can't be replaced without admin rights.
    static func isRootProtected(_ path: String) -> Bool {
        var st = stat()
        guard stat(path, &st) == 0 else { return false }
        return st.st_uid == 0 && st.st_mode & (S_IWGRP | S_IWOTH) == 0
    }

    /// Apple's simctl from CoreSimulator (what Xcode's simctl wrapper runs), root-owned and Apple-signed.
    /// Used directly so neither xcrun's DEVELOPER_DIR lookup nor a user-writable Xcode is involved.
    public static let simctl: String? = {
        let path = "/Library/Developer/PrivateFrameworks/CoreSimulator.framework/Versions/A/Resources/bin/simctl"
        return isRootProtected(path) && isTrusted(path, requirement: "anchor apple") ? path : nil
    }()

    /// The developer folder chosen with xcode-select (a root-owned link), for simctl's own lookups.
    public static var developerDirectory: [String: String] {
        let developer = URL(fileURLWithPath: "/var/db/xcode_select_link").resolvingSymlinksInPath().path
        return developer == "/var/db/xcode_select_link" ? [:] : ["DEVELOPER_DIR": developer]
    }
}
