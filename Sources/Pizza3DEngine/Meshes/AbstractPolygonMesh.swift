//
//  AbstractPolygonMesh.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 11/06/21.
//
import simd

public class AbstractPolygonMesh : AbstractMesh{
    
    public let isVolumetric = false
    public let isSurface = true
    public var uv : [[vec2]]?
    
    func build(vertices : [vec3], polys : [[Int]], colors : [vec4]?){
        
        self.vertices.reserveCapacity(vertices.count)
        self.polys.reserveCapacity(polys.count)
        self.edges.reserveCapacity(polys.count*3)
        self.visiblePolys.reserveCapacity(polys.count)
        self.adjV2V.reserveCapacity(vertices.count)
        self.adjV2E.reserveCapacity(vertices.count)
        self.adjV2P.reserveCapacity(vertices.count)
        self.adjE2V.reserveCapacity(edges.count)
        self.adjE2E.reserveCapacity(edges.count)
        self.adjE2P.reserveCapacity(edges.count)
        self.adjP2V.reserveCapacity(polys.count)
        self.adjP2E.reserveCapacity(polys.count)
        self.adjP2P.reserveCapacity(polys.count)
        self.visiblePolys.reserveCapacity(polys.count)
        self.polyColors.reserveCapacity(polys.count)
        
        for vert in vertices{
            let _ = addVert(vert: vert)
        }
        
        if let _ = colors{
            polyColors = colors!
        }
        for poly in polys{
            let _ = addPoly(poly: poly)
            if colors == nil{
                polyColors.append(AbstractMesh.defaultColor)
            }
        }
        
        
        
        adjP2V = polys
        adjE2V = edges
        
        for eid in 0..<edges.count{
            adjE2E.append([Int]())
            for vid in adjE2V[eid]{
                for e in adjV2E[vid]{
                    if e != eid{
                        adjE2E[eid].append(e)
                    }
                }
            }
        }
        
        updateNormals()
    }
    
    private func addVert(vert : vec3) -> Int{
        
        let vid = vertices.count
        vertices.append(vert)
        
        adjV2V.append([Int]())
        adjV2E.append([Int]())
        adjV2P.append([Int]())
        
        bbox.add(point: vert)
        
        return vid
    }
    
    private func addPoly(poly : [Int])-> Int{
        
        let pid = polys.count
        polys.append(poly)
        
        adjP2E.append([Int]())
        adjP2P.append([Int]())
        
        for i in 0..<poly.count{
            let v0 = poly[i]
            let v1 = poly[(i+1)%poly.count]
            let eid = edgeId(v0: v0, v1: v1)
            if eid == -1{
               let _ = addEdge(edge: [v0, v1])
            }
        }
        
        for vid in poly{
            adjV2P[vid].append(pid)
        }
        
        for i in 0..<poly.count{
            let v0 = poly[i]
            let v1 = poly[(i+1)%poly.count]
            let eid = edgeId(v0: v0, v1: v1)
            
            for nbr in adjE2P[eid]{
                assert(nbr != pid)
                if !polysAreAdjacent(p0: pid, p1: nbr){
                    continue
                }
                adjP2P[pid].append(nbr)
                adjP2P[nbr].append(pid)
            }
            
            adjE2P[eid].append(pid)
            adjP2E[pid].append(eid)
        }
        
        visiblePolys.append(true)
        
        return pid
        
    }
    
    private func addEdge(edge : [Int]) -> Int{
        
        let eid = edges.count
        edges.append(edge)
        
        adjE2P.append([Int]())
        adjV2V[edge[0]].append(edge[1])
        adjV2V[edge[1]].append(edge[0])
        
        adjV2E[edge[0]].append(eid)
        adjV2E[edge[1]].append(eid)
        
        return eid
    }
    
    public func updateNormals(){
        
        normals.removeAll()
        vertNormals.removeAll()
        
        for pid in polys.indices{
            let a = vertices[polys[pid][1]]-vertices[polys[pid][0]]
            var b : vec3
            if(polys[pid].count == 3){
                b = vertices[polys[pid][2]]-vertices[polys[pid][0]]
            }
            else{
                b = vertices[polys[pid][3]]-vertices[polys[pid][0]]
            }
            var normal = cross(a, b)
            normal /= length(normal)
            normals.append(normal)
        }
        
        for vid in vertices.indices{
            var vNormal = vec3(0,0,0)
            var count : Int = 0
            for pid in adjV2P[vid]{
                vNormal += normals[pid]
                count += 1
            }
            vNormal/=Float(count)
            vertNormals.append(vNormal)
            
        }
        
    }
    
    public func dig(id : Int){
        for pid in adjE2P[id]{
            if visiblePolys[pid]{
                visiblePolys[pid] = false
                didChange = true
                break
            }
        }
    }
    public func undig(id : Int){
        for pid in adjE2P[id]{
            if !visiblePolys[pid]{
                visiblePolys[pid] = true
                didChange = true
                break
            }
        }
    }
    
}
