//
//  VoiceRecorderService.swift
//  Pulse
//
//  Created by Codex on 2/19/26.
//

import AVFoundation
import Foundation

enum VoiceRecorderError: LocalizedError {
    case permissionDenied
    case unableToStartRecording

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required to record voice clips."
        case .unableToStartRecording:
            return "Could not start recording. Try again."
        }
    }
}

@MainActor
final class VoiceRecorderService: NSObject {
    private var recorder: AVAudioRecorder?
    private(set) var recordingURL: URL?
    private(set) var recordingDuration: TimeInterval?

    var isRecording: Bool {
        recorder?.isRecording == true
    }

    func startRecording(maxDuration: TimeInterval = 45) async throws {
        let granted = await requestPermission()
        guard granted else { throw VoiceRecorderError.permissionDenied }

        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try AVAudioSession.sharedInstance().setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("voice-\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.prepareToRecord()
            guard recorder.record(forDuration: maxDuration) else {
                throw VoiceRecorderError.unableToStartRecording
            }

            self.recorder = recorder
            self.recordingURL = url
            self.recordingDuration = nil
        } catch {
            throw VoiceRecorderError.unableToStartRecording
        }
    }

    func stopRecording() -> URL? {
        guard let recorder else { return recordingURL }
        recorder.stop()

        let duration = recorder.currentTime
        recordingDuration = duration > 0 ? duration : nil

        self.recorder = nil
        return recordingURL
    }

    func clearRecording() {
        recorder?.stop()
        recorder = nil

        if let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
        }

        recordingURL = nil
        recordingDuration = nil
    }

    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}
