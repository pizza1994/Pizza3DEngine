//
//  Node.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 09/06/21.
//

import Metal
import MetalKit
import simd

public enum NodeType{
    case empty
    case drawableMesh
    case pointLight
    case spotLight
    case sunLight
    case ambientLight
    case gizmoElement
}


public class Node{
    private static var nodeCounter = 0
    public let identifier : Int //UUID().hashValue.simplifyHash(n: 7)
    public var type : NodeType{
        switch self{
            case _ as DrawableMesh: return .drawableMesh
            case _ as PointLight: return .pointLight
            case _ as SpotLight: return .spotLight
            case _ as SunLight: return .sunLight
            case _ as AmbientLight: return .ambientLight
            case _ as DrawableGizmoElement : return .gizmoElement
            default:
                return .empty
        }
    }
    private (set) public var parent : Node? = nil
    private (set) public var children : [Node]? = nil
    private (set) public var model : matrix4!
    
    private var notificationCenter : NotificationCenter = .default

    
    public var position : vec3 = vec3(0,0,0) {
        didSet{update()}
    }
    public var worldPosition : vec3{
        return (worldTransformMatrix()*vec4(0,0,0,1)).xyz;
    }
    public var rotation : vec3 = vec3(0,0,0)
    {
        didSet{update()}
    }
    public var scale : vec3 = vec3(1,1,1)
    {
        didSet{update()}
    }
    
    public init(position: vec3, rotation: vec3, scale: vec3) {
        self.position = position
        self.rotation = rotation
        self.scale    = scale
        identifier = Node.nodeCounter
        Node.nodeCounter += 1
        update()
    }
    
    public init() {
        self.position = vec3(0,0,0)
        self.rotation = vec3(0,0,0)
        self.scale = vec3(1,1,1)
        identifier = Node.nodeCounter
        Node.nodeCounter += 1
        update()
    }
    
    public func add(child node: Node){
        
        if children == nil{
            children = [Node]()
        }
        node.parent = self
        children?.append(node)
        
        notificationCenter.post(name: .childAdded, object: node)
    
    }
    
    public func removeFromParent(){
        
        if self.parent == nil {return}
        removeChildren()
        self.parent?.children?.removeAll(where:{$0 == self})
        notificationCenter.post(name: .childRemoved, object: self)
        
    }
    
    public func removeChildren(){
        if let _ = self.children{
            for child in self.children!{
                child.removeFromParent()
            }
            self.children!.removeAll();
        }
    }
    
    func update(){
        model = modelMatrix()
    }
    
    private func modelMatrix() -> matrix4 {
        let translation = matrix4.makeTranslation(x: position.x, y: position.y, z: position.z)
        let rotation = matrix4.makeRotation(x: Float.degreeToRad(x: rotation.x), y: Float.degreeToRad(x: rotation.y), z: Float.degreeToRad(x: rotation.z))
        let scale = matrix4.makeScale(x: scale.x, y: scale.y, z: scale.z)
        return translation*rotation*scale
    }
    
    public func worldTransformMatrix() -> matrix4 {
        if let parent = parent {
            return parent.worldTransformMatrix() * model
        }
        return model
        
    }
    
    func draw(encoder : MTLRenderCommandEncoder, device : MTLDevice, camera : Camera){
        
        if let children = self.children{
            for child in children{
                child.draw(encoder: encoder, device: device, camera: camera)
            }
        }
        
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    
}

extension Notification.Name {
    static var childAdded: Notification.Name {
        return .init(rawValue: "Node.childAdded")
    }
    
    static var childRemoved: Notification.Name {
        return .init(rawValue: "Node.childRemoved")
    }
    
}
