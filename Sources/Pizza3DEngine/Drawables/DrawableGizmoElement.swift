//
//  DrawableGizmoElement.swift
//  GoodViewer
//
//  Created by Luca Pitzalis on 22/07/21.
//

import MetalKit

class DrawableGizmoElement: Node, Drawable{
    
    var geometry : Geometry
    private var triangles : [Vertex]!
    private var wireframe : [Vertex]!
    private var shading = Shading.smooth
    internal var material : Material
    private var depthStencilState : MTLDepthStencilState!
    
    private var buffer : MTLBuffer? = nil
    
    public init(mesh : Geometry){
        self.geometry = mesh
        material = Material(ambient: Color.white.xyz, diffuse: Color.white.xyz, specular: Color.white.xyz, shininess: 0, model: .flatColor)
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .always
        depthDescriptor.isDepthWriteEnabled = true
        depthStencilState = Renderer.device!.makeDepthStencilState(descriptor: depthDescriptor)!
        super.init()
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
        
        let buffers = getUniformsBuffer(device: device, projectionMatrix: camera.projectionMatrix(), viewTransformMatrix: camera.viewMatrix())
        
        encoder.setVertexBuffer(getGeometryBuffer(device: device), offset: 0, index: 0)
        encoder.setVertexBuffer(buffers.0, offset: 0, index: 1)
        encoder.setVertexBuffer(buffers.1, offset: 0, index: 2)
        encoder.setFragmentBuffer(getMaterialBuffer(device: device), offset: 0, index: 3)
        let textures = material.asTextures(device: device)
        encoder.setFragmentTextures(textures, range: 0..<3)
        //encoder.setDepthBias(5, slopeScale: 1.0, clamp: 0.1)
        
        encoder.setDepthStencilState(depthStencilState)
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: triangles.count)
        
        
    }
    

    
}
