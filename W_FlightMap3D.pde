class FlightMap3D extends Widget implements IDraggable, IWheelInput {

  private Event<MouseDraggedEventInfoType> m_onDraggedEvent = new Event<MouseDraggedEventInfoType>();
  private Event<MouseWheelEventInfoType> m_onWheelEvent = new Event<MouseWheelEventInfoType>();

  private PShape m_earthModel, m_sunModel, m_skySphere;
  private PImage m_earthDayTex, m_earthNightTex, m_sunTex;
  private PImage m_earthNormalTex, m_earthSpecularMap, m_noiseImg;
  private PShader m_earthShader, m_sunShader, m_postProcessingShader, m_skyboxShader;
  private PImage m_starsTex;

  private PVector m_earthRotation = new PVector(0, 0, 0);
  private PVector m_earthRotationalVelocity = new PVector(0, 0, 0);
  private float m_zoomLevel = 1.0f;
  private float m_dayCycleSpeed = 0.00005f;

  private float m_arcFraction = 1.0f;
  private float m_arcGrowMillis = 1.0f;
  private int m_arcStartGrowMillis = 0;
  private boolean m_connectionsEnabled = true;
  private boolean m_textEnabled = true;
  private boolean m_markersEnabled = true;
  private boolean m_lockTime = false;

  private boolean m_assetsLoaded = false;
  private boolean m_drawnLoadingScreen = false;
  private boolean m_flightDataLoaded = false;

  private float m_rotationYModified = 0;
  private float m_totalTimeElapsed = 0;
  private int m_arcSegments;

  private HashMap<String, AirportPoint3DType> m_airportHashmap = new HashMap<String, AirportPoint3DType>();

  private PVector m_earthPos;
  private float m_earthRadius;

  public FlightMap3D(int posX, int posY, int scaleX, int scaleY) {
    super(posX, posY, scaleX, scaleY);
    m_starsTex = loadImage("data/Images/Stars2k.jpg");
    m_earthRadius = height * 0.38f;

    new Thread(() -> {
      m_earthModel = s_3D.createShape(SPHERE, m_earthRadius);
      m_earthModel.disableStyle();
      m_earthDayTex = loadImage("data/Images/EarthDay2k.jpg");
      m_earthNightTex = loadImage("data/Images/EarthNight2k.jpg");
      m_earthNormalTex = loadImage("data/Images/EarthNormalAlt.jpg");

      m_earthShader = loadShader("data/Shaders/EarthFrag.glsl", "data/Shaders/BaseVert.glsl");
      m_earthShader.set("texDay", m_earthDayTex);
      m_earthShader.set("texNight", m_earthNightTex);
      m_earthShader.set("normalMap", m_earthNormalTex);

      if (DEBUG_FAST_LOADING_3D) {
        m_assetsLoaded = true;
        return;
      }

      m_sunModel = s_3D.createShape(SPHERE, 40);
      m_skySphere = s_3D.createShape(SPHERE, 3840);
      m_sunModel.disableStyle();
      m_skySphere.disableStyle();

      m_sunTex = loadImage("data/Images/Sun2k.jpg");
      m_noiseImg = loadImage("data/Images/noise.png");
      m_earthSpecularMap = loadImage("data/Images/EarthSpecular2k.tif");
      m_sunShader = loadShader("data/Shaders/SunFrag.glsl", "data/Shaders/BaseVert.glsl");
      m_postProcessingShader = loadShader("data/Shaders/PostProcessing.glsl");
      m_skyboxShader = loadShader("data/Shaders/SkyboxFrag.glsl", "data/Shaders/SkyboxVert.glsl");

      m_earthShader.set("specularMap", m_earthSpecularMap);
      m_sunShader.set("tex", m_sunTex);
      m_postProcessingShader.set("noise", m_noiseImg);
      m_skyboxShader.set("tex", m_starsTex);
      setPermaDay(false);

      m_assetsLoaded = true;
    }
    ).start();

    m_earthPos = new PVector(width * 0.5f + posX, height * 0.5f + posY, EARTH_Z_3D);

    m_onDraggedEvent.addHandler(e -> onDraggedHandler(e));
    m_onWheelEvent.addHandler(e -> onWheelHandler(e));
  }

  @ Override
    public void draw() {
    super.draw();

    m_earthRotation.add(m_earthRotationalVelocity);
    m_earthRotationalVelocity.mult(EARTH_FRICTION_3D);
    m_earthRotation.x = clamp(m_earthRotation.x, -VERTICAL_SCROLL_LIMIT_3D, VERTICAL_SCROLL_LIMIT_3D);
    m_arcFraction = (millis() - m_arcStartGrowMillis) / m_arcGrowMillis;

    if (!m_assetsLoaded || !m_drawnLoadingScreen || !m_flightDataLoaded) {
      image(m_starsTex, 0, 0, width, height);

      textAlign(CENTER);
      fill(255, 255, 255, 255);
      textSize(50);
      text("Loading...", width/2, height/2);
      m_drawnLoadingScreen = true;
      return;
    }

    if (!m_lockTime)
      m_totalTimeElapsed += s_deltaTime * m_dayCycleSpeed;

    PVector lightDir = new PVector(cos(m_totalTimeElapsed), 0, sin(m_totalTimeElapsed));
    m_earthShader.set("lightDir", lightDir);
    // m_earthShader.set("mousePos", (float)mouseX / (float)width, (float)mouseY / (float)height);
    m_rotationYModified = m_earthRotation.y + m_totalTimeElapsed;
    m_earthPos.z = EARTH_Z_3D + m_zoomLevel;

    if (!DEBUG_FAST_LOADING_3D)
      m_sunShader.set("texTranslation", 0, m_totalTimeElapsed * 0.5f);

    drawEarth();

    if (!DEBUG_FAST_LOADING_3D) {
      drawSun(lightDir);
    }

    drawMarkersAndConnections();
    if (m_textEnabled)
      drawMarkerText();

    if (DITHER_MODE_3D && !DEBUG_FAST_LOADING_3D)
      s_3D.filter(m_postProcessingShader);

    if (!DEBUG_FAST_LOADING_3D) {
      drawSkybox();
    }

    s_3D.endDraw();

    image(s_3D, 0, 0);
  }

  void drawEarth() {
    s_3D.beginDraw();
    s_3D.clear();
    s_3D.noStroke();
    s_3D.fill(255);

    s_3D.pushMatrix();
    s_3D.shader(m_earthShader);
    s_3D.textureWrap(CLAMP);

    s_3D.translate(m_earthPos.x, m_earthPos.y, m_earthPos.z);
    s_3D.rotateX(m_earthRotation.x);
    s_3D.rotateY(m_rotationYModified);

    s_3D.shape(m_earthModel);
    s_3D.resetShader();
    s_3D.popMatrix();
  }

  void drawSun(PVector lightDir) {
    PVector sunTranslation = lightDir.copy().mult(-3000);
    s_3D.shader(m_sunShader);
    s_3D.textureWrap(REPEAT);

    s_3D.pushMatrix();
    s_3D.translate(m_earthPos.x, m_earthPos.y, m_earthPos.z);
    s_3D.rotateX(m_earthRotation.x);
    s_3D.rotateY(m_rotationYModified);
    s_3D.translate(sunTranslation.x, sunTranslation.y, sunTranslation.z);

    s_3D.shape(m_sunModel);
    s_3D.popMatrix();
    s_3D.resetShader();
    s_3D.textureWrap(CLAMP);
  }

  void drawSkybox() {
    s_3D.pushMatrix();
    s_3D.shader(m_skyboxShader);

    s_3D.rotateX(m_earthRotation.x);
    s_3D.rotateY(m_earthRotation.y);

    s_3D.shape(m_skySphere);
    s_3D.resetShader();
    s_3D.popMatrix();
  }

  void drawMarkersAndConnections() {
    s_3D.strokeWeight(ARC_SIZE_3D);
    s_3D.noFill();

    s_3D.pushMatrix();
    s_3D.translate(m_earthPos.x, m_earthPos.y, m_earthPos.z);
    s_3D.rotateX(m_earthRotation.x);
    s_3D.rotateY(m_rotationYModified);

    for (AirportPoint3DType point : m_airportHashmap.values()) {
      PVector endline = point.Pos.copy().mult(1.05f);

      if (m_markersEnabled) {
        s_3D.stroke(point.Color);
        s_3D.line(point.Pos.x, point.Pos.y, point.Pos.z, endline.x, endline.y, endline.z);
      }

      if (m_connectionsEnabled) {
        s_3D.stroke(255, 255, 255, 255);
        drawGreatCircleArcFast(point);
      }
    }

    s_3D.fill(255);
    s_3D.noStroke();
    s_3D.popMatrix();
  }

  void drawMarkerText() {
    s_3D.fill(255, 255, 255, 255);
    s_3D.textAlign(CENTER);
    s_3D.textSize(TEXT_SIZE_3D);

    for (AirportPoint3DType point : m_airportHashmap.values()) {
      float verticalDisplacement = point.Pos.y > 0 ? TEXT_DISPLACEMENT_3D.y : -TEXT_DISPLACEMENT_3D.y;

      s_3D.pushMatrix();
      s_3D.translate(m_earthPos.x, m_earthPos.y + verticalDisplacement, m_earthPos.z + TEXT_DISPLACEMENT_3D.z);
      s_3D.rotateX(m_earthRotation.x);
      s_3D.rotateY(m_rotationYModified);
      s_3D.translate(point.Pos.x, point.Pos.y, point.Pos.z);
      s_3D.rotateY(-m_rotationYModified);

      s_3D.text(point.Name, 0, 0);
      s_3D.popMatrix();
    }
  }

  public Event<MouseDraggedEventInfoType> getOnDraggedEvent() {
    return m_onDraggedEvent;
  }

  private void onDraggedHandler(MouseDraggedEventInfoType e) {
    PVector deltaDrag = new PVector( -(e.Y - e.PreviousPos.y) * 2, e.X - e.PreviousPos.x);
    deltaDrag.mult(s_deltaTime).mult(VERTICAL_DRAG_SPEED_3D);
    m_earthRotationalVelocity.add(deltaDrag);
  }

  public Event<MouseWheelEventInfoType> getOnMouseWheelEvent() {
    return m_onWheelEvent;
  }

  private void onWheelHandler(MouseWheelEventInfoType e) {
    m_zoomLevel -= e.wheelCount * MOUSE_SCROLL_STRENGTH_3D;
    m_zoomLevel = clamp(m_zoomLevel, -500, 350);
  }

  private AirportPoint3DType manualAddPoint(double latitude, double longitude, String code) {
    PVector pos = coordsToPointOnSphere(latitude, longitude, m_earthRadius);
    AirportPoint3DType point = new AirportPoint3DType(pos, code);
    m_airportHashmap.put(code, point);
    return point;
  }

  void drawGreatCircleArcFast(AirportPoint3DType point) {
    for (var connection : point.ConnectionArcPoints) {
      PVector lastPos = connection.get(0);

      float connectionSize = connection.size();
      for (int i = 1; i < connection.size(); i++) {
        PVector pointOnArc = connection.get(i);
        float t = i / connectionSize;

        if (t > m_arcFraction) {
          float lastT = (i-1) / connectionSize;
          float frac = (m_arcFraction - lastT) / (t - lastT);
          pointOnArc = PVector.lerp(lastPos, pointOnArc, frac);
          s_3D.line(lastPos.x, lastPos.y, lastPos.z, pointOnArc.x, pointOnArc.y, pointOnArc.z);
          break;
        }

        s_3D.line(lastPos.x, lastPos.y, lastPos.z, pointOnArc.x, pointOnArc.y, pointOnArc.z);
        lastPos = pointOnArc;
      }
    }
  }

  ArrayList<PVector> cacheArcPoints(PVector p1, PVector p2) {
    float distance = p1.dist(p2);
    float distMult = lerp(0.1f, 1.0f, distance / 700);
    ArrayList<PVector> cacheResult = new ArrayList<PVector>();
    cacheResult.ensureCapacity(m_arcSegments  + 1);
    cacheResult.add(p1);

    for (int i = 1; i < m_arcSegments; i++) {
      float t = i / (float)m_arcSegments;
      float bonusHeight = distMult * ARC_HEIGHT_MULT_3D * t * (1-t) + 1;
      PVector pointOnArc = slerp(p1, p2, t).mult(m_earthRadius * bonusHeight);
      cacheResult.add(pointOnArc);
    }

    cacheResult.add(p2);
    return cacheResult;
  }

  public void setArcGrowMillis(float timeTakenMillis, int delay) {
    m_arcStartGrowMillis = millis() + delay;
    m_arcGrowMillis = timeTakenMillis;
  }

  public void setPermaDay(boolean enabled) {
    m_earthShader.set("permaDay", enabled ? 10.0f : 0.0f);
  }

  public void setConnectionsEnabled(boolean enabled) {
    m_connectionsEnabled = enabled;
  }

  public void setTextEnabled(boolean enabled) {
    m_textEnabled = enabled;
  }

  public void setMarkersEnabled(boolean enabled) {
    m_markersEnabled = enabled;
  }

  public void setLockTime(boolean enabled) {
    m_lockTime = enabled;
  }
  
  public void setDayCycleSpeed(float speed) {
    m_dayCycleSpeed = speed;
  }

  public void loadFlights(FlightType[] flights, QueryManagerClass queries) {
    m_flightDataLoaded = false;
    int count = flights.length;

    if (DEBUG_FAST_LOADING_3D)
      m_arcSegments = 5;
    else if (count <= 6_000)
      m_arcSegments = 15;
    else if (count <= 12_000)
      m_arcSegments = 10;
    else
      m_arcSegments = 4;

    for (int i = 0; i < count; i++) {

      if (DEBUG_MODE && DEBUG_PRINT_3D_LOADING) {
        println(flights[i].AirportOriginIndex + " " + flights[i].AirportDestIndex);
        println(flights[i].CarrierCodeIndex + " " + flights[i].FlightNumber);
        println("Flight " + i + " / " + flights.length);
      }

      String originCode = queries.getCode(flights[i].AirportOriginIndex);
      String destCode = queries.getCode(flights[i].AirportDestIndex);
      AirportPoint3DType origin, dest;

      if (!m_airportHashmap.containsKey(originCode)) {
        float latitude = queries.getLatitude(originCode);
        float longitude = -queries.getLongitude(originCode);
        origin = manualAddPoint(latitude, longitude, originCode);
      } else
        origin = m_airportHashmap.get(originCode);

      if (!m_airportHashmap.containsKey(destCode)) {
        float latitude = queries.getLatitude(destCode);
        float longitude = -queries.getLongitude(destCode);
        dest = manualAddPoint(latitude, longitude, destCode);
      } else
        dest = m_airportHashmap.get(destCode);

      if (origin.Connections.contains(destCode) || dest.Connections.contains(originCode))
        continue;

      origin.Connections.add(destCode);
      dest.Connections.add(originCode);
      origin.ConnectionArcPoints.add(cacheArcPoints(origin.Pos, dest.Pos));
    }

    m_flightDataLoaded = true;
  }  
}

// Descending code authorship changes:
// F. Wright, Created 3D flight map screen using OpenGL GLSL shaders and P3D features. Implemented light shading and day-night cycle, 9pm 07/03/24
// F. Wright, Fixed loading screen, 10am, 08/03/24
// F. Wright, Created latitude/longitude coords to 3D point converter and used geometric slerping to create arcs around the planet for connections between airports, 3pm 08/03/24
// F. Wright, Specular maps, vertical scrolling, bigger window, more constants, growing arcs over time, 3pm 09/03/24
// F. Wright, Skybox, shaders, fullscreen, UI, buttons, sun, connections, loading in data, etc, etc
// CKM, made minor edits to neaten up code 16:00 12/03
// CKM, inital no spin setup 11:00 13/03
// F. Wright, Implemented "Lock time" checkbox, 12pm 13/03/24
// F. Wright, Improved time locking options, more progress on normal mapping, 9pm 13/03/24
// F. Wright, Finally got normal mapping working! Had to go deep into github repos and tiny forums for that one, 11am 14/03/24
// F. Wright, Changed earth size to depend on screen size, 10am 15/03/24
// F. Wright, Implemented zooming and improved performance, 12pm 15/03/24
