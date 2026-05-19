use bevy::input::mouse::MouseMotion;
use bevy::prelude::*;
use bevy::window::{CursorGrabMode, PrimaryWindow};

#[derive(Component)]
struct Spinner;

#[derive(Component)]
struct FlyCamera {
    speed: f32,
    sensitivity: f32,
    yaw: f32,
    pitch: f32,
}

impl Default for FlyCamera {
    fn default() -> Self {
        Self {
            speed: 5.0,
            sensitivity: 0.002,
            yaw: 0.0,
            pitch: 0.0,
        }
    }
}

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    commands.spawn((
        Mesh3d(meshes.add(Plane3d::default().mesh().size(8.0, 8.0))),
        MeshMaterial3d(materials.add(Color::srgb(0.3, 0.5, 0.3))),
    ));

    commands.spawn((
        Mesh3d(meshes.add(Cuboid::new(1.0, 1.0, 1.0))),
        MeshMaterial3d(materials.add(Color::srgb(0.8, 0.2, 0.2))),
        Transform::from_xyz(0.0, 0.5, 0.0),
        Spinner,
    ));

    commands.spawn((
        PointLight {
            shadows_enabled: true,
            intensity: 2_000_000.0,
            ..default()
        },
        Transform::from_xyz(4.0, 6.0, 4.0),
    ));

    let start = Transform::from_xyz(-3.0, 3.0, 5.0).looking_at(Vec3::ZERO, Vec3::Y);
    let (yaw, pitch, _) = start.rotation.to_euler(EulerRot::YXZ);
    commands.spawn((
        Camera3d::default(),
        start,
        FlyCamera {
            yaw,
            pitch,
            ..default()
        },
    ));
}

fn spin(time: Res<Time>, mut query: Query<&mut Transform, With<Spinner>>) {
    for mut transform in &mut query {
        transform.rotate_y(time.delta_secs());
    }
}

fn toggle_cursor_grab(
    mouse: Res<ButtonInput<MouseButton>>,
    keys: Res<ButtonInput<KeyCode>>,
    mut windows: Query<&mut Window, With<PrimaryWindow>>,
) {
    let Ok(mut window) = windows.single_mut() else {
        return;
    };
    if mouse.just_pressed(MouseButton::Left) {
        window.cursor_options.grab_mode = CursorGrabMode::Locked;
        window.cursor_options.visible = false;
    }
    if keys.just_pressed(KeyCode::Escape) {
        window.cursor_options.grab_mode = CursorGrabMode::None;
        window.cursor_options.visible = true;
    }
}

fn fly_camera(
    time: Res<Time>,
    keys: Res<ButtonInput<KeyCode>>,
    mut mouse_motion: EventReader<MouseMotion>,
    windows: Query<&Window, With<PrimaryWindow>>,
    mut query: Query<(&mut Transform, &mut FlyCamera)>,
) {
    let Ok((mut transform, mut cam)) = query.single_mut() else {
        return;
    };
    let cursor_locked = windows
        .single()
        .map(|w| w.cursor_options.grab_mode == CursorGrabMode::Locked)
        .unwrap_or(false);

    if cursor_locked {
        let mut delta = Vec2::ZERO;
        for ev in mouse_motion.read() {
            delta += ev.delta;
        }
        cam.yaw -= delta.x * cam.sensitivity;
        cam.pitch = (cam.pitch - delta.y * cam.sensitivity)
            .clamp(-std::f32::consts::FRAC_PI_2 + 0.01, std::f32::consts::FRAC_PI_2 - 0.01);
        transform.rotation = Quat::from_euler(EulerRot::YXZ, cam.yaw, cam.pitch, 0.0);
    } else {
        mouse_motion.clear();
    }

    let mut direction = Vec3::ZERO;
    let forward = *transform.forward();
    let right = *transform.right();
    if keys.pressed(KeyCode::KeyW) {
        direction += forward;
    }
    if keys.pressed(KeyCode::KeyS) {
        direction -= forward;
    }
    if keys.pressed(KeyCode::KeyD) {
        direction += right;
    }
    if keys.pressed(KeyCode::KeyA) {
        direction -= right;
    }
    if keys.pressed(KeyCode::Space) {
        direction += Vec3::Y;
    }
    if keys.pressed(KeyCode::ControlLeft) {
        direction -= Vec3::Y;
    }
    if direction != Vec3::ZERO {
        transform.translation += direction.normalize() * cam.speed * time.delta_secs();
    }
}

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, setup)
        .add_systems(Update, (spin, toggle_cursor_grab, fly_camera))
        .run();
}
