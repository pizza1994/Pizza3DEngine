//
//  ObjIO.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 23/06/21.
//

import Foundation

public func readObj(fileURL : URL) throws -> ([vec3], [[Int]], [[vec2]]){
    
    var text = ""
    do{
        text = try String(contentsOf: fileURL, encoding: .utf8)
    }
    catch{
        print("Error loading file: \(error)")
        throw error
    }
    
    let lines = text.split(whereSeparator: \.isNewline)
    
    var vertices = [vec3]()
    var polys = [[Int]]()
    var uv = [[vec2]]()
    
    var tmpUV = [vec2]()
    
    for line_ in lines{
        let line = line_.replacingOccurrences(of: "\t", with: "")
        let split = line.split(separator: " ")
        
        if split.first == "v"{
            vertices.append(vec3(Float(split[1])!, Float(split[2])!, Float(split[3])!))
        }
        if split.first == "vt"{
            var currUV = vec2(Float(split[1])!,0)
            if split.count > 2{
                currUV.y = Float(split[2])!
            }
            tmpUV.append(currUV)
        }
        if split.first == "f"{
            if line.contains("/"){
                var poly = [Int]()
                var currUV = [vec2]()
                for spl in split[1..<split.count]{
                    let subsplit = spl.split(separator: "/")
                    let format = subsplit.count
                    let tmp_vid = Int(subsplit[0])!
                    if tmp_vid < 0{
                        poly.append(vertices.count+tmp_vid)
                    }
                    else{
                        poly.append(tmp_vid-1)
                    }
                    if format >= 2{
                        let uv = Int(subsplit[1])!
                        if uv < 0{
                            currUV.append(tmpUV[tmpUV.count+uv])
                        }
                        else{
                            currUV.append(tmpUV[uv-1])
                        }
                    }
                }
                
                polys.append(poly)
                uv.append(currUV)
            }
            else{
                var poly = [Int]()
                for vid in split[1..<split.count]{
                    let tmp_vid = Int(vid)!
                    if tmp_vid < 0{
                        poly.append(vertices.count+tmp_vid)
                    }
                    else{
                        poly.append(tmp_vid-1)
                    }
                }
                polys.append(poly)
            }
        }
    }
    
    
    return (vertices, polys, uv)
}
