//
//  Canvas.swift
//  MetalEngine
//
//  Created by Luca Pitzalis on 11/06/21.
//

import Metal
import MetalKit

public class Canvas : MTKView{
    
    public var enableCameraControls = true
    public var cameraRotationSensitivity : Float = 0.0001
    public var cameraMoveSensitivity : Float = 0.01
    public var cameraZoomSensitivity : Float = 0.5
    
    public var cameraDamping = 0.1
    public var autoAdjustCamera = true
    public var scene : Scene?
    
    private var observer : NSKeyValueObservation?
    private var isZooming = false
    private var isMoving = false
    
    private var angularVelocity = vec2(0,0)
    private var angle = vec2(0,0)
    
    public var showFPS = true
    private var fpsLabel : UILabel!
    
    private var timer = 0.0
    
    public var pickType : PickType = .face
    private var canvasIsChanged = false
    
    //Picking Stuff
    private var depthTexture : MTLTexture!
    private var pickTexture : MTLTexture!
    private var pickRendererPassDescriptor : MTLRenderPassDescriptor!
    private var pickPipelineState : MTLRenderPipelineState!
    private var depthState : MTLDepthStencilState!
    private var commandQueue : MTLCommandQueue!
    
    //Gizmo Stuff
    private var giz_ : (Gizmo, Int)? =  nil
    
    public override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        fpsLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0,y: 0), size: CGSize(width: 10, height: 5)))
        self.addSubview(fpsLabel)
        setup()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        observer = self.layer.observe(\.bounds){
            object, _ in
            var settings : CameraSettings =  PerspectiveSettings.defaultSettings()
            if self.autoAdjustCamera{
                settings.aspectRatio = Float(self.bounds.size.width/self.bounds.size.height)
                self.scene?.camera.setSettings(settings)
            }
            self.canvasIsChanged = true
        }
        fpsLabel = UILabel(frame: CGRect(origin: CGPoint(x: 50,y: 50), size: CGSize(width: 100, height: 50)))
        fpsLabel.textColor = .black
        self.addSubview(fpsLabel)
        setup()
    }
    
    private func setup(){
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler))
        panGestureRecognizer.minimumNumberOfTouches = 1
        panGestureRecognizer.maximumNumberOfTouches = 3
        self.addGestureRecognizer(panGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(cameraZoom))
        self.addGestureRecognizer(pinchGestureRecognizer)
        self.framebufferOnly = false
        
    }
    
    
    @objc func cameraMove(_ sender: UIPanGestureRecognizer){
        if !enableCameraControls || isZooming{return}

        let velocity = sender.velocity(in: self)
        if sender.numberOfTouches == 1{
            angularVelocity = vec2((Float(velocity.x)*cameraRotationSensitivity), (Float(velocity.y)*cameraRotationSensitivity))
            angularVelocity = clamp(angularVelocity, min: -1, max: 1)
            
        }
        else if sender.numberOfTouches >= 2{
            isMoving = true
            let dx = Float(Float(velocity.x)*cameraMoveSensitivity)
            let dy = Float(Float(velocity.y)*cameraMoveSensitivity)
            
            let w = Float(self.bounds.width)
            let h = Float(self.bounds.height)
            let cam = scene!.camera
            
            let settings : CameraSettings = cam.projectionType == .Perspective ? cam.perspectiveSettings : cam.orthographicSettings

            let aspect = settings.aspectRatio
            let top = cam.projectionType == .Perspective ? Float(tanf(Float.degreeToRad(x: cam.perspectiveSettings.fov))) * cam.perspectiveSettings.near : cam.orthographicSettings.top
            let right = aspect*top
            let x = Float(2.0*dx/w*right/settings.near)
            let y = Float(-2.0*dy/h*top/settings.near)

            scene?.camera.position+=vec3(x, y, 0)
            isMoving = false
        }
        
    }
    
    private func gizmoMove(velocity : CGPoint, giz : (Gizmo, Int)){
        
        let (gizmo, offset) = giz
        
        let xVel = (Float(velocity.x)*cameraMoveSensitivity*gizmo.sensitivity)
        let yVel = (Float(velocity.y)*cameraMoveSensitivity * gizmo.sensitivity)
        
        let drawableMesh = scene?.drawables[gizmo.associateddrawableID] as! DrawableMesh
        
        
        switch(gizmo.type){
            case .translation:
                switch offset {
                    case 0:
                        gizmo.move(xyz: vec3((xVel),0,0), drawableMesh: drawableMesh)
                        break
                    case 1:
                        gizmo.move(xyz: vec3(0,(-yVel),0), drawableMesh: drawableMesh)
                        break
                    case 2:
                        gizmo.move(xyz: vec3(0,0,(xVel+yVel)), drawableMesh : drawableMesh)
                        break
                    case 3:
                        gizmo.move(xyz: vec3(xVel, yVel, (xVel+yVel)), drawableMesh : drawableMesh)
                    default:
                        break
                }
                break
            case .rotation:
                switch offset {
                    case 0:
                        gizmo.rotate(xyz: -vec3((xVel-yVel),0,0), drawableMesh: drawableMesh)
                        break
                    case 1:
                        gizmo.rotate(xyz: vec3(0,(xVel-yVel),0), drawableMesh: drawableMesh)
                        break
                    case 2:
                        gizmo.rotate(xyz: -vec3(0,0,(xVel+yVel)), drawableMesh : drawableMesh)
                        break
                    default:
                        break
                }
                break
            case .scale:
                switch offset {
                    case 0:
                        gizmo.scale(xyz: vec3((xVel),0,0), drawableMesh: drawableMesh)
                        break
                    case 1:
                        gizmo.scale(xyz: vec3(0,(-yVel),0), drawableMesh: drawableMesh)
                        break
                    case 2:
                        gizmo.scale(xyz: vec3(0,0,(xVel+yVel)), drawableMesh : drawableMesh)
                        break
                    case 3:
                        gizmo.scale(xyz: vec3(-(xVel+yVel),-(xVel+yVel),-(xVel+yVel)), drawableMesh : drawableMesh)
                    default:
                        break
                }
                break
            default:
                break
        }
        
    }
    
    @objc private func panGestureHandler(_ sender : UIPanGestureRecognizer){
        if sender.state == .ended{
            giz_ =  nil
            return
        }
        let giz = gizmoHitTest(point: sender.location(in: self))
        if giz_ != nil || giz != nil{
            if giz_ == nil {giz_ = giz}
            gizmoMove(velocity: sender.velocity(in: self), giz: giz_!)
        }
        else{
            cameraMove(sender)
        }
    }
    
    @objc private func cameraZoom(_ sender: UIPinchGestureRecognizer){
        if sender.state == .changed {
            if !enableCameraControls || isMoving {return}
            isZooming = true
            
            let velocity = sender.velocity
            let scale = sender.scale
            if scene?.camera.projectionType == .Perspective {
                if scale < 1{
                    if(scene?.camera.perspectiveSettings.fov ?? 180 < 179){scene?.camera.perspectiveSettings.fov+=cameraZoomSensitivity*velocity}
                }
                else{
                    if(scene?.camera.perspectiveSettings.fov ?? 0 > 1){scene?.camera.perspectiveSettings.fov-=cameraZoomSensitivity*velocity}
                }
            }
            else{
                if scale < 1{
                    scene?.camera.orthographicSettings.zoom = simd_clamp((scene?.camera.orthographicSettings.zoom)!-cameraZoomSensitivity/10, 0.01, Float.greatestFiniteMagnitude)
                }
                else{
                    scene?.camera.orthographicSettings.zoom += cameraZoomSensitivity/10
                }
            }
        }
        
        else{
            isZooming = false
        }
        
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    
    
    
        
    private func updateCameraMotion(){
        
        let eps : Float = 10e-5
        
        if length(angularVelocity) <= eps && length(angularVelocity) >= -eps{return}
        
        //let drawables = scene!.getAllDrawables()
        //let center = scene!.center
        
        angularVelocity = vec2(angularVelocity.x * (1-Float(cameraDamping)), angularVelocity.y * (1-Float(cameraDamping)))
        scene?.camera.rotate(degrees: vec3(Float(angularVelocity.y).truncatingRemainder(dividingBy: 360),
                                           Float(angularVelocity.x).truncatingRemainder(dividingBy: 360),
                                           0))

    }
    
    
    private func oneSecondTimer(deltaTime : Double){
        if(timer >= 1){
            timer = 0
        }
        timer+=deltaTime
    }
    
    func update(deltaTime : Double){
        
        
        if showFPS && timer >= 1{
            let fps = String(format: "%.01f", 1/deltaTime)
            self.fpsLabel.text = fps
            
        }
        
        updateCameraMotion()
        oneSecondTimer(deltaTime: deltaTime)
    }
    
    
    
}


extension Canvas{
    
    func createPickingRenderer(){
        
        commandQueue = self.device?.makeCommandQueue()
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type2D
        textureDescriptor.width  =  Int(self.bounds.width)
        textureDescriptor.height = Int(self.bounds.height)
        textureDescriptor.pixelFormat = .rgba32Float
        #if targetEnvironment(macCatalyst)
            textureDescriptor.storageMode = .managed
        #else
            textureDescriptor.storageMode = .shared
        #endif
        textureDescriptor.usage = [.renderTarget]

        pickTexture = self.device?.makeTexture(descriptor: textureDescriptor)
        
        textureDescriptor.textureType = .type2D
        textureDescriptor.width  =  Int(self.bounds.width)
        textureDescriptor.height = Int(self.bounds.height)
        textureDescriptor.pixelFormat = .depth32Float
        textureDescriptor.storageMode = .private
        textureDescriptor.usage = [.renderTarget]
        
        depthTexture = self.device?.makeTexture(descriptor: textureDescriptor)
        
        pickRendererPassDescriptor = MTLRenderPassDescriptor()
        pickRendererPassDescriptor.colorAttachments[0].texture = pickTexture
        pickRendererPassDescriptor.depthAttachment.texture = depthTexture
        pickRendererPassDescriptor.colorAttachments[0].loadAction = .clear
        pickRendererPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        pickRendererPassDescriptor.colorAttachments[0].storeAction = .store
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthState = self.device?.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        guard let library = try? self.device?.makeDefaultLibrary(bundle: Bundle.module)
        else { fatalError("Unable to create library") }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "pickVertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "pickFragmentShader")
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = pickTexture!.pixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        do{
            pickPipelineState = try self.device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        catch{
            print("Failed to create pipeline state!")
        }
        
        
    }
    
    public func gizmoHitTest(point : CGPoint) -> (Gizmo, Int)?{
        if canvasIsChanged{
            createPickingRenderer()
            canvasIsChanged = false
            print("changed")
        }
                
        var hit : [Float32] = [Float32](repeating: 0, count: 4)
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer?.enqueue()
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: pickRendererPassDescriptor)
        renderEncoder?.label = "PickingEncoder"
        renderEncoder?.setCullMode(.none)
        
        renderEncoder?.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(bounds.width), height: Double(bounds.height), znear: 0, zfar: 1))
        renderEncoder?.setRenderPipelineState(pickPipelineState)
        renderEncoder?.setDepthStencilState(depthState)
        
        scene?.draw(encoder: renderEncoder!, device: device!)
        
        renderEncoder?.endEncoding()
        #if targetEnvironment(macCatalyst)
        let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
        blitEncoder?.synchronize(resource: pickTexture)
        blitEncoder?.endEncoding()
        #endif
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        pickTexture.getBytes(&hit, bytesPerRow: Int(bounds.width)*MemoryLayout<Float32>.size*4, from: MTLRegionMake2D(Int(point.x), Int(point.y), 1, 1), mipmapLevel: 0)
        
        if hit[3] != 0.5{
            let id = Int(round(hit[3]))
            guard let gizmo = scene?.getGizmo(id: id) else{
                return nil
            }
            
            return gizmo
        }
        
        return nil
    }
    
    
    public func hitTest(point: CGPoint, type : PickType? = nil) -> HitResult?{
        
        if canvasIsChanged{
            createPickingRenderer()
            canvasIsChanged = false
            print("changed")
        }
        
        let pickType_ = type ?? pickType
        
        var hit : [Float32] = [Float32](repeating: 0, count: 4)
        //let pointer = UnsafeMutablePointer(mutating: hit)
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer?.enqueue()
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: pickRendererPassDescriptor)
        renderEncoder?.label = "PickingEncoder"
        renderEncoder?.setCullMode(.none)
        
        renderEncoder?.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(bounds.width), height: Double(bounds.height), znear: 0, zfar: 1))
        renderEncoder?.setRenderPipelineState(pickPipelineState)
        renderEncoder?.setDepthStencilState(depthState)
        
        scene?.draw(encoder: renderEncoder!, device: device!)
        
        renderEncoder?.endEncoding()
        #if targetEnvironment(macCatalyst)
            let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
            blitEncoder?.synchronize(resource: pickTexture)
            blitEncoder?.endEncoding()
        #endif
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()

        pickTexture.getBytes(&hit, bytesPerRow: Int(bounds.width)*MemoryLayout<Float32>.size*4, from: MTLRegionMake2D(Int(point.x), Int(point.y), 1, 1), mipmapLevel: 0)
        
        if hit[3] != 0.5{
            let id = Int(round(hit[3]))
            guard let drawable = scene?.getDrawable(id: id) else{
                return nil
            }
    
            let query = vec3(hit[0], hit[1], hit[2])
            var item : Int
            switch pickType_{
                case .vertex:
                    item = drawable.geometry.pickVert(point: query)
                case .edge:
                    item = drawable.geometry.pickEdge(point: query)
                case .face:
                    item = drawable.geometry.pickFace(point: query)
                case .poly:
                    item = drawable.geometry.pickPoly(point: query)
                case .geometry:
                    item = id
            }
            
            return HitResult(point: query, item: item, type: pickType_, drawableId : id)
        }
        
        return nil
        
    }
    
}
extension Canvas{
    public func screenshot() -> CGImage?{
        return self.currentDrawable?.texture.toImage()
    }
}


//https://stackoverflow.com/questions/35115605/how-can-i-make-screen-shot-image-from-mtkview-in-ios
extension MTLTexture {
    
    func bytes() -> UnsafeMutableRawPointer {
        let width = self.width
        let height   = self.height
        let rowBytes = self.width * 4
        let p = malloc(width * height * 4)
        
        self.getBytes(p!, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        
        return p!
    }
    
    public func toImage() -> CGImage? {
        let p = bytes()
        
        let pColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
        
        let selftureSize = self.width * self.height * 4
        let rowBytes = self.width * 4
        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
            return
        }
        let provider = CGDataProvider(dataInfo: nil, data: p, size: selftureSize, releaseData: releaseMaskImagePixelData)
        let cgImageRef = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes, space: pColorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)!
        
        return cgImageRef
    }
}

