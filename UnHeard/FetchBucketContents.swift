//
//  FetchBucketContents.swift
//  UnHeard
//
//  Created by Avya Rathod on 28/02/24.
//

import Foundation

struct BucketContents: Codable {
    var items: [Item]
    
    struct Item: Codable {
        var name: String
    }
}

class BucketViewModel: ObservableObject {
    @Published var directories = [String]()
    @Published var secondLevelDirectories: [String: [String]] = [:]
    @Published var videoFilesInDirectories: [String: String] = [:]
    let bucketName: String = "isldictionary"
    let apiKey: String = ""

    func fetchFirstLevelDirectories() {
        let urlString = "https://storage.googleapis.com/storage/v1/b/\(bucketName)/o?delimiter=/&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data else {
                print("Fetch failed:", error?.localizedDescription ?? "Unknown error")
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let prefixes = jsonResponse["prefixes"] as? [String] {
                    let directories = prefixes.map { String($0.dropLast()) } // Remove the '/' at the end
                    DispatchQueue.main.async {
                        self.directories = directories
                        // After updating directories, fetch second-level directories for each
                        directories.forEach { self.fetchSecondLevelDirectories(for: $0) }
                    }
                }
            } catch {
                print("JSON parsing failed:", error.localizedDescription)
            }
        }.resume()
    }

    func fetchSecondLevelDirectories(for directory: String) {
        let encodedDirectory = directory.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        let urlString = "https://storage.googleapis.com/storage/v1/b/\(bucketName)/o?delimiter=/&prefix=\(encodedDirectory)/&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data else {
                print("Fetch failed:", error?.localizedDescription ?? "Unknown error")
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let prefixes = jsonResponse["prefixes"] as? [String] {
                    let secondLevelDirs = prefixes.map { $0.dropLast().split(separator: "/").last.map(String.init) ?? "" }
                    DispatchQueue.main.async {
                        self.secondLevelDirectories[directory] = secondLevelDirs
                        // For each second-level directory, fetch third-level directories and video names
                        secondLevelDirs.forEach { secondLevelDir in
                            let fullPath = "\(directory)/\(secondLevelDir)"
                            self.fetchThirdLevelDirectoriesAndVideoName(for: fullPath)
                        }
                    }
                }
            } catch {
                print("JSON parsing failed:", error.localizedDescription)
            }
        }.resume()
    }
    
    func fetchThirdLevelDirectoriesAndVideoName(for directory: String) {
            let encodedDirectory = directory.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
            let urlString = "https://storage.googleapis.com/storage/v1/b/\(bucketName)/o?delimiter=/&prefix=\(encodedDirectory)/&key=\(apiKey)"
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return
            }

            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self, let data = data else {
                    print("Fetch failed:", error?.localizedDescription ?? "Unknown error")
                    return
                }

                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let items = jsonResponse["items"] as? [[String: Any]] {
                        // Assuming there is one video file per directory, find the first video file
                        if let videoFile = items.first(where: { item in
                            if let name = item["name"] as? String {
                                return name.hasSuffix(".MOV") || name.hasSuffix(".MP4")
                            }
                            return false
                        }) {
                            if let videoFileName = videoFile["name"] as? String {
                                // Store the video file name, keyed by the directory
                                DispatchQueue.main.async {
                                    self.videoFilesInDirectories[directory] = videoFileName
                                }
                            }
                        }
                    }
                } catch {
                    print("JSON parsing failed:", error.localizedDescription)
                }
            }.resume()
        }
    
}
