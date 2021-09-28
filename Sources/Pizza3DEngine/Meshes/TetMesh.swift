//
//  TetMesh.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 15/06/21.
//
import Foundation

public class TetMesh : AbstractPolyhedralMesh, Geometry{
    
    public init(filename : String) throws{
        let url = URL(fileURLWithPath: filename)
        do{
            let v_p_l = try readMesh(fileURL: url)
            super.init()
            self.build(vertices: v_p_l.0, polys: v_p_l.1, labels: v_p_l.2)
        }
        catch{
            throw error
        }
        let meshName = String(url.lastPathComponent.split(separator: ".")[0])
        self.meshName = meshName
        
    }
    
    public init(vertices: [vec3], polys: [[Int]], labels : [Int]?) {
        super.init()
        self.build(vertices: vertices, polys: polys, labels: labels)
    }
    
    override func getTriangles(shading: Shading) -> [Vertex]{
        var triangles = [Vertex]()
        triangles.reserveCapacity(polys.count*4)
        for pid in polys.indices{
            if !visiblePolys[pid] {continue}
            
            let lab = labels?[pid] ?? 0
            if labelColors[lab] == nil{
                labelColors[lab] = Color.random(alpha: 1)
            }
            for fid in adjP2F[pid]{
                if !faceIsVisible(fid: fid) {continue}
                let faceIsInternal = !faceIsOnSurf(fid: fid)
                let face = faces[fid]
                var tmpTri = [vec3]()
                tmpTri.reserveCapacity(3)
                for vid in face{
                    tmpTri.append(self.vertices[vid])
                }
                
                //let faceColor =
                
                for i in tmpTri.indices{
                    let pos = tmpTri[i]
                    var normal : vec3
                    switch shading {
                        case .smooth:
                            normal = vertNormals[faces[fid][i]]
                        default:
                            normal = normals[fid]
                    }
                    let color = useLabelColor ? labelColors[lab] : faceIsInternal && useInternalColor ? internalColor : polyColors[pid]
                    let newVert = Vertex.build(pos: pos, color: color!, normal: normal, uv: vec2(0,0), primitiveType: 0)
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
            var edgeIsOnVisiblePoly = false
            
            for pid in adjE2P[eid]{
                if visiblePolys[pid]{
                    edgeIsOnVisiblePoly = true
                    break
                }
            }
            for fid in adjE2F[eid]{
                if faceIsVisible(fid: fid){
                    edgeIsVisible = true
                    break
                }
            }
            if !(edgeIsVisible && edgeIsOnVisiblePoly){continue}
            let edge = edges[eid]
            for vid in edge{
                let newVert = Vertex.build(pos: self.vertices[vid], color: wireframeColor, normal: vec3(0,1,0),uv: vec2(0,0), primitiveType: 1)
                wireframe.append(newVert)
            }
        }
        return wireframe
    }
}
