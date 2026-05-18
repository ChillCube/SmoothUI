# SmoothUI API Reference
Generated: 2026-05-18

A base node for smooth UI nodes used by ChillCube

## Class: SmoothUI
**Inherits:** [Sprite2D](https://docs.godotengine.org/en/stable/classes/class_sprite2d.html)

Base class for UI elements with smooth movement and relative positioning

### ⚙️ Inspector Variables (Exported)
| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| **use_relative_positioning** | `bool` | `true` | Relative positioning ensures the UI stays on the same spot even when the screens are different. |
| **anchor_point** | `Vector2` | `Vector2(0.5, 0.5)` | The normalized screen coordinate (0.0 to 1.0) used as the element's origin. |
| **local_position** | `Vector2` | `Vector2.ZERO` | The local offset relative to the anchor point when the element is visible. |
| **off_screen_position** | `Vector2` | `Vector2(0.0, 0.6)` | The local offset relative to the anchor point when the element is hidden. |
| **is_hidden** | `bool` | `false` | If true, the element moves to its off-screen position. |
| **bounce** | `bool` | `false` | Enables an elastic bounce effect when the element reaches its target position. |
| **rotation_on** | `bool` | `false` | If enabled, the element will slightly tilt/rotate during movement. |
| **speed** | `float` | `10` | The speed multiplier for the smooth movement transition. |
| **use_smooth_movement** | `bool` | `true` | Whether to use smooth tweening or instant positioning. |

---

