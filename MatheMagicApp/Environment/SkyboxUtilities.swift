//import SwiftUI
//import RealityKit
//
///// A simple SwiftUI container that hosts a RealityView.
//struct ContentView: View {
//    var body: some View {
//        MyRealityView()
//            .ignoresSafeArea()
//    }
//}
//
///// A view containing the RealityView and configuration logic.
//struct MyRealityView: View {
//    @State private var realityView = RealityView()
//
//    var body: some View {
//        // Use a custom container to display the RealityView in SwiftUI.
//        RealityViewContainer(realityView: $realityView)
//            .task {
//                await configureSkybox(resourceName: "MySkybox")
//                addDirectionalLight()
//                addPointLight()
//                addSpotLight()
//            }
//    }
//
//    /// 1. Configure a skybox environment on the RealityView.
//    ///
//    /// - Parameter resourceName: The name of your environment resource (e.g., .hdr file).
//    func configureSkybox(resourceName: String) async {
//        do {
//            // Use the async initializer instead of the synchronous load method
//            let skyboxResource = try await EnvironmentResource(named: resourceName)
//            
//            // Set the environment using RealityViewEnvironment.skybox
//            realityView.environment = RealityViewEnvironment.skybox(skyboxResource)
//        } catch {
//            print("Error loading skybox resource: \(error)")
//        }
//    }
//
//
//    /// 2. Add a directional light to the scene.
//    ///
//    /// - Parameters:
//    ///   - color: Light color (default: .white).
//    ///   - intensity: Intensity in lumens per square meter (default: 2145.7078).
//    func addDirectionalLight(color: UIColor = .white,
//                             intensity: Float = 2145.7078) {
//        // Create the directional light component.
//        let directionalLight = DirectionalLightComponent(color: color, intensity: intensity)
//        
//        // Wrap it in an Entity and add to an Anchor.
//        let lightEntity = Entity()
//        lightEntity.components.set(directionalLight)
//        
//        // For demonstration, tilt the light by 45 degrees.
//        lightEntity.transform.rotation = simd_quatf(angle: .pi / 4, axis: [1, 0, 0])
//
//        // Create an anchor and add the lightEntity as a child.o
//        let anchor = AnchorEntity(world: .zero)
//        anchor.addChild(lightEntity)
//        
//        // Add to the RealityView's scene.
//        realityView.scene.addAnchor(anchor)
//    }
//
//    /// 3. Add a point light to the scene.
//    ///
//    /// - Parameters:
//    ///   - color: Light color (default: .white).
//    ///   - intensity: Light brightness in lumens (default: 26963.76).
//    ///   - attenuationRadius: Distance at which the light no longer illuminates (default: 10.0).
//    func addPointLight(color: UIColor = .white,
//                       intensity: Float = 26963.76,
//                       attenuationRadius: Float = 10.0) {
//        // Create the point light component.
//        let pointLight = PointLightComponent(
//            color: color,
//            intensity: intensity,
//            attenuationRadius: attenuationRadius
//        )
//
//        // Wrap it in an Entity and add to an Anchor.
//        let lightEntity = Entity()
//        lightEntity.components.set(pointLight)
//
//        // Optionally position the light or transform it if desired.
//        // lightEntity.transform.translation = [0, 1, 0] // example
//
//        let anchor = AnchorEntity(world: .zero)
//        anchor.addChild(lightEntity)
//        realityView.scene.addAnchor(anchor)
//    }
//
//    /// 4. Add a spotlight to the scene.
//    ///
//    /// - Parameters:
//    ///   - color: Light color (default: .white).
//    ///   - intensity: Light brightness (default: 6740.94).
//    ///   - innerAngleInDegrees: The inner cone angle of full intensity (default: 45.0).
//    ///   - outerAngleInDegrees: The angle at which the spotlight's intensity is zero (default: 60.0).
//    ///   - attenuationRadius: Distance at which the light no longer illuminates (default: 10.0).
//    func addSpotLight(color: UIColor = .white,
//                      intensity: Float = 6740.94,
//                      innerAngleInDegrees: Float = 45.0,
//                      outerAngleInDegrees: Float = 60.0,
//                      attenuationRadius: Float = 10.0) {
//        // Create the spotlight component.
//        let spotLight = SpotLightComponent(
//            color: color,
//            intensity: intensity,
//            innerAngleInDegrees: innerAngleInDegrees,
//            outerAngleInDegrees: outerAngleInDegrees,
//            attenuationRadius: attenuationRadius
//        )
//
//        // Wrap it in an Entity and add to an Anchor.
//        let lightEntity = Entity()
//        lightEntity.components.set(spotLight)
//
//        // Optionally transform the light if needed.
//        // lightEntity.transform.translation = [0, 2, 0] // example
//
//        let anchor = AnchorEntity(world: .zero)
//        anchor.addChild(lightEntity)
//        realityView.scene.addAnchor(anchor)
//    }
//}
//
//
////func loadSkybox(into content: RealityViewContent, for destination: Destination, with iblComponent: ImageBasedLightComponent) {
////    let rootEntity = Entity()
////
////    // Load the skybox texture and apply it to the rootEntity.
////    rootEntity.addSkybox(for: destination)
////
////    // Add the rootEntity with the skybox to the scene.
////    content.add(rootEntity)
////
////    // Set the ImageBasedLightComponent to the rootEntity.
////    rootEntity.components.set(iblComponent)
////
////    // Set the ImageBasedLightReceiverComponent to receive the ImageBasedLight.
////    rootEntity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: rootEntity))
////}
//
//// LOAD SKYBOX
////loadSkybox(into: content, for: .forest, with: iblComponent)
//
//func configureSkybox2(resourceName: String, content: RealityView.Content) async {
//    do {
//        // Load the HDR texture resource asynchronously
//        let textureResource = try await TextureResource(named: resourceName)
//        
//        // Create an unlit material with the HDR texture
//        var material = UnlitMaterial()
//        material.color = .init(texture: .init(resource: textureResource))
//        
//        // Create a large sphere to act as the skybox
//        let skyboxMesh = MeshResource.generateSphere(radius: 1000, segments: 50)
//        
//        // Create a model entity with the sphere mesh and unlit material
//        let skyboxEntity = ModelEntity(mesh: skyboxMesh, materials: [material])
//        
//        // Flip the sphere's normals inward to make it viewable from inside
//        skyboxEntity.scale = SIMD3<Float>(x: -1, y: 1, z: 1)
//        
//        // Add the skybox entity to the RealityView content
//        content.add(skyboxEntity)
//    } catch {
//        print("Error loading skybox resource: \(error)")
//    }
//}
//
//
//
