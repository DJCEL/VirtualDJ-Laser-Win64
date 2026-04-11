// New Laser_Club_v9 function
void Laser_Club_v9() {
    // Parameters for the green laser lines
    float lineHeight = 1.0;
    float glareHeight = 0.5;
    float centerX = 0.0;
    float centerY = 0.0;

    // Create 6 laser lines emanating from the center
    for (int i = 0; i < 6; i++) {
        float angle = (PI / 3.0) * i;  // Spread the lines evenly
        float xOffset = cos(angle);
        float yOffset = sin(angle);

        // Line position
        float linePositionY = lineHeight * yOffset;
        float glarePositionY = glareHeight * yOffset;

        // Render the laser line
        DrawLaser(centerX + xOffset, linePositionY, green);

        // Add glare effect at mid-height
        if (glarePositionY == glareHeight) {
            DrawGlare(centerX + xOffset, glarePositionY);
        }
    }
}

void ps_main() {
    // Replace active shader call to use Laser_Club_v9
    Laser_Club_v9();
}