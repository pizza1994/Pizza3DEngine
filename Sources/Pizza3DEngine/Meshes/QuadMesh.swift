//
//  QuadMesh.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 15/06/21.
//
import Foundation

public class QuadMesh : AbstractPolygonMesh, Geometry{
    
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
        let meshName = String(url.lastPathComponent.split(separator: ".")[0])
        self.meshName = meshName
    }
    
    public init(vertices: [vec3], polys: [[Int]], colors : [vec4]?) {
        super.init()
        self.build(vertices: vertices, polys: polys, colors: colors)
    }
    
    override func getTriangles(shading: Shading) -> [Vertex]{
        var triangles = [Vertex]()
        triangles.reserveCapacity(polys.count*6)
        for pid in polys.indices{
            if !visiblePolys[pid] {continue}
            let poly = polys[pid]
            
            var tmpTris = [[vec3]]()
            tmpTris.reserveCapacity(2)
            tmpTris.append([vec3]())
            tmpTris.append([vec3]())
            var tmpNormals = [[vec3]]()
            tmpNormals.reserveCapacity(2)
            tmpNormals.append([vec3]())
            tmpNormals.append([vec3]())
            
            let tri1 = [poly[0], poly[1], poly[3]]
            let tri2 = [poly[1], poly[2], poly[3]]
            let tris = [[0,1,3], [1,2,3]]
            for vid in tri1{
                tmpTris[0].append(self.vertices[vid])
                tmpNormals[0].append(self.vertNormals[vid])
            }
            for vid in tri2{
                tmpTris[1].append(self.vertices[vid])
                tmpNormals[1].append(self.vertNormals[vid])
            }
            
            for i in tmpTris.indices{
                let fNormals = computeVertNormals(tri: tmpTris[i])
                for j in tmpTris[i].indices{
                    var normal : vec3
                    switch shading{
                        case .smooth:
                            normal = tmpNormals[i][j]
                        default:
                            normal = fNormals[j]
                    }
                    let pos = tmpTris[i][j]
                    
                    var txc = vec2(0,0)
                    if let _ = uv{
                        if(self.polys.count == uv?.count){
                            txc = uv![pid][tris[i][j]]
                        }
                    }
                    
                    let newVert = Vertex.build(pos: pos, color: polyColors[pid], normal: normal, uv: txc, primitiveType: 0)
                    triangles.append(newVert)
                }
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
