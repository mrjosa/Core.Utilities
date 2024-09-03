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
        if let fileURL = SharedFileManager.getFilePath(name: "\(filePrefix)_\(name)".sha256Hash(), type: FileType.cache) {
            
            // Load the data
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
                let fileData = try? Data(contentsOf: fileURL)
                
                completion(fileData)
            }
        }
    }
    
    public func download(from url: URL?, completion: ((Data?, FileError?) -> ())?)
    {
        if let url = url {
            
            DispatchQueue.global().async {
                
                let data = try? Data(contentsOf: url)
                
                if let data = data {
                    
                    let name = url.absoluteString
                    
                    SharedFileManager.saveFile(named: "\(self.filePrefix)_\(name)".sha256Hash(), type: .cache, withData: data) { success in
                        completion?(success ? data : nil, nil)
                    }
                }
                else {
                    completion?(nil, FileError.failedDownload)
                }
            }
        }
    }
    
    public func getFile<T : Decodable>(named fileName: String, completion: @escaping (T?) -> Void)
    {
        if let filePath = SharedFileManager.getFilePath(name: fileName, type: .cache) {
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
                
                if let fileData = try? Data(contentsOf: filePath) {
                    
                    let str = String(data: fileData, encoding: .utf8)
                    
                    let decoder = JSONDecoder()
                    
                    let value = try? decoder.decode(T.self, from: fileData)
                    
                    completion(value)
                }
                else {
                    // should be data but make sure...
                    
                    completion(nil)
                }
            }
        }
        else {
            // no file found!
            completion(nil)
        }
    }
    
    public func saveData(named fileName: String, withData data : Data, completion: @escaping (Bool) -> Void)
    {
        let encoder = JSONEncoder()
        
        do
        {
            SharedFileManager.saveFile(named: fileName, type: .cache, withData: data, completion: completion)
        }
        catch {
            print("\(error)")
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
