use std::process::Command;
use std::io::Write;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Generate a random 32-byte key for JWT signing
    let output = Command::new("openssl")
        .args(&["rand", "-base64", "32"])
        .output()?;
    
    if !output.status.success() {
        return Err("Failed to generate JWT secret".into());
    }
    
    let jwt_secret = String::from_utf8(output.stdout)?;
    
    // Write to file
    let mut file = std::fs::File::create("jwt_secret.txt")?;
    file.write_all(jwt_secret.trim().as_bytes())?;
    
    println!("Created JWT secret and saved to jwt_secret.txt");
    
    Ok(())
}
