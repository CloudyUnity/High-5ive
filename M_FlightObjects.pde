// Data type for flight information
class FlightType { // 23 bytes total
  public byte Month;                    // supports all querys
  public byte Day;                      // supports all queries
  public short CarrierCodeIndex;        // only supports EQUAL or NOT_EQUAL
  public short FlightNumber;            // only supports EQUAL or NOT_EQUAL
  public short TailNumber;              // only supports EQUAL or NOT_EQUAL
  public short AirportOriginIndex;      // only supports EQUAL or NOT_EQUAL
  public short AirportDestIndex;        // only supports EQUAL or NOT_EQUAL
  public short ScheduledDepartureTime;  // supports all querys
  public short DepartureTime;           // supports all querys
  public short DepartureDelay;          // supports all querys
  public short ScheduledArrivalTime;    // supports all querys
  public short ArrivalTime;             // supports all querys
  public short ArrivalDelay;            // supports all querys
  public byte Cancelled;                // only supports EQUAL or NOT_EQUAL
  public byte Diverted;                 // only supports EQUAL or NOT_EQUAL
  public short ScheduledDuration;       // supports all queries
  public short ActualDuration;          // supports all queries
  public short KmDistance;              // supports all querys

  FlightType(
    byte month, byte day, short carrierCodeIndex, short flightNumber, short tailNumber,
    short airportOriginIndex, short airportDestIndex, short scheduledDepartureTime,
    short departureTime, short departureDelay, short scheduledArrivalTime,
    short arrivalTime, short arrivalDelay, byte cancelled, byte diverted,
    short scheduledDuration, short duration, short kmDistance) {

    Month = month;
    Day = day;
    CarrierCodeIndex = carrierCodeIndex;
    FlightNumber = flightNumber;
    TailNumber = tailNumber;
    AirportOriginIndex = airportOriginIndex;
    AirportDestIndex = airportDestIndex;
    ScheduledDepartureTime = scheduledDepartureTime;
    DepartureTime = departureTime;
    DepartureDelay = departureDelay;
    ScheduledArrivalTime = scheduledArrivalTime;
    ArrivalTime = arrivalTime;
    ArrivalDelay = arrivalDelay;
    Cancelled = cancelled;
    Diverted = diverted;
    ScheduledDuration = scheduledDuration;
    ActualDuration = duration;
    KmDistance = kmDistance;
  }

  FlightType(short carrierCodeIndex, short airportOriginIndex, short airportDestIndex) {
    CarrierCodeIndex = carrierCodeIndex;
    AirportOriginIndex = airportOriginIndex;
    AirportDestIndex = airportDestIndex;
  }

  public FlightType() {
  }
}

// Data type for holding all loaded flight data
class FlightMultiDataType {
  public FlightType[] US;
  public FlightType[] WORLD;

  FlightMultiDataType(FlightType[] us, FlightType[] world) {
    US = us;
    WORLD = world;
  }
}

// Data type for making a query on a FlightType[]
class FlightQueryType {
  public int QueryValue;
  public QueryType Type;
  public QueryOperatorType Operator;
  public QueryLocationType Location;

  FlightQueryType(QueryType type, QueryOperatorType operator, QueryLocationType location) {
    Type = type;
    Operator = operator;
    Location = location;
  }
}

// Data type for making a range query on a FlightType[]
class FlightRangeQueryType {
  public QueryType Type;
  public QueryLocationType Location;

  FlightRangeQueryType(QueryType type, QueryLocationType location) {
    Type = type;
    Location = location;
  }
}

// Data type for sorting a FlightType[]
class FlightSortQueryType {
  public QueryType Type;
  public QuerySortDirectionType SortDirection;

  FlightSortQueryType(QueryType type, QuerySortDirectionType sortDirection) {
    Type = type;
    SortDirection = sortDirection;
  }
}

// Enum for the fields in FlightType
public enum QueryType {
  MONTH,
    DAY,
    CARRIER_CODE_INDEX,
    FLIGHT_NUMBER,
    TAIL_NUMBER,
    AIRPORT_ORIGIN_INDEX,
    AIRPORT_DEST_INDEX,
    SCHEDULED_DEPARTURE_TIME,
    DEPARTURE_TIME,
    DEPARTURE_DELAY,
    SCHEDULED_ARRIVAL_TIME,
    ARRIVAL_TIME,
    ARRIVAL_DELAY,
    CANCELLED,
    DIVERTED,
    SCHEDULED_DURATION,
    ACTUAL_DURATION,
    KILOMETRES_DISTANCE,
}

// Enum for the query operators
public enum QueryOperatorType {
  EQUAL,
    NOT_EQUAL,
    LESS_THAN,
    LESS_THAN_EQUAL,
    GREATER_THAN,
    GREATER_THAN_EQUAL,
}

// Enum for the sort directions
public enum QuerySortDirectionType {
  ASCENDING,
    DESCENDING,
}

// Enum for the query locations
public enum QueryLocationType {
  US,
    WORLD,
}

// Data type for a latitude-longitude coordinate for a point on earth
class CoordType {
  public float Latitude;
  public float Longitude;

  public CoordType(float lat, float longi) {
    Latitude = lat;
    Longitude = longi;
  }
}

// Data type for an airport marker on the 3D flight map and its connections
class AirportPoint3DType {
  public PVector Pos;
  public String Name;
  public color Color = color(0, 255, 0, 255);
  public ArrayList<String> Connections = new ArrayList<String>();
  public ArrayList<ArrayList<PVector>> ConnectionArcPoints = new ArrayList<ArrayList<PVector>>();

  public AirportPoint3DType(PVector pos, String name) {
    Pos = pos;
    Name = name;
  }

  public AirportPoint3DType(PVector pos, String name, color col) {
    Pos = pos;
    Name = name;
    Color = col;
  }
}

// Descending code authorship changes:
// T. Creagh, added enums into this file, 11pm 06/03/24
// F. Wright, Moved 3D objects into this tab from W_FlightMap3D
// T. Creagh, added in FlightQuery, 8pm 12/03/24
// T. Creagh, added in FlightRangeQuery, 9pm 12/03/24
// T. Creagh, added in FlightSortQuery, 10pm 12/03/24
// F. Wright, Refactoring, 7pm 25/03/24
// CKM, Added additional queries 16:00 04/04
// CKM, Basework for 2nd level querying 22:00 05/04
