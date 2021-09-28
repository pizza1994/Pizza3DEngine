//
//  Gizmos.swift
//  GoodViewer
//
//  Created by Luca Pitzalis on 21/07/21.
//

import MetalKit

public enum GizmoType{
    
    case translation
    case rotation
    case scale
}

public class Gizmo{
    
    private(set) var elements = [DrawableGizmoElement]()
    private(set) var type : GizmoType!
    private(set) var associateddrawableID : Int!
    public var rotationSensitivity : Float = 20
    public var sensitivity : Float = 0.005
    private var originalPositions : [vec3]!
    private var maxDelta : Float!
    
    func draw(encoder : MTLRenderCommandEncoder, device : MTLDevice, camera : Camera, drawableMesh : DrawableMesh){
        for element in elements{
            element.draw(encoder: encoder, device: device, camera: camera)
        }
    }
    
    func move(xyz : vec3, drawableMesh : DrawableMesh){
        if type != .translation{
            return
        }
        drawableMesh.position += xyz
        center(drawableMesh: drawableMesh)
    }
    
    func rotate(xyz : vec3, drawableMesh : DrawableMesh){
        if type != .rotation{
            return
        }
        drawableMesh.rotation += xyz*rotationSensitivity
        center(drawableMesh: drawableMesh)
    }
    
    func scale(xyz : vec3, drawableMesh : DrawableMesh){
        if type != .scale{
            return
        }
       
        let oldBboxCenter = drawableMesh.geometry.bbox.center*drawableMesh.scale
        let oldDist = drawableMesh.position-oldBboxCenter
        drawableMesh.scale += xyz*(1.0/drawableMesh.geometry.bbox.diag)
        let eps : Float = 10e-7
        drawableMesh.scale = clamp(drawableMesh.scale, min: vec3(eps,eps,eps), max: vec3(Float.greatestFiniteMagnitude,Float.greatestFiniteMagnitude,Float.greatestFiniteMagnitude))
        let bboxCenter = drawableMesh.geometry.bbox.center*drawableMesh.scale
        let newDist = drawableMesh.position-bboxCenter
        let diff = newDist-oldDist
        
        drawableMesh.position += diff

        

    }
    
    private func center(drawableMesh : DrawableMesh){
        for (idx, element) in elements.enumerated(){
            element.position = originalPositions[idx]
            element.position += drawableMesh.center
        }
    }
    
    static func makeTranslationGizmo(for drawableMesh : DrawableMesh) -> Gizmo{
        
        let gizmo = Gizmo()
        
        let xArrow = try! TriangleMesh(filename: Bundle.module.url(forResource: "arrow1", withExtension: ".obj")!.path)
        let yArrow = try! TriangleMesh(filename: Bundle.module.url(forResource: "arrow2", withExtension: ".obj")!.path)
        let zArrow = try! TriangleMesh(filename: Bundle.module.url(forResource: "arrow3", withExtension: ".obj")!.path)
        let sphere = try! TriangleMesh(filename: Bundle.module.url(forResource: "sphere", withExtension: ".obj")!.path)
        
        xArrow.polyColors = Array<vec4>(repeating: vec4(1,0,0,1), count: xArrow.polys.count)
        yArrow.polyColors = Array<vec4>(repeating: vec4(0,1,0,1), count: yArrow.polys.count)
        zArrow.polyColors = Array<vec4>(repeating: vec4(0,0,1,1), count: zArrow.polys.count)
        
        
        let drawableXArrow = DrawableGizmoElement(mesh: xArrow)
        let drawableYArrow = DrawableGizmoElement(mesh: yArrow)
        let drawableZArrow = DrawableGizmoElement(mesh: zArrow)
        let drawableSphere = DrawableGizmoElement(mesh: sphere)
        
        let s : Float = (1.0 / xArrow.bbox.maxDelta)
        drawableSphere.scale = vec3(s,s,s)
        drawableXArrow.scale = vec3(s,s,s)
        drawableYArrow.scale = vec3(s,s,s)
        drawableZArrow.scale = vec3(s,s,s)
        
        drawableSphere.position -= sphere.bbox.center*s
        drawableXArrow.position -= sphere.bbox.center*s
        drawableYArrow.position -= sphere.bbox.center*s
        drawableZArrow.position -= sphere.bbox.center*s
        
        gizmo.originalPositions = [drawableXArrow.position, drawableYArrow.position, drawableZArrow.position, drawableSphere.position]
        gizmo.maxDelta = drawableXArrow.geometry.bbox.maxDelta
        
        gizmo.elements.append(drawableXArrow)
        gizmo.elements.append(drawableYArrow)
        gizmo.elements.append(drawableZArrow)
        gizmo.elements.append(drawableSphere)
        
        gizmo.center(drawableMesh: drawableMesh)
        
        gizmo.type = .translation
        gizmo.associateddrawableID = drawableMesh.identifier
        
        
        return gizmo
    }
    
    static func makeScaleGizmo(for drawableMesh : DrawableMesh) -> Gizmo{
        
        let gizmo = Gizmo()
        
        let xArrow = try! TriangleMesh(filename: Bundle.module.url(forResource: "scale1", withExtension: ".obj")!.path)
        let yArrow = try! TriangleMesh(filename: Bundle.module.url(forResource: "scale2", withExtension: ".obj")!.path)
        let zArrow = try! TriangleMesh(filename: Bundle.module.url(forResource: "scale3", withExtension: ".obj")!.path)
        let cube   = try! TriangleMesh(filename: Bundle.module.url(forResource: "cube", withExtension: ".obj")!.path)
        
        xArrow.polyColors = Array<vec4>(repeating: vec4(1,0,0,1), count: xArrow.polys.count)
        yArrow.polyColors = Array<vec4>(repeating: vec4(0,1,0,1), count: yArrow.polys.count)
        zArrow.polyColors = Array<vec4>(repeating: vec4(0,0,1,1), count: zArrow.polys.count)
        
        
        let drawableXArrow = DrawableGizmoElement(mesh: xArrow)
        let drawableYArrow = DrawableGizmoElement(mesh: yArrow)
        let drawableZArrow = DrawableGizmoElement(mesh: zArrow)
        let drawableCube = DrawableGizmoElement(mesh: cube)
        
        let s : Float = (1.0 / xArrow.bbox.maxDelta)
        drawableCube.scale = vec3(s,s,s)
        drawableXArrow.scale = vec3(s,s,s)
        drawableYArrow.scale = vec3(s,s,s)
        drawableZArrow.scale = vec3(s,s,s)
        
        drawableCube.position -= cube.bbox.center*s
        drawableXArrow.position -= cube.bbox.center*s
        drawableYArrow.position -= cube.bbox.center*s
        drawableZArrow.position -= cube.bbox.center*s
        
        gizmo.originalPositions = [drawableXArrow.position, drawableYArrow.position, drawableZArrow.position, drawableCube.position]
        
        gizmo.maxDelta = drawableXArrow.geometry.bbox.maxDelta
        
        gizmo.elements.append(drawableXArrow)
        gizmo.elements.append(drawableYArrow)
        gizmo.elements.append(drawableZArrow)
        gizmo.elements.append(drawableCube)
        
        gizmo.center(drawableMesh: drawableMesh)
        
        gizmo.type = .scale
        gizmo.associateddrawableID = drawableMesh.identifier
        
        
        return gizmo
    }
    
    static func makeRotationGizmo(for drawableMesh : DrawableMesh) -> Gizmo{
        
        let gizmo = Gizmo()
        
        let xRing = try! TriangleMesh(filename: Bundle.module.url(forResource: "ring1", withExtension: ".obj")!.path)
        let yRing = try! TriangleMesh(filename: Bundle.module.url(forResource: "ring2", withExtension: ".obj")!.path)
        let zRing = try! TriangleMesh(filename: Bundle.module.url(forResource: "ring3", withExtension: ".obj")!.path)
        //let cube = TriangleMesh(filename: Bundle.main.url(forResource: "cube", withExtension: ".obj")!.path)
        
        xRing.polyColors = Array<vec4>(repeating: vec4(1,0,0,1), count: xRing.polys.count)
        yRing.polyColors = Array<vec4>(repeating: vec4(0,1,0,1), count: yRing.polys.count)
        zRing.polyColors = Array<vec4>(repeating: vec4(0,0,1,1), count: zRing.polys.count)
        
        
        let drawableXRing = DrawableGizmoElement(mesh: xRing)
        let drawableYRing = DrawableGizmoElement(mesh: yRing)
        let drawableZRing = DrawableGizmoElement(mesh: zRing)
        
        let s : Float = (1.0 / xRing.bbox.maxDelta)
        drawableXRing.scale = vec3(s,s,s)
        drawableYRing.scale = vec3(s,s,s)
        drawableZRing.scale = vec3(s,s,s)
        
        drawableXRing.position -= xRing.bbox.center*s
        drawableYRing.position -= yRing.bbox.center*s
        drawableZRing.position -= zRing.bbox.center*s
        
        gizmo.originalPositions = [drawableXRing.position, drawableYRing.position, drawableZRing.position]
        
        gizmo.maxDelta = drawableXRing.geometry.bbox.maxDelta
                
        gizmo.elements.append(drawableXRing)
        gizmo.elements.append(drawableYRing)
        gizmo.elements.append(drawableZRing)
        
        gizmo.center(drawableMesh: drawableMesh)

        gizmo.type = .rotation
        gizmo.associateddrawableID = drawableMesh.identifier
        
        
        return gizmo
    }
    
}


