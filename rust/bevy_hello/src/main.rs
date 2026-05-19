use bevy::prelude::*;

#[derive(Component)]
struct Spinner;

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

    commands.spawn((
        Camera3d::default(),
        Transform::from_xyz(-3.0, 3.0, 5.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));
}

fn spin(time: Res<Time>, mut query: Query<&mut Transform, With<Spinner>>) {
    for mut transform in &mut query {
        transform.rotate_y(time.delta_secs());
    }
}

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, setup)
        .add_systems(Update, spin)
        .run();
}
