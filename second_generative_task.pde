import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer player;
FFT fft;

int numLayers = 4;
float baseRadius = 200;

ArrayList<PVector[]> layerPoints = new ArrayList<PVector[]>();  

void setup() {
  size(1920, 1080, P3D);
  smooth(8);
  colorMode(HSB, 255);
  blendMode(ADD);  

  minim = new Minim(this);
  player = minim.loadFile("Lost Sky x Anna Yvette - Carry On _ Trap _ NCS - Copyright Free Music.mp3", 2048);
  fft = new FFT(player.bufferSize(), player.sampleRate());
  fft.logAverages(16, 4);
  player.play();
}

void draw() {
  background(0);
  lights();
  translate(width / 2, height / 2, -150);
  rotateX(PI / 6);
  rotateZ(frameCount * 0.002);

  fft.forward(player.mix);
  float rms = computeRMS(player.mix) * 500;
  float pulse = baseRadius + rms + 20 * sin(radians(frameCount * 2));

  layerPoints.clear();

  
  for (int layer = 0; layer < numLayers; layer++) {
    float radius = pulse * (1.0 - 0.15 * layer);
    PVector[] points = drawSmoothWaveCircle(radius, layer);
    layerPoints.add(points);

    
    if (layer > 0) {
      drawConnections(layerPoints.get(layer - 1), points, layer);
    }
  }
}

float computeRMS(AudioBuffer buffer) {
  float sum = 0;
  for (int i = 0; i < buffer.size(); i++) {
    sum += sq(buffer.get(i));
  }
  return sqrt(sum / buffer.size());
}

PVector[] drawSmoothWaveCircle(float radius, int layerIndex) {
  float zOffset = map(layerIndex, 0, numLayers - 1, 0, -50);
  PShape shape = createShape();
  shape.beginShape();
  shape.noFill();
  shape.strokeWeight(2);

  int detail = 120;
  PVector[] points = new PVector[detail + 1];

  for (int i = 0; i <= detail; i++) {
    int index = int(map(i, 0, detail, 0, fft.avgSize() - 1));
    float angle = map(i, 0, detail, 0, TWO_PI);
    float amp = fft.getAvg(index) * (1.3 + 0.6 * sin(radians(frameCount + i * 6)));
    float r = radius + amp * pow(0.85, layerIndex);

    float x = r * cos(angle);
    float y = r * sin(angle);
    points[i] = new PVector(x, y, zOffset);

    float hue = map(sin(radians(frameCount * 2 + layerIndex * 40)), -1, 1, 180, 255);
    shape.stroke(hue, 200, 255, 180);
    shape.curveVertex(x, y, zOffset);
  }

  shape.endShape(CLOSE);
  shape(shape);

  return points;
}

void drawConnections(PVector[] layerA, PVector[] layerB, int layerIndex) {
  strokeWeight(0.5);
  int detail = layerA.length;

  for (int i = 0; i < detail; i++) {
    PVector p1 = layerA[i];
    PVector p2 = layerB[i];

    float hue = map(layerIndex, 1, numLayers - 1, 180, 255);
    stroke(hue, 150, 255, 100); 
    line(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z);
  }
}

void stop() {
  player.close();
  minim.stop();
  super.stop();
}
