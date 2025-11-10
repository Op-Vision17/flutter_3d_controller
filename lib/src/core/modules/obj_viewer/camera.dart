import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

class Camera {
  Camera({
    Vector3? position,
    Vector3? target,
    Vector3? up,
    this.fov = 60.0,
    this.near = 0.1,
    this.far = 1000,
    this.zoom = 1.0,
    this.viewportWidth = 100.0,
    this.viewportHeight = 100.0,
  }) {
    if (position != null) position.copyInto(this.position);
    if (target != null) target.copyInto(this.target);
    if (up != null) up.copyInto(this.up);
  }

  final Vector3 position = Vector3(0.0, 0.0, -10.0);
  final Vector3 target = Vector3(0.0, 0.0, 0.0);
  Vector3 up = Vector3(0.0, 1.0, 0.0);
  double fov;
  double near;
  double far;
  double zoom;
  double viewportWidth;
  double viewportHeight;

  double get aspectRatio => viewportWidth / viewportHeight;

  Matrix4 get lookAtMatrix {
    return makeViewMatrix(position, target, up);
  }

  Matrix4 get projectionMatrix {
    final double top = near * math.tan(radians(fov) / 2.0) / zoom;
    final double bottom = -top;
    final double right = top * aspectRatio;
    final double left = -right;
    return makeFrustumMatrix(left, right, bottom, top, near, far);
  }

  /*
  * Vertical rotation can be locked via the lockVertical parameter
  * When locked, only horizontal rotation around Y-axis is allowed
  * */
  void trackBall(Vector2 from, Vector2 to,
      [double sensitivity = 1.0, bool lockVertical = false]) {
    if (lockVertical) {
      // LOCKED MODE: Only horizontal rotation
      final double x = -(to.x - from.x) * sensitivity / (viewportWidth * 0.5);

      // Calculate the eye vector
      Vector3 eye = position - target;
      double radius = eye.length; // Store the radius to maintain distance

      // Only rotate around Y-axis (vertical axis)
      if (x.abs() > 0.0001) {
        // Small threshold to avoid unnecessary calculations
        // Calculate rotation angle
        final double angle = x;

        // Create rotation quaternion only for Y-axis
        Quaternion q = Quaternion.axisAngle(Vector3(0, 1, 0), angle);

        // Rotate the position around the target
        Vector3 relativePosition = position - target;
        q.rotate(relativePosition);

        // Update position while maintaining the same distance from target
        position.setFrom(target + relativePosition.normalized() * radius);
      }
    } else {
      // NORMAL MODE: Full rotation (original behavior)
      final double x = -(to.x - from.x) * sensitivity / (viewportWidth * 0.5);
      final double y = (to.y - from.y) * sensitivity / (viewportHeight * 0.5);

      Vector2 delta = Vector2(x, y);

      Vector3 eye = position - target;
      Vector3 eyeDirection = eye.normalized();
      Vector3 upDirection = up.normalized();

      Vector3 sidewaysDirection = upDirection.cross(eyeDirection).normalized();
      sidewaysDirection.scale(delta.x);
      Vector3 upVector = upDirection.clone();
      upVector.scale(delta.y);
      Vector3 moveDirection = sidewaysDirection + upVector;
      final double angle = moveDirection.length;

      if (angle > 0) {
        Vector3 axis = moveDirection.normalized();
        axis = upDirection.cross(axis);
        Quaternion q = Quaternion.axisAngle(axis, angle);
        q.rotate(position);
      }
    }

    // Always keep up vector pointing upward
    stabilizeUpVector();
  }

  void stabilizeUpVector() {
    up = Vector3(0, 1, 0);
  }
}
