//
//  File.swift
//  
//
//  Created by Sandman.Jonas on 28/06/2024.
//

import Foundation

class SharedFileManager
{
    static func getFilePath(name: String, type : FileType) -> URL?
    {
        let fileManager = FileManager.default
        
        do {
            // Get the URL for the documents directory
            let directoryURL = try fileManager.url(for: type == FileType.cache ? .cachesDirectory : .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            
            // Create the full file URL
            let fileURL = directoryURL.appendingPathComponent(name)
            
            return fileURL
        }
        catch {
            print("Error loading file: \(error)")
        }
        
        return nil
    }
    
    static func saveFile(named name: String, type: FileType, withData data : Data, completion: @escaping ((Bool) -> Void))
    {
        if let filePath = SharedFileManager.getFilePath(name: name, type: type) {
            
            DispatchQueue.global(qos: .userInteractive).async {
                try? data.write(to: filePath)
                
                completion(true)
            }
        }
        else {
            completion(false)
        }
    }
    
    static func loadFile(named name : String, type: FileType, completion: @escaping (Data?) -> (Void))
    {
        if let filePath = SharedFileManager.getFilePath(name: name, type: type) {
            
            DispatchQueue.global(qos: .userInteractive).async {
                
                if let data = try? Data(Data(contentsOf: filePath)) {
                    
                    completion(data)
                }
                else {
                    completion(nil)
                }
            }
        }
        else {
            completion(nil)
        }
    }
}
