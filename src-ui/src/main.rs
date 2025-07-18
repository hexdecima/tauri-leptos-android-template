use leptos::{mount::mount_to_body, prelude::*, view};

fn main() {
    mount_to_body(|| view! { <h1>meow</h1> });
}
