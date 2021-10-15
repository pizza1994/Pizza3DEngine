//
//  AbstractPolyhedralMesh.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 15/06/21.
//
import simd

public class AbstractPolyhedralMesh : AbstractMesh{
    
    public let isVolumetric = true
    public let isSurface = false
    
    internal(set) public var faces = [[Int]]()
    internal(set) public var adjV2F = [[Int]]()
    internal(set) public var adjE2F = [[Int]]()
    internal(set) public var adjF2F = [[Int]]()
    internal(set) public var adjP2F = [[Int]]()
    
    internal(set) public var adjF2V = [[Int]]()
    internal(set) public var adjF2E = [[Int]]()
    internal(set) public var adjF2P = [[Int]]()
    
    public static var defaultInternalColor = vec4(1,197.0/255,161.0/255,1)
    
    public var internalColor = AbstractPolyhedralMesh.defaultInternalColor{
        didSet{
            didChange = true
        }
    }
    public var useInternalColor : Bool = true{
        willSet(newValue){
            if newValue{
                self.useLabelColor = false
            }
            didChange = true
        }
    }
    public var useLabelColor : Bool = false{
        willSet(newValue){
            didChange = true
        }
    }
    
    func build(vertices : [vec3], polys : [[Int]], labels : [Int]?){
        
        self.vertices.reserveCapacity(vertices.count)
        self.polys.reserveCapacity(polys.count)
        self.visiblePolys.reserveCapacity(polys.count)
        self.adjV2V.reserveCapacity(vertices.count)
        self.adjV2E.reserveCapacity(vertices.count)
        self.adjV2F.reserveCapacity(vertices.count)
        self.adjV2P.reserveCapacity(vertices.count)
        self.adjP2V.reserveCapacity(polys.count)
        self.adjP2F.reserveCapacity(polys.count)
        self.adjP2E.reserveCapacity(polys.count)
        self.adjP2P.reserveCapacity(polys.count)
        self.adjP2V.reserveCapacity(polys.count)
        self.adjP2V.reserveCapacity(polys.count)
        self.adjP2V.reserveCapacity(polys.count)
        self.adjP2V.reserveCapacity(polys.count)
        self.visiblePolys.reserveCapacity(polys.count)
        self.polyColors.reserveCapacity(polys.count)
        
        for vert in vertices{
            let _ = addVert(vert: vert)
        }
        for poly in polys{
            let _ = addPoly(poly: poly)
            polyColors.append(AbstractMesh.defaultColor)
        }
        
        adjP2V = polys
        adjF2V = faces
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
        self.labels = labels

    }
    
    public func updateNormals(){
        
        normals.removeAll()
        vertNormals.removeAll()
        
        for fid in faces.indices{
            let a = vertices[faces[fid][1]]-vertices[faces[fid][0]]
            var b : vec3
            if(faces[fid].count == 3){
                b = vertices[faces[fid][2]]-vertices[faces[fid][0]]
            }
            else{
                b = vertices[faces[fid][3]]-vertices[faces[fid][0]]
            }
            var normal = cross(a, b)
            normal /= length(normal)
            normals.append(normal)
        }
        
        for vid in vertices.indices{
            if vertIsOnSurf(vid: vid){
                var vNormal = vec3(0,0,0)
                var count : Int = 0
                for fid in adjV2F[vid]{
                    if faceIsOnSurf(fid: fid){
                        vNormal += normals[fid]
                        count += 1
                    }
                }
                vNormal/=Float(count)
                vertNormals.append(vNormal)
            }
            else{
                var normal = vec3(0,0,0)
                var count = 0
                for fid in adjV2F[vid]{
                    if faceIsVisible(fid: fid){
                        normal += normals[fid]
                        count += 1
                    }
                }
                normal /= Float(count)
                vertNormals.append(normal)
            }
        }
        
    }
    
    
    private func addVert(vert : vec3) -> Int{
        
        let vid = vertices.count
        vertices.append(vert)
        
        adjV2V.append([Int]())
        adjV2E.append([Int]())
        adjV2F.append([Int]())
        adjV2P.append([Int]())
        
        bbox.add(point: vert)
        
        return vid
    }
    
    public func facesAreAdjacent(f1: Int, f2 : Int) -> Bool{
        for eid in adjF2E[f1]{
            for nbr in adjE2F[eid]{
                if nbr == f2 {
                    return true
                }
            }
        }
        return false
    }
    
    public func faceID(face : [Int])-> Int{
        let query = face.sorted()
        guard let vid = face.first else{
            return -1
        }
        for fid in adjV2F[vid]{
            if(faces[fid].sorted() == query){
                return fid
            }
        }
        return -1
    }
    
    private func addEdge(edge : [Int]) -> Int{
        
        let eid = edges.count
        edges.append(edge)
        
        adjE2F.append([Int]())
        adjE2P.append([Int]())
        adjV2V[edge[0]].append(edge[1])
        adjV2V[edge[1]].append(edge[0])
        
        adjV2E[edge[0]].append(eid)
        adjV2E[edge[1]].append(eid)
        
        return eid
    }
    
    func addFace(face : [Int])-> Int{
        let fid = faces.count
        faces.append(face)
        
        adjF2E.append([Int]())
        adjF2F.append([Int]())
        adjF2P.append([Int]())
        
        for i in face.indices{
            let v0 = face[i]
            let v1 = face[(i+1)%face.count]
            var eid = edgeId(v0: v0, v1: v1)
            if eid == -1{
                eid = addEdge(edge:[v0, v1])
            }
        }
        
        for vid in face{
            adjV2F[vid].append(fid)
        }
        
        for i in face.indices{
            let v0 = face[i]
            let v1 = face[(i+1)%face.count]
            let eid = edgeId(v0: v0, v1: v1)
            
            for nbr in adjE2F[eid]{
                if(facesAreAdjacent(f1:fid, f2:nbr)){continue}
                adjF2F[nbr].append(fid)
                adjF2F[fid].append(nbr)

            }
            adjE2F[eid].append(fid)
            adjF2E[fid].append(eid)
        }
        
        return fid
    }
    
    private func addTet(poly : [Int])-> Int{
        
        let f1 = [poly[0], poly[2], poly[1]]
        let f2 = [poly[0], poly[1], poly[3]]
        let f3 = [poly[1], poly[2], poly[3]]
        let f4 = [poly[0], poly[3], poly[2]]
        
        var fid1 = faceID(face: f1)
        var fid2 = faceID(face: f2)
        var fid3 = faceID(face: f3)
        var fid4 = faceID(face: f4)
        
        if fid1 == -1 {fid1 = addFace(face: f1)}
        if fid2 == -1 {fid2 = addFace(face: f2)}
        if fid3 == -1 {fid3 = addFace(face: f3)}
        if fid4 == -1 {fid4 = addFace(face: f4)}
        
        let pid = polys.count

        adjP2E.append([Int]())
        adjP2F.append([Int]())
        adjP2P.append([Int]())
        
        for fid in [fid1, fid2, fid3, fid4]{
            adjF2P[fid].append(pid)
            adjP2F[pid].append(fid)
        }
        for vid in poly{
            adjV2P[vid].append(pid)
        }
        for fid in adjP2F[pid]{
            for eid in adjF2E[fid]{
                if !adjP2E[pid].contains(eid){
                    adjE2P[eid].append(pid)
                    adjP2E[pid].append(eid)

                }
            }
            for nbr in adjF2P[pid]{
                if pid != nbr && !adjP2P[pid].contains(nbr){
                    adjP2P[pid].append(nbr)
                    adjP2P[nbr].append(pid)
                    
                }
            }
        }
        
        visiblePolys.append(true)
        polys.append(poly)
        
        return pid
    }
    private func addHexa(poly : [Int])-> Int{
        
        let f1 = [poly[0], poly[3], poly[2], poly[1]]
        let f2 = [poly[1], poly[2], poly[6], poly[5]]
        let f3 = [poly[4], poly[5], poly[6], poly[7]]
        let f4 = [poly[3], poly[0], poly[4], poly[7]]
        let f5 = [poly[0], poly[1], poly[5], poly[4]]
        let f6 = [poly[2], poly[3], poly[7], poly[6]]
        
        var fid1 = faceID(face: f1)
        var fid2 = faceID(face: f2)
        var fid3 = faceID(face: f3)
        var fid4 = faceID(face: f4)
        var fid5 = faceID(face: f5)
        var fid6 = faceID(face: f6)

        
        if fid1 == -1 {fid1 = addFace(face: f1)}
        if fid2 == -1 {fid2 = addFace(face: f2)}
        if fid3 == -1 {fid3 = addFace(face: f3)}
        if fid4 == -1 {fid4 = addFace(face: f4)}
        if fid5 == -1 {fid5 = addFace(face: f5)}
        if fid6 == -1 {fid6 = addFace(face: f6)}
        
        let pid = polys.count
        adjP2E.append([Int]())
        adjP2F.append([Int]())
        adjP2P.append([Int]())
        
        for fid in [fid1, fid2, fid3, fid4, fid5, fid6]{
            adjF2P[fid].append(pid)
            adjP2F[pid].append(fid)
        }
        for vid in poly{
            adjV2P[vid].append(pid)
        }
        for fid in adjP2F[pid]{
            for eid in adjF2E[fid]{
                if !adjP2E[pid].contains(eid){
                    adjE2P[eid].append(pid)
                    adjP2E[pid].append(eid)
                    
                }
            }
            for nbr in adjF2P[pid]{
                if pid != nbr && !adjP2P[pid].contains(nbr){
                    adjP2P[pid].append(nbr)
                    adjP2P[nbr].append(pid)
                    
                }
            }
        }
        
        visiblePolys.append(true)
        polys.append(poly)
        return pid
        
    }
    
    private func addPoly(poly : [Int])-> Int{
        
        if poly.count == 4{
            return addTet(poly: poly)
        }
        else if poly.count == 8{
            return addHexa(poly: poly)
        }
        
        return -1
        
    }
    
    public func faceIsOnSurf(fid : Int) -> Bool{
        return adjF2P[fid].count == 1
    }
    
    public func vertIsOnSurf(vid : Int) -> Bool{
        for fid in adjV2F[vid]{
            if faceIsOnSurf(fid: fid){
                return true
            }
        }
        return false
    }
    
    public func edgeIsOnSurf(eid : Int) -> Bool{
        for fid in adjE2F[eid]{
            if faceIsOnSurf(fid: fid){
                return true
            }
        }
        return false
    }
    
    public func polyIsOnSurf(pid : Int) -> Bool{
        for fid in adjP2F[pid]{
            if faceIsOnSurf(fid: fid){
                return true
            }
        }
        return false
    }
    
    public func faceIsVisible(fid: Int) -> Bool{
        
        var faceTouchInvisiblePoly = false
        var inv = false
        var vis = false
        for pid in adjF2P[fid]{
            if !visiblePolys[pid]{
                inv = true
            }
            if visiblePolys[pid]{
                vis = true
            }
        }
        faceTouchInvisiblePoly = inv && vis
                
        return faceTouchInvisiblePoly || faceIsOnSurf(fid: fid)
    }
    
    public func faceCentroid(fid : Int) -> vec3{
        var sum = vec3(0,0,0)
        for vid in faces[fid]{
            sum+=vertices[vid]
        }
        sum/=Float(faces[fid].count)
        return sum
    }
    
    override public func pickFace(point: vec3) -> Int{
        var ordered = [(Float, Int)](repeating: (0,0), count: faces.count)
        for fid in faces.indices{
            //if !faceIsVisible(fid: fid) {continue}
            ordered[fid] = (point.dist(other: faceCentroid(fid: fid)), fid)
        }
        ordered.sort{
            return $0 < $1
        }
        
        return ordered[0].1
    }
    
    public func dig(id : Int){
        for pid in adjF2P[id]{
            if visiblePolys[pid]{
                visiblePolys[pid] = false
                didChange = true
                break
            }
        }
    }
    public func undig(id : Int){
        for pid in adjF2P[id]{
            if !visiblePolys[pid]{
                visiblePolys[pid] = true
                didChange = true
                break
            }
        }
    }
    
    
}
