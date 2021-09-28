//
//  TriangleMesh.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 11/06/21.
//

import Foundation

public class TriangleMesh : AbstractPolygonMesh, Geometry{
    
    public init(filename : String) throws{
        super.init()
        let url = URL(fileURLWithPath: filename)
        if url.lastPathComponent.contains(".off") || url.lastPathComponent.contains(".OFF"){
            do{
                let v_p_c = try readOff(fileURL: url)
                self.build(vertices: v_p_c.0, polys: v_p_c.1, colors: v_p_c.2)
            }
            catch{
                throw error
            }
        }
        if url.lastPathComponent.contains(".obj") || url.lastPathComponent.contains(".OBJ"){
            do{
                let v_p_uv = try readObj(fileURL: url)
                self.build(vertices: v_p_uv.0, polys: v_p_uv.1, colors: nil)
                super.uv = v_p_uv.2
            }
            catch{
                throw error
            }
        }
        if url.lastPathComponent.contains(".stl") || url.lastPathComponent.contains(".STL"){
            do{
                let v_p = try readSTL(fileURL: url)
                self.build(vertices: v_p.0, polys: v_p.1, colors: nil)
            }
            catch{
                throw error
            }
        }
        
        let meshName = String(url.lastPathComponent.split(separator: ".")[0])
        self.meshName = meshName
        
    }
    
    public init(vertices: [vec3], polys: [[Int]], colors : [vec4]?) {
        super.init()
        self.build(vertices: vertices, polys: polys, colors: colors)
    }
    
    
    
    override func getTriangles(shading: Shading) -> [Vertex]{
        var triangles = [Vertex]()
        triangles.reserveCapacity(polys.count*3)
        for pid in polys.indices{
            if !visiblePolys[pid] {continue}
            let poly = polys[pid]
            var tmpTri = [vec3]()
            tmpTri.reserveCapacity(3)
            for vid in poly{
                tmpTri.append(self.vertices[vid])
            }
            for i in tmpTri.indices{
                var normal : vec3
                switch shading {
                    case .smooth:
                        normal = vertNormals[polys[pid][i]]
                    default:
                        normal = normals[pid]
                }
                let pos = tmpTri[i]
                
                var txc = vec2(0,0)
                if let _ = uv{
                    if(self.polys.count == uv?.count){
                        txc = uv![pid][i]
                    }
                }
                
                let newVert = Vertex.build(pos: pos, color: polyColors[pid], normal: normal, uv: txc, polyCentroid: polyCentroid(pid: pid), primitiveType: 0)
                triangles.append(newVert)
            }
        }
        return triangles
    }
    
    override func getWireframe() -> [Vertex]{
        var wireframe = [Vertex]()
        wireframe.reserveCapacity(edges.count*2)
        for eid in edges.indices{
            var edgeIsVisible = false
            for pid in adjE2P[eid]{
                if visiblePolys[pid]{
                    edgeIsVisible = true
                    break
                }
            }
            if !edgeIsVisible {continue}
            let edge = edges[eid]
            for vid in edge{
                
                let newVert = Vertex.build(pos: self.vertices[vid], color: wireframeColor, primitiveType: 1)
                wireframe.append(newVert)
            }
        }
        return wireframe
    }
    
    
}
