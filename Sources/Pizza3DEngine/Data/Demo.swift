//
//  File.swift
//  
//
//  Created by Luca Pitzalis on 28/09/21.
//

import MetalKit

public enum DemoMesh : String{
    
    case Hexmesh  = "demo_hex.mesh"
    case Tetmesh  = "demo_tet.mesh"
    case Trimesh  = "demo_tri.obj"
    case Quadmesh = "demo_quad.obj"
    
}

extension Scene{
    
    public class func demoScene(device : MTLDevice?, demoMesh : DemoMesh?) -> Scene{
        
        
        let verts = [vec3(-0.5,-0.5,0.5), vec3(0.5,-0.5,0.5), vec3(0.5,-0.5,-0.5), vec3(-0.5,-0.5,-0.5),
                     vec3(-0.5,0.5,0.5), vec3(0.5,0.5,0.5), vec3(0.5,0.5,-0.5), vec3(-0.5,0.5,-0.5)]
        let polys : [[Int]] = [[0,1,2,3,4,5,6,7]]
        
        var mesh : AbstractMesh!
        var drawableMesh : DrawableMesh!
        
        switch(demoMesh){
            case .Hexmesh:
                let resource = ""+(demoMesh?.rawValue.split(separator: ".").first)!
                let ext = "."+(demoMesh?.rawValue.split(separator: ".").last)!
                
                mesh = try! HexMesh(filename: Bundle.module.url(forResource: resource, withExtension: ext)!.path)
                drawableMesh = DrawableMesh(mesh: (mesh as! HexMesh))
                
            default:
                mesh = HexMesh(vertices: verts, polys: polys, labels: nil)
                drawableMesh = DrawableMesh(mesh: (mesh as! HexMesh))
        }
        
        mesh.meshName = "Demo"
        
        
        let scene = Scene()
        let camera = Camera(settings: PerspectiveSettings.defaultSettings())

        camera.position = vec3(0,0,-3)
        camera.rotation = vec3(0,0,0)
        
        scene.camera = camera
        let s = 1.0 / drawableMesh.geometry.bbox.diag
        drawableMesh.scale = vec3(s,s,s)
        drawableMesh.position -= drawableMesh.geometry.bbox.center
        drawableMesh.material.ambient = vec3(1,1,1)
        drawableMesh.material.shininess = 32
        drawableMesh.material.specular = vec3(1,1,1)
        drawableMesh.material.model = .phong
        
        
        
        drawableMesh.wireframeEnabled = true
        
        scene.rootNode.add(child: drawableMesh)
        
        
        let ambient = AmbientLight()
        ambient.color = vec3(1,1,1)
        ambient.intensity = 0.7
        
        let keyLight = PointLight()
        keyLight.position = vec3(-2,2,2)
        keyLight.color = vec3(1,1,1)
        keyLight.intensity = 0.4
        
        let fillLight = PointLight()
        fillLight.position = vec3(3,2,3)
        fillLight.color = vec3(1,1,1)
        fillLight.intensity = 0.4
        
        let backLight = PointLight()
        backLight.position = vec3(0,2,-2)
        backLight.color = vec3(1,1,1)
        backLight.intensity = 0.4
        
        scene.rootNode.add(child: keyLight)
        scene.rootNode.add(child: fillLight)
        scene.rootNode.add(child: backLight)
        
        scene.rootNode.add(child: ambient)
        
        
        
        
        return scene
        
    }
}
