using Godot;
using System.Collections.Generic;
using System;

public class game_utils : Node2D
{
  [Export] public Dictionary<String, Color> ship_colors;
  [Export] public Dictionary<String, int> side_layers;
  [Export] public Dictionary<String, Color> plasma_colors;
  [Export] public float delta;
  public float target_delta;
  public List<Node> ship_inputs = new List<Node>();
  public Node camera_input;
  public bool networking = false;
  public const int side_layer_count = 8;
  public int junk_layer;
  public Vector2 global_mouse_pos;
  
  public override void _Ready() {
    GD.Randomize();
    junk_layer = 0;
    for (int i = 0; i < side_layer_count; i++)
      junk_layer += get_plasma_layer(i);
    this.target_delta = 1.2f / Engine.TargetFps;
  }
  public override void _Process(float delta) {
    this.delta = delta;
    this.global_mouse_pos = this.GetGlobalMousePosition();
    if (Single.IsNaN(global_mouse_pos.x) || Single.IsNaN(global_mouse_pos.y))
      global_mouse_pos = Vector2.Zero;
  }
  
  public int get_layer_index(String side) {
    if ("junk".Equals(side))
      return -1;
    return side_layers[side];
  }
  public int get_plasma_layer(int layer_index) {
    if (layer_index == -1)
      return junk_layer;
    return 1 << (31 - layer_index);
  }
  public int get_plasma_mask(int layer_index) {
    if (layer_index == -1)
      return ~0;
    return ~get_plasma_layer(layer_index);
  }
  void connect_exit(string signal, Node arg) {
    arg.Connect("tree_exiting", this, signal, new Godot.Collections.Array {arg});
  }
  public bool register_camera_input(Node holder) {
    if (camera_input == null) {
      connect_exit("unregister_camera_input", holder);
      camera_input = holder;
      if (ship_inputs.Count == 0)
        return true;
    }
    holder.Call("lost_input");
    return false;
  }
  public void unregister_camera_input(Node holder) {
    if (holder == camera_input)
      camera_input = null;
  }
  
  public bool register_ship_input(Node holder) {
    var i = ship_inputs.IndexOf(holder);
    if (i >= 0)
      return i == 0;
    ship_inputs.Add(holder);
    connect_exit("unregister_ship_input", holder);
    if (ship_inputs.Count == 1) {
      if (camera_input != null)
        camera_input.Call("lost_input");
      return true;
    }
    return false;
  }
  public void unregister_ship_input(Node holder) {
    var i = ship_inputs.IndexOf(holder);
    if (i >= 0) {
      ship_inputs.RemoveAt(i);
      if (ship_inputs.Count == 0) {
        if (camera_input != null)
          camera_input.Call("gained_input");
      } else if (i == 0) {
        ship_inputs[0].Call("gained_input");
      }
    }
  }
  
  public bool is_enemy(String side, Node other) {
    var other_side = other.Get("side");
    return other_side != null && !other_side.Equals("junk") && !other_side.Equals(side);
  }
  
  public bool is_shootable(String side, Node other) {
    var other_side = other.Get("side");
    return other_side != null && !other_side.Equals(side);
  }
  
  public bool is_friend(String side, Node other) {
    var other_side = other.Get("side");
    return other_side != null && other_side.Equals(side);
  }
  
  /// Calculate the direction to move to dodge the specified projectiles
  /// - pos, speed: the state of our ship
  /// - sqr_gap: only try to dodge projectiles that would come within this gap to our ship
  /// - projectiles: list of projectiles
  /// - max_check: maximum number of projectiles to consider, used to improve performance at the cost of accuracy
  public Vector2 dodge_projectiles(Node2D self, float safe_distance_ratio, Godot.Collections.Array<Node2D> projectiles, Godot.Collections.Array<Node2D> removed, int max_check, float max_approach_time) {
    int max_remove;
    (max_check, max_remove) = get_max_remove(max_check, projectiles);
    removed.Clear();
    var total = Vector2.Zero; // The sum of results calculated from each of the contributing projectile
    var count = 0; // Number of contributing projectile to calculate the average
    var my_speed = (Vector2)self.Get("linear_velocity");
    var my_pos = self.GlobalPosition;
    var my_size = (float)self.Get("size");
    for (int i = 0; i < max_check; i++) {
      // Formula to calculate the approach time, the time that the projectile reaches nearest to our ship
      var diff = projectiles[i].GlobalPosition - my_pos;
      var vdiff = (Vector2)projectiles[i].Get("linear_velocity") - my_speed;
      var vdiff_sqr = vdiff.LengthSquared();
      if (vdiff_sqr > 0.0001) { // Projectile not moving relative to us, will take forever to reach
        float approach_time = - vdiff.Dot(diff) / vdiff_sqr;
        if (approach_time > 0 || approach_time > max_approach_time) { // Skips the case of approach_time <= 0, ie. the projectile is moving away from us
          var approach_diff = diff + vdiff * approach_time; // The difference vector when the projectile is nearest to our ship, this is the resulting vector of the projectile
          var length_sqr = approach_diff.LengthSquared();
          var safe_distance = safe_distance_ratio * ((float)projectiles[i].Get("size") + my_size);
          if (length_sqr < safe_distance * safe_distance) {
            count++;
            total += approach_diff / approach_time;
            continue;
          }
        }
      }
      // Mark projectiles that have moved pass or would not come near us to be moved to the back so that we are less likely to check them again in the future
      if (removed.Count < max_remove) { // We would not move more than the number of projectiles left unchecked, as moving them to the back would still leave them inside the max_check range
        removed.Add(projectiles[i]);
        projectiles[i] = null;
      }
    }
    append_removed_nodes(projectiles, removed);
    return count > 0 ? total / count : total;
  }
  public Vector3 dodge_bodies(Node2D self, float safe_distance_ratio, Godot.Collections.Array<Node2D> bodies, Godot.Collections.Array<Node2D> removed, int max_check, float max_approach_time) {
    int max_remove;
    (max_check, max_remove) = get_max_remove(max_check, bodies);
    removed.Clear();
    var total = Vector2.Zero; // The sum of results calculated from each of the contributing projectile
    var count = 0; // Number of contributing projectile to calculate the average
    var vdiff_total = 0f;
    var my_size = (float)self.Get("size");
    var velocity = self.Get("linear_velocity");
    try {
      for (int i = 0; i < max_check; i++) {
        // Formula to calculate the approach time, the time that the projectile reaches nearest to our ship
        var vdiff = (Vector2)bodies[i].Get("linear_velocity") - (Vector2)self.Get("linear_velocity");
        var vdiff_sqr = vdiff.LengthSquared();
        if (vdiff_sqr > 100) { // Projectile not moving relative to us, will take forever to reach
          var diff = bodies[i].GlobalPosition - self.GlobalPosition;
          float approach_time = - vdiff.Dot(diff) / vdiff_sqr;
          if (approach_time > 0 || approach_time > max_approach_time) { // Skips the case of approach_time <= 0, ie. the projectile is moving away from us
            vdiff_total += vdiff_sqr;
            var approach_diff = diff + vdiff * approach_time; // The difference vector when the projectile is nearest to our ship, this is the resulting vector of the projectile
            var length_sqr = approach_diff.LengthSquared();
            var safe_distance = safe_distance_ratio * vdiff_sqr * ((float)bodies[i].Get("size") + my_size);
            if (length_sqr < safe_distance * safe_distance) {
              count++;
              total += approach_diff * vdiff_sqr / approach_time;
              continue;
            }
          }
        }
        // Mark projectiles that have moved pass or would not come near us to be moved to the back so that we are less likely to check them again in the future
        if (removed.Count < max_remove) { // We would not move more than the number of projectiles left unchecked, as moving them to the back would still leave them inside the max_check range
          removed.Add(bodies[i]);
          bodies[i] = null;
        }
      }
      append_removed_nodes(bodies, removed);
      if (count > 0)
        total = total / count / 100;
      return new Vector3(total.x, total.y, vdiff_total);
    } catch (Exception e) {
      Console.WriteLine(e.ToString());
    }
    return new Vector3(0,0,0);
  }
  (int, int) get_max_remove(int max_check, Godot.Collections.Array<Node2D> source) {
    if (max_check > source.Count) {
      return (source.Count, 0);
    } else {
      return (max_check, Mathf.Min(source.Count - max_check, max_check)); // The capacity will be the smaller of the number of checked projectiles and the number of projectiles left unchecked
    }
  }
  void append_removed_nodes(Godot.Collections.Array<Node2D> dest, Godot.Collections.Array<Node2D> removed) {
    // Compact our destination array to leave empty spaces at the back
    for (int i = 0, delta = 0; i < dest.Count; i++) {
      if (dest[i] == null)
        delta++;
      else if (delta > 0)
        dest[i-delta] = dest[i];
    }
    // Add the removed nodes back to the array
    for (int i = 0; i < removed.Count; i++)
      dest[dest.Count - i - 1] = removed[i];
  }
  
  /// Calculate aim rotation for a direction, taking into account ship and bullet speed
  public float moving_aim(Vector2 velocity, Vector2 direction, float bullet_speed) {
    var speed = velocity.Length();
    var naive_angle = direction.Angle();
    return naive_angle - Mathf.Asin(Mathf.Clamp(Mathf.Sin(velocity.Angle() - naive_angle) * speed / bullet_speed, -1, 1));
  }
  
  /// Extrapolate the position of a target when our bullets reach it, assuming our ship is at origin
  /// - position, velocity, accel: the state of the target to calculate its trajectory
  /// - bullet_speed, ship_velocity: used to calculate the bullet speed toward the target, thus the time to reach
  ///   We need the ship speed because bullet speed is relative to the ship, not the global
  public Vector2 extrapolate(Vector2 position, Vector2 velocity, Vector2 accel, float bullet_speed, Vector2 ship_velocity) {
    var result = position;
    bullet_speed += position.Normalized().Dot(ship_velocity);
    float bullet_speed_sqr = bullet_speed * bullet_speed;
    /// Calculate the position of the target after the time for our bullet to reach the *current* extrapolation
    /// This would not be 100% accurate, because the time to reach the new extrapolation would be different from that of the old extrapolation
    /// Ideally we would repeat this step many times, until the time values converge
    void extrapolate_step() {
      var time_sqr = result.LengthSquared() / bullet_speed_sqr;
      result = position + velocity * Mathf.Sqrt(time_sqr) + accel * time_sqr / 2;
    }
    bullet_speed_sqr /= 1.5f; // As we only run the extrapolation step twice, compensate by a fixed ratio
    extrapolate_step();
    extrapolate_step();
    if (result.Dot(position) < 0) // Don't interpolate at all if it tells us to fire away from the target
      return position;
    return result;
  }
  public String fixed_length_format(long num) {
    int decimal_places = (int)(Mathf.Log(num)/Mathf.Log(10));
    string suffix = "";
    float normalized;
    if (decimal_places >= 12) {
      normalized = num / 1000000000000;
      suffix = "T";
    } else if (decimal_places >= 9) {
      normalized = num / 1000000000;
      suffix = "B";
    } else if (decimal_places >= 6) {
      normalized = num / 1000000;
      suffix = "M";
    } else if (decimal_places >= 3) {
      normalized = num / 1000;
      suffix = "K";
    } else normalized = num;
    string str = normalized > 10 || num <= 10 ? $"{normalized:0}" : $"{normalized:0.0}";
    return str + suffix;
  }
}
 
