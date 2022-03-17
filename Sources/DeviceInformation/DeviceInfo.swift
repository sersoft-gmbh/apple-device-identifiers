import Foundation
#if canImport(UIKit)
import class UIKit.UIDevice
#endif
import Sysctl

/// Contains the information about a device.
public struct DeviceInfo: Equatable, Identifiable {
    /// Contains the information about the operating system of a device.
    public struct OperatingSystem: Equatable {
        /// The name of the operating system (e.g. iOS or macOS)
        public let name: String
        /// The version of the operating system (e.g. 14.3.0 or 11.0.0)
        public let version: String
        /// The build version of the operating system.
        public let build: String

        static func currentName() -> String {
            // Keep up to date with https://github.com/apple/swift/blob/main/lib/Basic/LangOptions.cpp
#if canImport(UIKit) && !targetEnvironment(macCatalyst) // os(iOS) os(tvOS) os(watchOS)
            return UIDevice.current.systemName
#elseif os(macOS) || targetEnvironment(macCatalyst)
            return "macOS"
#elseif os(Linux)
            return "Linux"
#elseif os(FreeBSD)
            return "FreeBSD"
#elseif os(OpenBSD)
            return "OpenBSD"
#elseif os(Windows)
            return "Windows"
#elseif os(Android)
            return "Android"
#elseif os(PS4)
            return "PS4"
#elseif os(Cygwin)
            return "Cygwin"
#elseif os(Haiku)
            return "Haiku"
#elseif os(WASI)
            return "Web Assembly"
#else
            return "Unknown"
#endif
        }

        init() {
            name = OperatingSystem.currentName()
            let osVersion = ProcessInfo.processInfo.operatingSystemVersion
            version = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
            build = SystemControl().kernel.osBuild
        }
    }

    /// The identifier of the device (e.g. iPhone13,4)
    public let identifier: String
    /// The name of the device if present.
    /// If this is nil, please check if a newer version of the package is available.
    public let name: String?
    /// The operating system information.
    public let operatingSystem: OperatingSystem

    /// See `Identifiable.id`.
    @inlinable
    public var id: String { identifier }

    init() {
#if os(macOS) || targetEnvironment(macCatalyst)
        identifier = SystemControl().hardware.model
#else
        identifier = SystemControl().hardware.machine
#endif
        name = DeviceInfo._deviceIdentifierToNameMapping[identifier]
        operatingSystem = .init()
    }
}

extension DeviceInfo {
    /// The informatino for the current device.
    public static let current = DeviceInfo()
}

#if arch(arm64) || arch(x86_64)
#if canImport(Combine) && canImport(SwiftUI)
import Combine
import SwiftUI

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension DeviceInfo {
    @usableFromInline
    @frozen
    enum EnvKey: EnvironmentKey {
        @usableFromInline
        typealias Value = DeviceInfo

        @inlinable
        static var defaultValue: Value { .current }
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension SwiftUI.EnvironmentValues {
    /// The device info of the current device.
    @inlinable
    public var deviceInfo: DeviceInfo { self[DeviceInfo.EnvKey.self] }
}
#endif
#endif

#if compiler(>=5.5.2) && canImport(_Concurrency)
extension DeviceInfo: Sendable {}
extension DeviceInfo.OperatingSystem: Sendable {}
#endif
