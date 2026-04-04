//----------------------------------------------------------------------------------/
// # MotionCore                                                                     /
// ---------------------------------------------------------------------------------/
// Abschnitt . . : Services/Media                                                   /
// Datei . . . . : VideoCacheService.swift                                          /
// Autor . . . . : Bartosz Stryjewski                                               /
// Erstellt am . : 04.04.2026                                                       /
// Beschreibung  : Actor-basierter LRU-Cache für Exercise-Videos und -Poster        /
// ---------------------------------------------------------------------------------/
// (C) Copyright by Bartosz Stryjewski                                              /
// ---------------------------------------------------------------------------------/
//
import Foundation
import UIKit

// MARK: - VideoCacheService

actor VideoCacheService {

    static let shared = VideoCacheService()

    // Cache-Verzeichnisse im Caches-Ordner der App (iOS löscht diese bei Speicherknappheit)
    private static let videosDir: URL = makeDir("exercise-videos")
    private static let postersDir: URL = makeDir("exercise-posters")

    // Maximale Cache-Größen
    private let maxVideoByes  = 500 * 1024 * 1024   // 500 MB
    private let maxPosterBytes =  50 * 1024 * 1024   //  50 MB

    // Laufende Video-Downloads (verhindert doppelten Download bei mehrfachem Aufruf)
    private var downloadingVideos: Set<String> = []

    // MARK: - Öffentliche API (synchron)

    /// Gibt die lokale Datei-URL zurück wenn das Video gecacht ist, sonst nil.
    /// Synchron und thread-sicher — nur FileManager.fileExists, kein Schreiben.
    nonisolated static func localVideoURL(for path: String) -> URL? {
        let file = videosDir.appendingPathComponent(sanitize(path))
        return FileManager.default.fileExists(atPath: file.path) ? file : nil
    }

    // MARK: - Öffentliche API (async, actor-isoliert)

    /// Lädt ein Poster: zuerst aus dem Cache, bei Cache-Miss vom Remote-Server.
    /// Speichert das Poster nach dem Download für künftige Aufrufe.
    func loadPoster(path: String, from remoteURL: URL) async -> UIImage? {
        let localFile = Self.postersDir.appendingPathComponent(Self.sanitize(path))

        // Cache-Hit: Poster liegt bereits auf der Disk
        if FileManager.default.fileExists(atPath: localFile.path),
           let data = try? Data(contentsOf: localFile),
           let image = UIImage(data: data) {
            return image
        }

        // Cache-Miss: Vom Server laden und cachen
        do {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            guard let image = UIImage(data: data) else { return nil }
            try? data.write(to: localFile, options: .atomic)
            await trimIfNeeded(directory: Self.postersDir, maxBytes: maxPosterBytes)
            return image
        } catch {
            print("[VideoCacheService] Poster-Download fehlgeschlagen: \(error)")
            return nil
        }
    }

    /// Lädt ein Video in den Cache (Hintergrundoperation).
    /// Wird ignoriert wenn das Video bereits gecacht ist oder ein Download läuft.
    func cacheVideo(path: String, from remoteURL: URL) async {
        let localFile = Self.videosDir.appendingPathComponent(Self.sanitize(path))

        // Abbruch: bereits gecacht oder Download läuft bereits
        guard !FileManager.default.fileExists(atPath: localFile.path) else { return }
        guard !downloadingVideos.contains(path) else { return }

        downloadingVideos.insert(path)
        defer { downloadingVideos.remove(path) }

        do {
            let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
            // Vorhandene Datei überschreiben falls ein paralleler Download durchkam
            if FileManager.default.fileExists(atPath: localFile.path) {
                try? FileManager.default.removeItem(at: localFile)
            }
            try FileManager.default.moveItem(at: tempURL, to: localFile)
            await trimIfNeeded(directory: Self.videosDir, maxBytes: maxVideoByes)
            print("[VideoCacheService] Video gecacht: \(path)")
        } catch {
            print("[VideoCacheService] Video-Download fehlgeschlagen: \(error)")
        }
    }

    // MARK: - LRU-Bereinigung

    /// Löscht die ältesten Dateien bis der Verzeichnis-Inhalt unter das Limit fällt.
    private func trimIfNeeded(directory: URL, maxBytes: Int) async {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        var totalSize = 0
        var files: [(url: URL, date: Date, size: Int)] = []

        for url in contents {
            let res = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
            let size = res?.fileSize ?? 0
            let date = res?.creationDate ?? Date.distantPast
            totalSize += size
            files.append((url: url, date: date, size: size))
        }

        guard totalSize > maxBytes else { return }

        // Älteste Dateien zuerst löschen (LRU-Approximation via Erstellungsdatum)
        var remaining = totalSize
        for file in files.sorted(by: { $0.date < $1.date }) {
            guard remaining > maxBytes else { break }
            try? FileManager.default.removeItem(at: file.url)
            remaining -= file.size
        }
    }

    // MARK: - Hilfsmethoden

    /// Wandelt einen Storage-Pfad in einen sicheren Dateinamen um.
    private static func sanitize(_ path: String) -> String {
        path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
            .replacingOccurrences(of: "/", with: "_")
    }

    private static func makeDir(_ name: String) -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
