float fDeltaTime, fElapsedTime; //<>//
boolean bGameStarted = false;
boolean bGameWon = false;

boolean bLaunchMode = false;
float fDogPower = -1;
float atan2X, atan2Y, cosX, sinY, theta; // variables for calculating launch angle from mousepos
float fBallDiameter = 15;
float fBallRadius = fBallDiameter / 2;
int iCurrentBall = 0;
int iBallTotal = 0;
float[][][] fAllActiveBall = new float[10][2][2]; // 3D array - 10 for amount of balls, 2 for position and velocity, 2 values for x, y
PVector pvHolePos;

int iDogVelX = 300;
PVector pvDogPos; // where the z value is direction of movement
int iLawnSize = 20;
int[] iMapDogWalkA = {22, 19, 4, 88, 76}; // width, height, tile size in pixels, width in pixels, height in pixels
String sMapDogWalkA = "";
char[] cMapDogWalkA = {'A'};
String sMapDogWalkB = "";
char[] cMapDogWalkB = {'A'};
int iDogWalkCount = 0;
char[] cMapDogWalk = {'A'};
float fDogMiddlePoint;

void setup() {
  size(952, 714); 
  frameRate(60);
  noiseSeed((long)random(0, 10000));
  noiseDetail(4, 0.0001);
  for (int x = 0; x < fAllActiveBall.length; x ++) {
    fAllActiveBall[x] = new float[][]{{-50.0, -50.0}, {0.0, 0.0}}; // population is necessary to avoid phantom balls in top left
  }
  pvHolePos = new PVector(random(fBallDiameter * 2, width - fBallDiameter * 2), random(fBallDiameter * 2, height * 0.7));
  pvDogPos = new PVector(width / 2 - iMapDogWalkA[3] / 2, height * 0.85, 1.0);
  sMapDogWalkA += "////////////B/BBBB/B//"; // tilemaps representing a dog in pixels
  sMapDogWalkA += "///////////B#B####B#B/"; // art inspired by Temmie Chang's "annoying dog"
  sMapDogWalkA += "///////////B########B/";
  sMapDogWalkA += "//////////B#########B/";
  sMapDogWalkA += "/////////BB####B##B##B";
  sMapDogWalkA += "///////BB############B";
  sMapDogWalkA += "/BBBBBB#########BB###B";
  sMapDogWalkA += "B#############B##B#B#B";
  sMapDogWalkA += "/BB############BBBB##B";
  sMapDogWalkA += "//B##################B";
  sMapDogWalkA += "//B##################B";
  sMapDogWalkA += "//B##################B";
  sMapDogWalkA += "//B##################B";
  sMapDogWalkA += "///B#################B";
  sMapDogWalkA += "///B################B/";
  sMapDogWalkA += "///B##BB##BBBB##BB##B/";
  sMapDogWalkA += "///B##B/B#B///B#BB##B/";
  sMapDogWalkA += "////B#B//B/////B//B#B/";
  sMapDogWalkA += "/////B/////////////B//";

  sMapDogWalkB += "////////////B/BBBB/B//";
  sMapDogWalkB += "///////////B#B####B#B/";
  sMapDogWalkB += "///////////B########B/";
  sMapDogWalkB += "//////////B#########B/";
  sMapDogWalkB += "///B/////BB####B##B##B";
  sMapDogWalkB += "//B#B//BB############B";
  sMapDogWalkB += "//B#BBB#########BB###B";
  sMapDogWalkB += "//B###########B##B#B#B";
  sMapDogWalkB += "//B############BBBB##B";
  sMapDogWalkB += "//B##################B";
  sMapDogWalkB += "//B##################B";
  sMapDogWalkB += "//B##################B";
  sMapDogWalkB += "//B##################B";
  sMapDogWalkB += "///B#################B";
  sMapDogWalkB += "///B################B/";
  sMapDogWalkB += "///B##BB##BBBB##BB##B/";
  sMapDogWalkB += "////B#BB##B//B##B/B#B/";
  sMapDogWalkB += "/////B//B#B///B#B//B//";
  sMapDogWalkB += "/////////B/////B//////";

  cMapDogWalkA = sMapDogWalkA.toCharArray();
  cMapDogWalkB = sMapDogWalkB.toCharArray();
  cMapDogWalk = sMapDogWalkB.toCharArray(); // conversion to char arrays is necessary as strings cannot be referenced w/ indexes
}

void draw() {
  fDeltaTime = (millis() - fElapsedTime) / 1000; // taking the time of the last frame, for physics
  noStroke();

  if (bGameStarted) { // basic state checking to determine what screens to show
    gameRunning();
  } else {
    gameStarting();
  }

  fElapsedTime = millis(); // required for deltatime of next frame
}

void gameStarting() {
  drawPlaySpace();
  drawPlayer(pvDogPos.x, pvDogPos.y);
  fill(255);
  rectMode(CENTER);
  textAlign(CENTER, CENTER);
  textSize(48);
  text("PRESS ANY KEY TO START", width / 2, height / 2);
  rectMode(CORNER);
}

void gameRunning() {
  // START movement calcs
  if (!bGameWon && !bLaunchMode) {
    iDogVelX = 300;
  }
  pvDogPos.x += iDogVelX * fDeltaTime * pvDogPos.z; // change player position over time
  if (pvDogPos.x + iMapDogWalkA[3] > width && pvDogPos.z == 1.0) { // check for border collision
    pvDogPos.z = -1.0; // set the direction of travel 
    pvDogPos.x = width;
  }
  if (pvDogPos.x - iMapDogWalkA[3] < 0 && pvDogPos.z == -1.0) {
    pvDogPos.z = 1.0; // set the direction of travel 
    pvDogPos.x = 0;
  }
  checkBallCollisions();
  moveBall();
  // END movement calcs

  // START drawing funcs 
  drawPlaySpace();
  fill(#211D1D);
  circle(pvHolePos.x, pvHolePos.y, fBallDiameter * 4); // drawing a hole 2* the size of the ball 
  for (float[][] x : fAllActiveBall) {
    drawBall(x[0][0], x[0][1]);
  }
  if (checkWin()) { // if a ball is on the
    bLaunchMode = false;
    iDogVelX = 0;
    bGameWon = true;
    rectMode(CENTER);
    text("HOLE IN " + iBallTotal + "!", width / 2, height / 2);
    text("PRESS ANY KEY TO TRY AGAIN", width / 2, height * 0.7);
    rectMode(CORNER);
  }
  drawPlayer(pvDogPos.x, pvDogPos.y);
  if (bLaunchMode) { // check if an aiming arrow needs to be drawn
    fDogPower = fDogPower >= 600 ? 1 : fDogPower + 2.5;
    if (fDogPower <= 150 && fDogPower > 0) { // determine how fast the dog stamps
      iDogWalkCount ++;
    } else if (150 < fDogPower && fDogPower <= 300) {
      iDogWalkCount += 2;
    } else if (300 < fDogPower && fDogPower <= 450) {
      iDogWalkCount += 3;
    } else if (450 < fDogPower) {
      iDogWalkCount += 4;
    }
    atan2Y = pvDogPos.y - mouseY - 10; // opposite side. these atan params make up the origin
    atan2X = fDogMiddlePoint - mouseX; // adjacent side
    theta = atan2(atan2Y, atan2X); // O / A to get the angle from mouse to origin, using arctangent
    cosX = cos(theta); // for theta, find the length of x, or the adjacent side
    sinY = sin(theta); // same as above, for the opposite side. these values become our x, y coordinates later on
    stroke(#EDDC1D);
    strokeWeight(5);
    float fArrowApexX = fDogMiddlePoint + (100 * -cosX);
    float fArrowApexY = pvDogPos.y + (100 * -sinY) - 10;
    line(fDogMiddlePoint, pvDogPos.y - 10, fArrowApexX, fArrowApexY); // main line
    line(fArrowApexX, fArrowApexY, fArrowApexX + (30 * cos(theta - PI / 6)), fArrowApexY + (30 * sin(theta - PI / 6))); //  offshoot lines to 
    line(fArrowApexX, fArrowApexY, fArrowApexX + (30 * cos(theta + PI / 6)), fArrowApexY + (30 * sin(theta + PI / 6))); //  make an arrow
  } 
  // END drawing funcs
}

void gameReset() { // reset all relevant variables to a pre win state
  pvHolePos = new PVector(random(fBallDiameter * 2, width - fBallDiameter * 2), random(fBallDiameter * 2, height * 0.7));
  pvDogPos = new PVector(width / 2 - iMapDogWalkA[3] / 2, height * 0.85, 1.0);
  bGameStarted = false;
  bGameWon = false;
  iCurrentBall = 0;
  iBallTotal = 0;
  fDogPower = -1;
  for (int x = 0; x < fAllActiveBall.length; x ++) {
    fAllActiveBall[x] = new float[][]{{-50.0, -50.0}, {0.0, 0.0}};
  }
}

boolean checkWin() { // checking all balls for whether they are still and in the hole
  for (float[][] x : fAllActiveBall) {
    PVector ballA = new PVector(x[0][0], x[0][1]);
    if (x[1][0] == 0.0 && x[1][1] == 0.0 && PVector.dist(ballA, pvHolePos) < fBallDiameter + fBallDiameter / 2) {
      return true;
    }
  }
  return false;
}

void moveBall() { // move all balls according to their velocity, accounting for friction
  for (float[][] x : fAllActiveBall) {
    x[1][0] *= 0.95;
    x[1][1] *= 0.95;
    if (abs(x[1][0]) <= 1 && abs(x[1][1]) <= 1) { // clamping velocity to prevent forever moving
      x[1][0] = 0;
      x[1][1] = 0;
    }
    x[0][0] += x[1][0] * fDeltaTime;
    x[0][1] += x[1][1] * fDeltaTime;
  }
}

void checkBallCollisions() { // check for circle v circle collision
  for (int x = 0; x < fAllActiveBall.length; x++) { // nested for loop checks items against unchecked items
    if (fAllActiveBall[x][0][0] + fBallRadius >= width || fAllActiveBall[x][0][0] - fBallRadius <= 0) { //
      fAllActiveBall[x][1][0] *= -1;
    } // these ifs check for border collision for each ball
    if (fAllActiveBall[x][0][1] + fBallRadius >= height || fAllActiveBall[x][0][1] - fBallRadius <= 0) {
      fAllActiveBall[x][1][1] *= -1;
    }
    for (int y = 9; y > x; y--) {
      PVector ballA = new PVector(fAllActiveBall[x][0][0], fAllActiveBall[x][0][1]);
      PVector ballB = new PVector(fAllActiveBall[y][0][0], fAllActiveBall[y][0][1]); // creating vectors for ball positions, velocities
      PVector ballAVel = new PVector(fAllActiveBall[x][1][0], fAllActiveBall[x][1][1]);
      PVector ballBVel = new PVector(fAllActiveBall[y][1][0], fAllActiveBall[y][1][1]);
      if (PVector.dist(ballA, ballB) <= fBallDiameter) { // comparing the distance between a ball to another ball centre
        float fTotalVel = ballAVel.mag() + ballBVel.mag();
        float fAngleFromA = atan2(ballB.y - ballA.y, ballB.x - ballA.x); // finding the angle from a ball to another ball
        fAllActiveBall[x][1][0] = -(fTotalVel / 2) * (cos(fAngleFromA)); // send a ball at the angle, and another one in the opposite
        fAllActiveBall[x][1][1] = -(fTotalVel / 2) * (sin(fAngleFromA));
        fAllActiveBall[y][1][0] = (fTotalVel / 2) * (cos(fAngleFromA));
        fAllActiveBall[y][1][1] = (fTotalVel / 2) * (sin(fAngleFromA));
      }
    }
  }
}

void drawBall(float x, float y) { // why was this a necessary signature
  noStroke();
  fill(255);
  circle(x, y, fBallDiameter);
}

void drawPlayer(float x, float y) { // drawing the player, cycling through an animation
  fDogMiddlePoint = pvDogPos.z == 1.0 ? pvDogPos.x + iMapDogWalkA[3] / 2 : pvDogPos.x - iMapDogWalkA[3] / 2; // change midpoint based on direction
  if (iDogWalkCount > 15) { // animation cycling
    iDogWalkCount = 0;
    if (cMapDogWalk == cMapDogWalkA) {
      cMapDogWalk = cMapDogWalkB;
    } else {
      cMapDogWalk = cMapDogWalkA;
    }
  }
  fill(#343030);
  ellipse(fDogMiddlePoint, pvDogPos.y + iMapDogWalkA[4], iMapDogWalkA[3], 10); // little shadow
  drawDogMap((int)x, (int)y, cMapDogWalk); // little dog
  iDogWalkCount++;
}

void drawPlaySpace() {
  for (int x = 0; x < width; x += iLawnSize) { // using noise, assign cloudy green values
    for (int y = 0; y < height; y += iLawnSize) {
      float a = map(255 * noise(0.01 * x, 0.01 * y), 0, 255, 100, 240);
      fill(50, a, 70);
      square(x, y, iLawnSize);
    }
  }
  fill(#939090);
  rect(0, height * 0.8, width, height * 0.3);
}

void drawDogMap(int fOffSetX, int fOffSetY, char[] cMap) { // a specialised loop that draws the tilemap in realspace
  for (int x = 0; x < iMapDogWalkA[0]; x++) {
    for (int y = 0; y < iMapDogWalkA[1]; y++) {
      char block = cMap[y * iMapDogWalkA[0] + x]; // this converts a 1D array into a 2D coordinate, so we can refer to the block in tilemapspace
      switch (block) { // draw each block in realspace according to direction, x offset and tilesize
      case 'B': // b for black
        fill(0);
        square((int)pvDogPos.z * x * iMapDogWalkA[2] + fOffSetX, y * iMapDogWalkA[2] + fOffSetY, iMapDogWalkA[2]);
        break; // ^^ these casts to int are necessary to prevent spaces opening between individual pixels. go figure
      case '#': // # for whitespace
        if (fDogPower <= 150 && fDogPower > 0) { // change colour depending on power
          fill(255);
        } else if (150 < fDogPower && fDogPower <= 300) {
          fill(#F29E16);
        } else if (300 < fDogPower && fDogPower <= 450) {
          fill(#F9FA1E);
        } else if (450 < fDogPower) {
          fill(#7BEA15);
        } else {
          fill(255);
        }
        square((int)pvDogPos.z * x * iMapDogWalkA[2] + fOffSetX, y * iMapDogWalkA[2] + fOffSetY, iMapDogWalkA[2]);
        break;
      }
    }
  }
}

void keyPressed() {
  if (!bLaunchMode && bGameStarted) { // toggle launchmode on, off
    bLaunchMode = true;
    iDogVelX = 0;
  } else if (bLaunchMode && bGameStarted) { // if launchmode, create a new ball
    bLaunchMode = false;
    float fPowerScaled = map(fDogPower, 0, 600, 0, 3000);
    fAllActiveBall[iCurrentBall] = new float[][]{ {fDogMiddlePoint, pvDogPos.y}, {-cosX * fPowerScaled, -sinY * fPowerScaled} };
    iCurrentBall = iCurrentBall == 9 ? 0 : iCurrentBall + 1;
    iDogVelX = 300;
    iBallTotal++;
    fDogPower = -1;
  } else if (!bGameStarted) { // response to the start screen prompt
    bGameStarted = true;
  }
  if (bGameWon) { // response to the end screen prompt
    bGameStarted = false;
    bLaunchMode = false;
    gameReset();
  }
}
