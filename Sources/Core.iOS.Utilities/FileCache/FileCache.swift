//
//  ImageCache.swift
//  LaMeridionaleiOS
//
//  Created by Sandman.Jonas on 25/01/2024.
//

import Foundation
import UIKit

public class FileCache
{
    public static let shared = FileCache()
    private var cache : [String: Data?] = [:]
    
    init()
    {
        purgeFiles(olderThan: 30)
    }
    
    public func get(from url: URL, completion: ((Data?, String, FileError?) -> ())?)
    {
        if let file = get(url.absoluteString) {
            completion?(file, url.absoluteString, nil)
        }
        else {
            completion?(nil, url.absoluteString, FileError.notfound)
        }
    }
            
    private func get(_ name : String) -> Data?
    {
        let fileManager = FileManager.default
        
        do {
            // Get the URL for the documents directory
            let directoryURL = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            
            // Create the full file URL
            let fileURL = directoryURL.appendingPathComponent("lmfile_\(name.sha256Hash())")
            
            // Load the data
            let fileData = try Data(contentsOf: fileURL)
            
            return fileData
        }
        catch {
            print("Error loading file: \(error)")
            return nil
        }
    }
    
    public func download(from url: URL?, completion: ((Data?, FileError?) -> ())?)
    {
        if let url = url {
            
            DispatchQueue.global().async {
                
                let data = try? Data(contentsOf: url)
                
                if let data = data {
                    
                    let name = url.absoluteString
                    
                    self.saveFile(named: name , withData: data)
                    
                    completion?(data, nil)
                }
                else {
                    completion?(nil, FileError.failedDownload)
                }
            }
        }
    }
    
    public func saveFile<T : Codable>(named fileName: String, withObject object : T)
    {
        let encoder = JSONEncoder()
        do
        {
            let data = try encoder.encode(object)
            saveFile(named: fileName, withData: data)
        }
        catch {
            print("\(error)")
        }
    }
    
    public func saveFile(named name: String, withData data : Data)
    {
        let fileManager = FileManager.default
        
        if let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            
            let filePath = directory.appendingPathComponent("lmfile_\(name.sha256Hash())")
            try? data.write(to: filePath)
        }
    }
    
    func purgeFiles(olderThan days: Int)
    {
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
