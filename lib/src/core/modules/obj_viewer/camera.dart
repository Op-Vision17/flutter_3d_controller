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
  * The bug related to unwanted rotation was fixed by M.R.Davari on October 5, 2024.
  * */
  void trackBall(Vector2 from, Vector2 to, [double sensitivity = 1.0]) {
    // Only allow horizontal rotation - lock vertical
    final double x = -(to.x - from.x) * sensitivity / (viewportWidth * 0.5);
    final double y = 0.0; // Lock vertical rotation

    Vector2 delta = Vector2(x, y);

    Vector3 eye = position - target;
    Vector3 eyeDirection = eye.normalized();
    Vector3 upDirection = up.normalized();

    // Only horizontal rotation
    Vector3 sidewaysDirection = upDirection.cross(eyeDirection).normalized();
    sidewaysDirection.scale(delta.x);
    Vector3 moveDirection = sidewaysDirection;
    final double angle = moveDirection.length;

    if (angle > 0) {
      Vector3 axis = Vector3(0, 1, 0); // Only Y-axis rotation
      Quaternion q = Quaternion.axisAngle(axis, angle);
      q.rotate(position);
    }

    stabilizeUpVector();
  }

  void stabilizeUpVector() {
    up = Vector3(0, 1, 0);
  }
}
