//
//  HexMesh.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 15/06/21.
//

import Foundation

public class HexMesh : AbstractPolyhedralMesh, Geometry{
    
    public init(filename : String) throws {
        
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
        self.build(vertices: vertices, polys: polys, labels : labels)
    }
    
    override func getTriangles(shading: Shading) -> [Vertex]{
        var triangles = [Vertex]()
        triangles.reserveCapacity(polys.count*12)
        
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
                var tmpTris = [[vec3]]()
                tmpTris.reserveCapacity(2)
                tmpTris.append([vec3]())
                tmpTris.append([vec3]())
                
                var tmpNormals = [[vec3]]()
                tmpNormals.reserveCapacity(2)
                tmpNormals.append([vec3]())
                tmpNormals.append([vec3]())
                
                for vid in [face[0], face[1], face[3]]{
                    tmpTris[0].append(self.vertices[vid])
                    
                    tmpNormals[0].append(self.vertNormals[vid])

                }
                for vid in [face[1], face[2], face[3]]{
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
                        let color = useLabelColor ? labelColors[lab] : (useQualityColor ? Color.valueToMap(value: quality(pid: pid)) : (faceIsInternal && useInternalColor ? internalColor : polyColors[pid]))
                        let newVert = Vertex.build(pos: pos, color: color!, normal: normal, uv: vec2(0,0),polyCentroid: polyCentroid(pid: pid), primitiveType: 0)
                        triangles.append(newVert)
                    }
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
                let newVert = Vertex.build(pos: self.vertices[vid], color: wireframeColor, normal: vec3(0,1,0), uv: vec2(0,0), primitiveType: 1)
                wireframe.append(newVert)
            }
        }
        return wireframe
    }
    
    func quality(pid : Int) -> Float{
        let vids = self.adjP2V[pid]
        return hexScaledJacobian(p0: vertices[vids[0]], p1: vertices[vids[1]], p2: vertices[vids[2]], p3: vertices[vids[3]], p4: vertices[vids[4]], p5: vertices[vids[5]], p6: vertices[vids[6]], p7: vertices[vids[7]])
    }
    
}
