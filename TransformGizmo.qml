import QtQuick.Scene3D 2.0
import QtQuick 2.2 as QQ2
import QtQuick.Window 2.13

import Qt3D.Core 2.0
import Qt3D.Render 2.0
import Qt3D.Input 2.0
import Qt3D.Logic 2.0
import Qt3D.Extras 2.0
import Qt3D.Animation 2.9

Entity {
    id: root
    property real size: 1
    readonly property real beamRadius: size * 0.05
    property var layer
    property var cameraController
    property var targetTransform
    property real linearSpeed: 0.01
    property real angularSpeed: 2.0
    property bool visible: false

    enum Mode {
        Translation,
        Rotation,
        Scale
    }

    property int mode: TransformGizmo.Mode.Translation

    Transform {
        id: ownTransform
    }

    components: [ownTransform, layer]

    function qmlInstanceOf(obj, className) {
        return obj.toString().indexOf(className + "(") === 0;
    }

    function attachTo(entity) {
        if(!(entity instanceof Entity)) return
        for(var i = 0; i < entity.components.length; i++) {
            if(qmlInstanceOf(entity.components[i], "Qt3DCore::QTransform")) {
                targetTransform = entity.components[i]
                ownTransform.translation = targetTransform.translation
                visible = true
                return
            }
        }
    }

    function angleAxisToQuat(angle, x, y, z) {
        var a = angle * Math.PI / 180.0;
        var s = Math.sin(a * 0.5);
        var c = Math.cos(a * 0.5);
        return Qt.quaternion(c, x * s, y * s, z * s);
    }

    function multiplyQuaternion(q1, q2) {
        return Qt.quaternion(q1.scalar * q2.scalar - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z,
                             q1.scalar * q2.x + q1.x * q2.scalar + q1.y * q2.z - q1.z * q2.y,
                             q1.scalar * q2.y + q1.y * q2.scalar + q1.z * q2.x - q1.x * q2.z,
                             q1.scalar * q2.z + q1.z * q2.scalar + q1.x * q2.y - q1.y * q2.x);
    }

    function translate(dx, dy, dz) {
        if(!targetTransform) return
        targetTransform.translation.x += dx
        targetTransform.translation.y += dy
        targetTransform.translation.z += dz
        ownTransform.translation.x += dx
        ownTransform.translation.y += dy
        ownTransform.translation.z += dz
    }

    function rotate(dx, dy, dz) {
        if(!targetTransform) return
        targetTransform.rotation = multiplyQuaternion(angleAxisToQuat(dx, 1, 0, 0), targetTransform.rotation)
        targetTransform.rotation = multiplyQuaternion(angleAxisToQuat(dy, 0, 1, 0), targetTransform.rotation)
        targetTransform.rotation = multiplyQuaternion(angleAxisToQuat(dz, 0, 0, 1), targetTransform.rotation)
    }

    function scale(dx, dy, dz) {
        if(!targetTransform) return
        targetTransform.scale3D.x += dx
        targetTransform.scale3D.y += dy
        targetTransform.scale3D.z += dz
    }

    Entity {
        components: [
            SphereMesh {
                radius: beamRadius * 2
                enabled: visible
            },
            PhongMaterial {
                diffuse: "#999"
            },
            ObjectPicker {
                onClicked: {
                    switch(mode)
                    {
                    case TransformGizmo.Mode.Translation: mode = TransformGizmo.Mode.Rotation; break;
                    case TransformGizmo.Mode.Rotation: mode = TransformGizmo.Mode.Scale; break;
                    case TransformGizmo.Mode.Scale: mode = TransformGizmo.Mode.Translation; break;
                    }
                }
            }
        ]
    }

    Entity {
        id: xBeamEntity
        components: [Transform {rotationZ: -90}]
        TransformGizmoBeam {
            visible: root.visible
            gizmo: root
            color: "#f33"
            onDragStart: cameraController.enabled = false
            onDrag: {
                switch(mode) {
                case TransformGizmo.Mode.Translation: translate(linearSpeed * dy, 0, 0); break
                case TransformGizmo.Mode.Rotation: rotate(angularSpeed * dy, 0, 0); break
                case TransformGizmo.Mode.Scale: scale(linearSpeed * dy, 0, 0); break
                }
            }
            onDragEnd: cameraController.enabled = true
        }
    }

    Entity {
        id: yBeamEntity
        components: [Transform {rotationZ: 0}]
        TransformGizmoBeam {
            visible: root.visible
            gizmo: root
            color: "#3f3"
            onDragStart: cameraController.enabled = false
            onDrag: {
                switch(mode) {
                case TransformGizmo.Mode.Translation: translate(0, linearSpeed * dy, 0); break
                case TransformGizmo.Mode.Rotation: rotate(0, angularSpeed * dy, 0); break
                case TransformGizmo.Mode.Scale: scale(0, linearSpeed * dy, 0); break
                }
            }
            onDragEnd: cameraController.enabled = true
        }
    }

    Entity {
        id: zBeamEntity
        components: [Transform {rotationX: 90}]
        TransformGizmoBeam {
            visible: root.visible
            gizmo: root
            color: "#33f"
            onDragStart: cameraController.enabled = false
            onDrag: {
                switch(mode) {
                case TransformGizmo.Mode.Translation: translate(0, 0, linearSpeed * dy); break
                case TransformGizmo.Mode.Rotation: rotate(0, 0, angularSpeed * dy); break
                case TransformGizmo.Mode.Scale: scale(0, 0, linearSpeed * dy); break
                }
            }
            onDragEnd: cameraController.enabled = true
        }
    }

    TransformGizmoPlane {
        id: xyPlane
        visible: root.visible
        gizmo: root
        axes: [0, 1]
        onDragStart: cameraController.enabled = false
        onDrag: translate(linearSpeed * dx, linearSpeed * dy, 0)
        onDragEnd: cameraController.enabled = true
    }

    TransformGizmoPlane {
        id: xzPlane
        visible: root.visible
        gizmo: root
        axes: [0, 2]
        onDragStart: cameraController.enabled = false
        onDrag: translate(linearSpeed * dx, 0, linearSpeed * dy)
        onDragEnd: cameraController.enabled = true
    }

    TransformGizmoPlane {
        id: yzPlane
        visible: root.visible
        gizmo: root
        axes: [1, 2]
        onDragStart: cameraController.enabled = false
        onDrag: translate(0, linearSpeed * dx, linearSpeed * dy)
        onDragEnd: cameraController.enabled = true
    }
}