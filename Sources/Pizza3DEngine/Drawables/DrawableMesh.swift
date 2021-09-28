//
//  Mesh.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 09/06/21.
//

import Metal
import MetalKit

public enum Shading : Int{
    case smooth = 0
    case flat  = 1
    case wireframe = 2
}

public class DrawableMesh: Node, Drawable{
    
    public var geometry : Geometry
    private var triangles : [Vertex]!
    private var wireframe : [Vertex]!
    public var shading = Shading.smooth{
        didSet{
            self.geometry.didChange = true
        }
    }
    public var material : Material
    private(set) var gizmo : Gizmo?
    private var depthStencilState : MTLDepthStencilState!
    
    public var center : vec3{
        let c = (worldTransformMatrix()*vec4(geometry.bbox.center, 1)).xyz
        return c
    }
    //public var isHidden = false
    
    public var wireframeEnabled = true
    
    private var buffer : MTLBuffer? = nil
    
    public init(mesh : Geometry){
        self.geometry = mesh
        material = Material.deafultMaterial
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .lessEqual
        depthDescriptor.isDepthWriteEnabled = true
        depthStencilState = Renderer.device!.makeDepthStencilState(descriptor: depthDescriptor)!
        super.init()
    }
    
    public func setGizmo(of type: GizmoType){
        switch(type){
            case .translation:
                gizmo = Gizmo.makeTranslationGizmo(for: self)
                break
            case .rotation:
                gizmo = Gizmo.makeRotationGizmo(for: self)
                break
            case .scale:
                gizmo = Gizmo.makeScaleGizmo(for: self)
                break
        }
    }
    
    public func removeGizmo(){
        gizmo = nil
    }
    
    func getTriangles() -> [Vertex]{
        if self.geometry.didChange{
            switch self.geometry{
                case let tri as TriangleMesh: self.triangles =  tri.getTriangles(shading: shading)
                case let quad as QuadMesh: self.triangles = quad.getTriangles(shading: shading)
                case let tet as TetMesh: self.triangles = tet.getTriangles(shading: shading)
                case let hex as HexMesh: self.triangles = hex.getTriangles(shading: shading)
                default:
                    self.triangles = []
            }
        }
     
        return self.triangles
    }
    func getWireframe() -> [Vertex]{
        if self.geometry.didChange{
            switch self.geometry{
                case let tri as TriangleMesh: self.wireframe =  tri.getWireframe()
                case let quad as QuadMesh: self.wireframe = quad.getWireframe()
                case let tet as TetMesh: self.wireframe = tet.getWireframe()
                case let hex as HexMesh: self.wireframe = hex.getWireframe()
                default:
                    self.wireframe = []
            }
        }
        return self.wireframe
    }
    
    
    private func getGeometryBuffer(device: MTLDevice) -> MTLBuffer{
        if self.geometry.didChange{
            let bytes = getTriangles()+getWireframe()
            self.geometry.didChange = false
            if (wireframe.count+triangles.count) == 0 {return buffer!}
            buffer = device.makeBuffer(bytes: bytes, length: (wireframe.count+triangles.count)*MemoryLayout<Vertex>.stride, options: [])!

        }
        return buffer!
    }
    
    private func getMaterialBuffer(device : MTLDevice) -> MTLBuffer{
        var mat = MaterialShader(ambientColor: vec3(0,0,0), diffuseColor: vec3(0,0,0), specularColor: vec3(0,0,0), shininess: material.shininess, model: material.model.rawValue)
        
        let size = MemoryLayout<MaterialShader>.stride
        let buffer = device.makeBuffer(bytes: &mat, length: size, options: [])
        return buffer!
    }
    
    //Change this to call it only once
    private func getUniformsBuffer(device : MTLDevice, projectionMatrix: matrix4, viewTransformMatrix : matrix4) -> (MTLBuffer, MTLBuffer){
        let wm = self.worldTransformMatrix()
        let modelmatrix = viewTransformMatrix*wm
        let matrices = [modelmatrix,modelmatrix.inverse, projectionMatrix, wm]
        let uniformBuffer = device.makeBuffer(bytes: matrices, length: MemoryLayout<matrix4>.stride*4, options: [])
        let idBuffer = device.makeBuffer(bytes: [identifier], length: MemoryLayout<Int>.size, options: [])
        return (uniformBuffer!, idBuffer!)
    }
    
    override func draw(encoder : MTLRenderCommandEncoder, device : MTLDevice, camera : Camera){
        
        encoder.setVertexBuffer(getGeometryBuffer(device: device), offset: 0, index: 0)
        let buffers = getUniformsBuffer(device: device, projectionMatrix: camera.projectionMatrix(), viewTransformMatrix: camera.viewMatrix())
        encoder.setVertexBuffer(buffers.0, offset: 0, index: 1)
        encoder.setVertexBuffer(buffers.1, offset: 0, index: 2)
        encoder.setFragmentBuffer(getMaterialBuffer(device: device), offset: 0, index: 3)
        let textures = material.asTextures(device: device)
        encoder.setFragmentTextures(textures, range: 0..<3)
        encoder.setDepthBias(0.1, slopeScale: 1.0, clamp: 0.1)
        
        encoder.setDepthStencilState(depthStencilState)
        if shading != .wireframe{
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: triangles.count)
        }
        if wireframeEnabled || shading == .wireframe{
            encoder.drawPrimitives(type: .line, vertexStart: triangles.count, vertexCount: wireframe.count)
        }
        
        gizmo?.draw(encoder: encoder, device: device, camera: camera, drawableMesh: self)
        
        if let children = self.children{
            for child in children{
                child.draw(encoder: encoder, device: device, camera: camera)
            }
        }
    }
    
}
