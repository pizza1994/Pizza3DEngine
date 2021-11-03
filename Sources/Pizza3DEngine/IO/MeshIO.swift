//
//  MeshIO.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 15/06/21.
//
import Foundation

public func readMesh(fileURL : URL) throws -> ([vec3], [[Int]], [Int]){
    
    var vertices = [vec3]()
    var polys = [[Int]]()
    var labels = [Int]()
    
    var text = ""
    do{
        text = try String(contentsOf: fileURL, encoding: .utf8)
    }
    catch{
        print("Error loading file: \(error)")
        throw error
    }
    
    guard text.contains("MeshVersionFormatted") && text.contains("Dimension") else{
        throw ReadError.invalidMESHFile
    }
    
    let lines = text.split(whereSeparator: \.isNewline)
    
    var numVertices = 0
    var numPolys = 0
    var start = 0
    for i in lines.indices{
        let line = String(lines[i])
        if line.contains("Vertices") && !line.contains("#"){
            numVertices = Int(lines[i+1]) ?? 0
            start = i+2
            break
        }
    }
    vertices.reserveCapacity(numVertices)
    for i in start..<start+numVertices{
        let line = lines[i]
        let sub = line.split(separator: " ")
        vertices.append(vec3(Float(sub[0])!, Float(sub[1])!, Float(sub[2])!))
    }
    
    for i in start+numVertices..<lines.count{
        let line = String(lines[i])
        if (line.contains("Tetrahedra") || line.contains("Hexahedra")) && !line.contains("#"){
            numPolys = Int(lines[i+1]) ?? 0
            start = i+2
            break
        }
    }
    
    polys.reserveCapacity(numPolys)
    labels.reserveCapacity(numPolys)
    for i in start..<start+numPolys{
        let line = lines[i]
        let sub = line.split(separator: " ")
        var poly = [Int]()
        for j in 0..<sub.count-1{
            poly.append(Int(sub[j])!-1)
        }
        let label = Float(String(sub.last!))
        labels.append(Int(label!))
        polys.append(poly)
    }
    
    return (vertices, polys, labels)
}
