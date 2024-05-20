import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'game_over_overlay.dart';

void main() {
  runApp(GameWidget(
    game: ArkanoidGame(),
    overlayBuilderMap: {
      'gameOver': (context, ArkanoidGame game) {
        return GameOverOverlay(
          onRestart: () {
            game.overlays.remove('gameOver');
            game.restart();
          },
        );
      },
    },
  ));
}

class ArkanoidGame extends FlameGame with TapDetector, HasCollisionDetection {
  late Paddle _paddle;
  late Ball _ball;
  late List<Block> _blocks;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _startGame();
  }

  void _startGame() {
    _paddle = Paddle(position: Vector2(size.x / 2 - 50, size.y - 30));
    _ball = Ball(onLose: onLose, position: Vector2(size.x / 2, size.y / 2));
    _blocks = List.generate(10, (i) => Block(Vector2(i * 50.0 + 10, 50)));

    add(_paddle);
    add(_ball);
    _blocks.forEach(add);
  }

  @override
  void onTapDown(TapDownInfo info) {
    _paddle.moveTo(info.eventPosition.global);
  }

  void onLose() {
    overlays.add('gameOver');
  }

  void restart() {
    removeAll(children);
    _startGame();
  }
}

class Paddle extends SpriteComponent
    with HasGameRef<ArkanoidGame>, CollisionCallbacks {
  static final double _speed = 400;
  Vector2 _targetPosition = Vector2.zero();

  Paddle({required Vector2 position})
      : super(position: position, size: Vector2(100, 20)) {
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('paddle.png');
  }

  void moveTo(Vector2 position) {
    _targetPosition = Vector2(position.x - size.x / 2, y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_targetPosition != Vector2.zero()) {
      final distance = (_targetPosition - position).length;
      if (distance > _speed * dt) {
        final direction = (_targetPosition - position).normalized();
        position += direction * _speed * dt;
        // Ограничение движения платформы по краям экрана
        if (position.x < 0) position.x = 0;
        if (position.x + size.x > gameRef.size.x)
          position.x = gameRef.size.x - size.x;
      } else {
        position = _targetPosition;
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Ball) {
      other.velocity.y = -other.velocity.y.abs(); // Отскок мяча вверх
    }
  }
}

class Ball extends SpriteComponent
    with HasGameRef<ArkanoidGame>, CollisionCallbacks {
  Vector2 velocity = Vector2(200, -200);
  final VoidCallback onLose;

  Ball({required this.onLose, required Vector2 position})
      : super(size: Vector2(20, 20), position: position) {
    add(CircleHitbox());
  }

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('ball.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if (x <= 0 || x + size.x >= gameRef.size.x) {
      velocity.x = -velocity.x;
    }
    if (y <= 0) {
      velocity.y = -velocity.y;
    }
    if (y >= gameRef.size.y) {
      // Ball is out of bounds
      onLose();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Paddle) {
      velocity.y = -velocity.y.abs(); // Отскок мяча вверх
    } else if (other is Block) {
      velocity.y = -velocity.y;
      other.removeFromParent();
    }
  }
}

class Block extends SpriteComponent with CollisionCallbacks {
  Block(Vector2 position) : super(position: position, size: Vector2(40, 20)) {
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('block.png');
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Ball) {
      removeFromParent();
    }
  }
}
