//
//  File.swift
//  
//
//  Created by Luca Pitzalis on 27/09/21.
//

import Foundation

public func readSTL(fileURL : URL) throws -> ([vec3], [[Int]]){
    
    var text = ""
    var textData : Data?
    do{
        text = try String(contentsOf: fileURL)
    }
    catch{
        guard let textData_ = try? Data(contentsOf: fileURL, options: .alwaysMapped) else{
            print("Error loading file: \(error)")
            throw error
        }
        
        textData = textData_
    }
    
    let lines = text.split(whereSeparator: \.isNewline)
    
    var vMap = Dictionary<vec3, Int>()
    
    var vertices = [vec3]()
    var polys = [[Int]]()
    
    let isBinary : Bool = !(text.contains("solid") && text.contains("facet"))
    
    if !isBinary{
        var poly = [Int]()
        for line in lines{
            let line_ = String(line)
            if line_.contains("facet normal"){
                poly.removeAll()
            }
            if line_.contains("endfacet"){
                polys.append(poly)
            }
            
            if line_.contains("vertex"){
                let vertString = line_.split(separator: " ");
                guard vertString.count == 4 else{
                    throw ReadError.invalidSTLFile
                }
                let vert = vec3(Float(vertString[1])!, Float(vertString[2])!, Float(vertString[3])!)
                
                if let vid = vMap[vert]{
                    poly.append(vid)
                }
                else{
                    poly.append(vertices.count)
                    vMap[vert] = vertices.count
                    vertices.append(vert)
                }
                
            }
        }
    }
    else{
        guard textData!.count > 84 else{
            throw ReadError.invalidSTLFile
        }
        
        let triLength : Int = 50
        for idx in stride(from: 84, through: textData!.count-triLength, by: triLength){
            
            var poly = [Int]()
            
            let v1 : (Float32, Float32, Float32) =  textData!.scanValue(start: idx+12, length: 12)
            let v2 : (Float32, Float32, Float32) =  textData!.scanValue(start: idx+24, length: 12)
            let v3 : (Float32, Float32, Float32) =  textData!.scanValue(start: idx+36, length: 12)
            
            for vert_ in [v1, v2, v3]{
                
                let vert = vec3(Float(vert_.0), Float(vert_.1), Float(vert_.2))
                if let vid = vMap[vert]{
                    poly.append(vid)
                }
                else{
                    poly.append(vertices.count)
                    vMap[vert] = vertices.count
                    vertices.append(vert)
                }
            }
            
            polys.append(poly)
            
        }
        
    }
    
    return (vertices, polys)
    
}

private extension Data {
    func scanValue<T>(start: Int, length: Int) -> T {
        
        return self.subdata(in: start..<start+length).withUnsafeBytes{$0.load(as: T.self)}
    }
}
