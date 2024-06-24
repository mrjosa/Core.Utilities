//
//  ImageCache.swift
//
//  Created by Sandman.Jonas on 25/01/2024.
//

import Foundation
import UIKit

public class FileCache
{
    public static let shared = FileCache()
    
    public var filePrefix : String = "cache"
    
    private var cache : [String: Data?] = [:]
    
    init()
    {
        purgeFiles(olderThan: 30)
    }
    
    public func get(from url: URL, completion: ((Data?, String, FileError?) -> ())?)
    {
        get(url.absoluteString) { data in
            if let data = data {
                completion?(data, url.absoluteString, nil)
            }
            else {
                completion?(nil, url.absoluteString, FileError.notfound)
            }
        }
    }
            
    private func get(_ name : String, completion: @escaping ((Data?) -> Void))
    {
        let fileManager = FileManager.default
        
        do {
            // Get the URL for the documents directory
            let directoryURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            
            // Create the full file URL
            let fileURL = directoryURL.appendingPathComponent("\(filePrefix)_\(name.sha256Hash())")
            
            // Load the data
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
                let fileData = try? Data(contentsOf: fileURL)
                
                completion(fileData)
            }
        }
        catch {
            print("Error loading file: \(error)")
            completion(nil)
        }
    }
    
    public func download(from url: URL?, completion: ((Data?, FileError?) -> ())?)
    {
        if let url = url {
            
            DispatchQueue.global().async {
                
                let data = try? Data(contentsOf: url)
                
                if let data = data {
                    
                    let name = url.absoluteString
                    
                    self.saveFile(named: name, withData: data) {
                        completion?(data, nil)
                    }
                }
                else {
                    completion?(nil, FileError.failedDownload)
                }
            }
        }
    }
    
    public func saveFile<T : Codable>(named fileName: String, withObject object : T, completion: @escaping () -> Void)
    {
        let encoder = JSONEncoder()
        do
        {
            let data = try encoder.encode(object)
            
            DispatchQueue.global(qos: .userInteractive).async {
                self.saveFile(named: fileName, withData: data, completion: completion)
            }
        }
        catch {
            print("\(error)")
        }
    }
    
    public func saveFile(named name: String, withData data : Data, completion: (() -> Void))
    {
        let fileManager = FileManager.default
        
        if let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            
            let filePath = directory.appendingPathComponent("\(filePrefix)_\(name.sha256Hash())")
            
            DispatchQueue.global(qos: .userInteractive).async {
                try? data.write(to: filePath)
            }
        }
    }
    
    func purgeFiles(olderThan days: Int)
    {
        DispatchQueue.global(qos: .background).async {
            
            let fileManager = FileManager.default
            let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            guard let filePaths = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil, options: []) else { return }
            
            let calendar = Calendar.current
            
            filePaths.forEach { fileURL in
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let creationDate = attributes[.creationDate] as? Date {
                    let age = calendar.dateComponents([.day], from: creationDate, to: Date()).day!
                    
                    if age > days {
                        try? fileManager.removeItem(at: fileURL)
                    }
                }
            }
        }
    }
}
