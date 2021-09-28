//
//  Scene.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 09/06/21.
//

import Metal
import MetalKit

public class Scene{
    
    public let rootNode : Node
    public var camera : Camera
    
    private(set) public var drawables : Dictionary<Int, Drawable>
    private(set) public var lights : Dictionary<Int, Light> {
        didSet{
            lightsShared.removeAll()
            for (_, light) in lights{
                lightsShared.append(light.getShaderLight())
            }
        }
    }
    
    private var lightsShared : [LightShader]!

    private var fragmentUniforms : FragmentUniforms!
    private var notificationCenter : NotificationCenter = .default
    

    public var center : vec3{
        var center = vec3(0,0,0)
        for (_, drawable) in drawables{
            if let drawableMesh = (drawable as? DrawableMesh){
                center+=drawableMesh.center
            }
        }
        center/=Float(drawables.count)
        return center
    }
    
    
    public init() {
        rootNode = Node()
        camera = Camera(settings: PerspectiveSettings.defaultSettings())
        drawables = Dictionary<Int, Drawable>()
        lightsShared = [LightShader]()
        lights = Dictionary<Int, Light>()
        
        notificationCenter.addObserver(self,
                                       selector: #selector(childAdded),
                                       name: .childAdded,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(childRemoved),
                                       name: .childRemoved,
                                       object: nil
        )
    }
    
    @objc private func childAdded(_ notification: Notification){
        
        if let drawable = notification.object as? Drawable{
            drawables[drawable.identifier] = drawable
        }
        else if let light = notification.object as? Light{
            lights[light.identifier] = light
        }
        
    }
    @objc private func childRemoved(_ notification: Notification){
        if let drawable = notification.object as? Drawable{
            drawables.removeValue(forKey: drawable.identifier)
        }
        else if let light = notification.object as? Light{
            lights.removeValue(forKey: light.identifier)
        }
    }
    
    private func getLightBuffers(device : MTLDevice) -> (MTLBuffer, MTLBuffer){
        
        let fragmentBuffer = device.makeBuffer(bytes: &fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size)!
        let lightBuffer = device.makeBuffer(bytes: lightsShared, length: MemoryLayout<LightShader>.stride*lightsShared.count)!
        return (fragmentBuffer, lightBuffer)
    }
    
    func draw(encoder : MTLRenderCommandEncoder, device: MTLDevice){
        if encoder.label == "StandardEncoder"{
            fragmentUniforms = FragmentUniforms(numLights: Int32(lightsShared.count), cameraPosition: camera.worldPosition)
            let buffers = getLightBuffers(device: device)
            encoder.setFragmentBuffer(buffers.0, offset: 0, index: 4)
            encoder.setFragmentBuffer(buffers.1, offset: 0, index: 5)
        }
        camera.pivot = center
        rootNode.draw(encoder: encoder, device: device, camera: camera)
    }
    
    
    public func getDrawable(id : Int) -> Drawable?{
        
        if let drawable = drawables[id]{
            return drawable
        }
        return nil
    }
    
    public func getGizmo(id : Int) -> (Gizmo, Int)?{
        for (_, drawable) in drawables{
            if let gizmo = (drawable as? DrawableMesh)?.gizmo{
                for (i, element) in gizmo.elements.enumerated(){
                    if element.identifier == id{
                        return (gizmo, i)
                    }
                }
            }
        }
        return nil
    }


    
}
