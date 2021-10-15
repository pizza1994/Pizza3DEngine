//
//  AbstractMesh.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 11/06/21.
//
import simd

public class AABB{
    private(set) public var min : vec3 = vec3(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
    private(set) public var max : vec3 = vec3(-Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude)
    
    public var center : vec3{
        return (min+max)/2
    }
    public var deltaX : Float{
        return max.x-min.x
    }
    public var deltaY : Float{
        return max.y-min.y
    }
    public var deltaZ : Float{
        return max.z-min.z
    }
    public var maxDelta : Float{
        
        return Swift.max(deltaY, Swift.max(deltaX, deltaZ))
    }
    public var diag : Float{
        return self.min.dist(other: self.max)
    }
    
    public func add(point : vec3){
        self.min = simd.min(point, min)
        self.max = simd.max(point, max)
    }
}

public struct Slice{
    var xMin : Float = 0, xMax : Float = 100
    var yMin : Float = 0, yMax : Float = 100
    var zMin : Float = 0, zMax : Float = 100
    
    var invertX : Bool = false
    var invertY : Bool = false
    var invertZ : Bool = false
    
    static func == (lhs: Slice, rhs: Slice) -> Bool {
        return lhs.xMin == rhs.xMax && lhs.yMin == rhs.yMax && lhs.zMin == rhs.zMax && lhs.invertX == rhs.invertX && lhs.invertY == rhs.invertY && lhs.invertZ == rhs.invertZ
               
    }
    
}
//The mesh classes are partially inspired by https://github.com/mlivesu/cinolib/
public class AbstractMesh{
    
    var vertices = [vec3](){
        didSet{
            didChange = true
        }
    }
    public var didChange = false
    internal(set) public var polys = [[Int]]()
    internal(set) public var edges = [[Int]]()
    internal(set) public var visiblePolys = [Bool]()
    
    internal(set) public var adjV2V = [[Int]]()
    internal(set) public var adjV2E = [[Int]]()
    internal(set) public var adjV2P = [[Int]]()
    
    internal(set) public var adjE2V = [[Int]]()
    internal(set) public var adjE2E = [[Int]]()
    internal(set) public var adjE2P = [[Int]]()
    
    internal(set) public var adjP2V = [[Int]]()
    internal(set) public var adjP2E = [[Int]]()
    internal(set) public var adjP2P = [[Int]]()
    
    public var meshName = "No Name"
    
    internal(set) public var bbox = AABB()
    internal(set) public var currentSlice = Slice()
    
    internal(set) public var polyColors = [vec4](){
        
        didSet{
            didChange = true
        }
    }
    internal(set) public var labelColors = Dictionary<Int, vec4>()
    
    public var wireframeColor = vec4(0,0,0,1) {
        didSet{
            self.didChange = true
        }
    }
    
    internal(set) public var normals = [vec3]()
    internal(set) public var vertNormals = [vec3]()
    
    internal(set) public var labels : [Int]?
    
    static public let defaultColor = Color.to01Scale(color: vec4(176,222,255,255))
    
    
    public func slice(x : (Float, Float), y: (Float, Float), z: (Float, Float), invertX : Bool = false, invertY : Bool = false, invertZ : Bool = false){
        
        let tmpSlice = Slice(xMin: x.0, xMax: x.1, yMin: y.0, yMax: y.1, zMin: z.0, zMax: z.1, invertX: invertX, invertY: invertY, invertZ: invertZ)
        
        if didChange || tmpSlice == currentSlice {return}
        
        currentSlice = tmpSlice
        
        for pid in polys.indices{
            visiblePolys[pid] = true
            let centroid =  polyCentroid(pid: pid)
            if (centroid.x < x.0 || centroid.x > x.1) != invertX{
                visiblePolys[pid] = false
            }
            if !(centroid.y < y.0 || centroid.y > y.1) != !invertY{
                visiblePolys[pid] = false
            }
            if !(centroid.z < z.0 || centroid.z > z.1) != !invertZ{
                visiblePolys[pid] = false
            }
        }
        
        didChange = true
    }
    
    public func polyCentroid(pid : Int) -> vec3{
        var sum = vec3(0,0,0)
        for vid in polys[pid]{
            sum+=vertices[vid]
        }
        sum/=Float(polys[pid].count)
        return sum
    }
    
    public func edgeId(v0: Int, v1: Int) -> Int{
        
        let v2e = adjV2E[v0]
        for eid in v2e{
            if edges[eid][0] == v1 || edges[Int(eid)][1] == v1{
                return eid
            }
        }
        
        return -1
    }
    
    public func polysAreAdjacent(p0: Int, p1: Int) -> Bool{
        var tmpSet1 = Set<Int>()
        var tmpSet2 = Set<Int>()
        for vid in polys[p0]{
            tmpSet1.insert(vid)
        }
        for vid in polys[p1]{
            tmpSet2.insert(vid)
        }
        
        return tmpSet1.intersection(tmpSet2).count == 2
        
    }
    
    func computeVertNormals(tri : [vec3]) -> [vec3]{
        let tmp = tri[0]
        let a = tri[1]-tmp
        let b = tri[2]-tmp
        
        let cross = cross(a, b)
        let faceNormal = cross / length(cross)
        return [faceNormal, faceNormal, faceNormal]
    }
    
    func getTriangles(shading: Shading) -> [Vertex]{
        return []
    }
    func getWireframe() -> [Vertex]{
        return []
    }
    
    public func polyAABB(pid : Int) -> AABB{
        let aabb = AABB()
        for vid in polys[pid]{
            aabb.add(point: vertices[vid])
        }
        return aabb
    }
    
    public func sampleEdge(_ eid : Int, at : Float) -> vec3{
        let v0 = vertices[edges[eid][0]]
        let v1 = vertices[edges[eid][1]]
        
        return at*v0+(1-at)*v1
    }
    
    public func pickPoly(point: vec3) -> Int{
        
        var nearestPid : Int = 0
        var distance : Float = Float.greatestFiniteMagnitude
        
        for pid in polys.indices{
            
            //if !visiblePolys[pid] {continue}
                
            let centroid = polyCentroid(pid: pid)
            let dist = point.dist(other: centroid)
            if dist < distance{
                distance = dist
                nearestPid = pid
            }
        }
        
        return nearestPid
    }
    
    public func pickVert(point: vec3) -> Int{
        var ordered = [(Float, Int)](repeating: (0,0), count: vertices.count)
        for vid in vertices.indices{
            ordered[vid] = (point.dist(other: vertices[vid]), vid)
        }
        ordered.sort{
            return $0 < $1
        }
        
        return ordered[0].1
    }
    public func pickEdge(point: vec3) -> Int{
        var ordered = [(Float, Int)](repeating: (0,0), count: edges.count)
        for eid in edges.indices{
            ordered[eid] = (point.dist(other: sampleEdge(eid, at: 0.5)), eid)
        }
        ordered.sort{
            return $0 < $1
        }
        
        return ordered[0].1
    }
    
    public func pickFace(point: vec3) -> Int{
        return pickPoly(point: point)
    }
    
    
    public func reset(){
        for pid in visiblePolys.indices{
            visiblePolys[pid] = true
        }
        let bb = bbox
        currentSlice = Slice(xMin: bb.min.x, xMax: bb.max.x, yMin: bb.min.y, yMax: bb.max.y, zMin: bb.min.z, zMax: bb.max.z, invertX: false, invertY: false, invertZ: false)
        didChange = true
    }
    
    public func setPolyColors(colors : [vec4]){
        assert(colors.count == 1 || colors.count == polys.count)
        
        for i in polyColors.indices{
            polyColors[i] = colors.count == 1 ? colors.first! : colors[i]
        }
    }
    
    public func setPolyColor(pid: Int, color : vec4){
        
        polyColors[pid] = color
        didChange = true
    }
    
    public func setLabel(pid: Int, label : Int){
        labels?[pid] = label
        didChange = true
    }
    
    public func setLabelColor(label: Int, color : vec4){
        labelColors[label] = color
        didChange = true
    }
    
    
}

extension Vertex{
    
    static func build(pos : vec3 = vec3(0,0,0), color : vec4 = vec4(1,1,1,1), normal : vec3 = vec3(0,1,0), uv : vec2 = vec2(0,0), polyCentroid : vec3 = vec3(0,0,0), primitiveType : Int = 0) -> Vertex{
        
        return Vertex(pos: pos, color: color, normal: normal, uv: uv, polyCentroid: polyCentroid, primitiveType: Int32(primitiveType))
    }
    
}
