//
//  OffIO.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 23/06/21.
//

import Foundation

public func readOff(fileURL : URL) throws -> ([vec3], [[Int]], [vec4]){
    
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
    var polyColor = [vec4]()
    
    var numVertices = 0
    var numPolys = 0
    
    var idx = 0
    for line in lines{
        idx+=1
        if line.first == "#" {continue}
        let split = line.split(separator: " ")
        if split.count == 3{
            numVertices = Int(split[0])!
            numPolys = Int(split[1])!
            break
        }
    }
    
    vertices.reserveCapacity(numVertices)
    polys.reserveCapacity(numPolys)
    polyColor.reserveCapacity(numPolys)
    
    for line in lines[idx..<idx+numVertices]{
        let vtx = line.split(separator: " ")
        vertices.append(vec3(Float(vtx[0])!, Float(vtx[1])!, Float(vtx[2])!))
    }
    
    if numPolys > 0{
        for line in lines[idx+numVertices..<idx+numVertices+numPolys]{
            let p = line.split(separator: " ")
            var poly = [Int]()
            for v in p[1..<1+Int(p[0])!]{
                poly.append(Int(v)!)
            }
            polys.append(poly)
            
            var color = [Float]()
            for c in p[1+Int(p[0])!..<p.count]{
                color.append(Float(c)!)
            }
            
            switch color.count{
                case 3:
                    polyColor.append(vec4(color[0], color[1], color[2], 1))
                case 4:
                    polyColor.append(vec4(color[0], color[1], color[2], color[3]))
                default:
                    polyColor.append(AbstractMesh.defaultColor)
            }
        }
        
    }
    
    
    return (vertices, polys, polyColor)
}
