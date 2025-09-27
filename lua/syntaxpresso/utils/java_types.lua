local M = {}

function M.get_id_types()
  return {
    { id = "java.lang.Long", name = "Long", package_path = "java.lang", type = "Long" },
    { id = "java.lang.Integer", name = "Integer", package_path = "java.lang", type = "Integer" },
    { id = "java.lang.String", name = "String", package_path = "java.lang", type = "String" },
    { id = "java.util.UUID", name = "UUID", package_path = "java.util", type = "UUID" },
    { id = "java.math.BigInteger", name = "BigInteger", package_path = "java.math", type = "BigInteger" },
    { id = "long", name = "long", package_path = "long", type = "long" },
    { id = "int", name = "int", package_path = "int", type = "int" },
  }
end

function M.get_basic_types()
  return {
    { id = "java.lang.String", name = "String", package_path = "java.lang", type = "String" },
    { id = "java.lang.Long", name = "Long", package_path = "java.lang", type = "Long" },
    { id = "java.lang.Integer", name = "Integer", package_path = "java.lang", type = "Integer" },
    { id = "java.lang.Boolean", name = "Boolean", package_path = "java.lang", type = "Boolean" },
    { id = "java.lang.Double", name = "Double", package_path = "java.lang", type = "Double" },
    { id = "java.math.BigDecimal", name = "BigDecimal", package_path = "java.math", type = "BigDecimal" },
    { id = "java.time.Instant", name = "Instant", package_path = "java.time", type = "Instant" },
    { id = "java.time.LocalDateTime", name = "LocalDateTime", package_path = "java.time", type = "LocalDateTime" },
    { id = "java.time.LocalDate", name = "LocalDate", package_path = "java.time", type = "LocalDate" },
    { id = "java.time.LocalTime", name = "LocalTime", package_path = "java.time", type = "LocalTime" },
    { id = "java.time.OffsetDateTime", name = "OffsetDateTime", package_path = "java.time", type = "OffsetDateTime" },
    { id = "java.time.OffsetTime", name = "OffsetTime", package_path = "java.time", type = "OffsetTime" },
    { id = "java.util.Date", name = "Date (util)", package_path = "java.util", type = "Date" },
    { id = "java.sql.Date", name = "Date (sql)", package_path = "java.sql", type = "Date" },
    { id = "java.sql.Time", name = "Time", package_path = "java.sql", type = "Time" },
    { id = "java.sql.Timestamp", name = "Timestamp", package_path = "java.sql", type = "Timestamp" },
    { id = "java.util.TimeZone", name = "TimeZone", package_path = "java.util", type = "TimeZone" },
    { id = "java.lang.Byte[]", name = "Byte[]", package_path = "java.lang", type = "Byte[]" },
    { id = "java.sql.Blob", name = "Blob", package_path = "java.sql", type = "Blob" },
    { id = "java.lang.Byte", name = "Byte", package_path = "java.lang", type = "Byte" },
    { id = "java.lang.Character", name = "Character", package_path = "java.lang", type = "Character" },
    { id = "java.lang.Short", name = "Short", package_path = "java.lang", type = "Short" },
    { id = "java.lang.Float", name = "Float", package_path = "java.lang", type = "Float" },
    { id = "java.math.BigInteger", name = "BigInteger", package_path = "java.math", type = "BigInteger" },
    { id = "java.net.URL", name = "URL", package_path = "java.net", type = "URL" },
    { id = "java.time.Duration", name = "Duration", package_path = "java.time", type = "Duration" },
    { id = "java.time.ZonedDateTime", name = "ZonedDateTime", package_path = "java.time", type = "ZonedDateTime" },
    { id = "java.util.Calendar", name = "Calendar", package_path = "java.util", type = "Calendar" },
    { id = "java.util.Locale", name = "Locale", package_path = "java.util", type = "Locale" },
    { id = "java.util.Currency", name = "Currency", package_path = "java.util", type = "Currency" },
    { id = "java.lang.Class", name = "Class", package_path = "java.lang", type = "Class" },
    { id = "java.util.UUID", name = "UUID", package_path = "java.util", type = "UUID" },
    { id = "java.lang.Character[]", name = "Character[]", package_path = "java.lang", type = "Character[]" },
    { id = "java.sql.Clob", name = "Clob", package_path = "java.sql", type = "Clob" },
    { id = "java.sql.NClob", name = "NClob", package_path = "java.sql", type = "NClob" },
    { id = "boolean", name = "boolean", package_path = "boolean", type = "boolean" },
    { id = "byte", name = "byte", package_path = "byte", type = "byte" },
    { id = "float", name = "float", package_path = "float", type = "float" },
    { id = "char", name = "char", package_path = "char", type = "char" },
    { id = "int", name = "int", package_path = "int", type = "int" },
    { id = "double", name = "double", package_path = "double", type = "double" },
    { id = "short", name = "short", package_path = "short", type = "short" },
    { id = "long", name = "long", package_path = "long", type = "long" },
    { id = "byte[]", name = "byte[]", package_path = "byte[]", type = "byte[]" },
    { id = "char[]", name = "char[]", package_path = "char[]", type = "char[]" },
    { id = "org.geolatte.geom.Geometry", name = "Geometry (geolatte)", package_path = "org.geolatte.geom", type = "Geometry" },
    { id = "com.vividsolutions.jts.geom.Geometry", name = "Geometry (jts)", package_path = "com.vividsolutions.jts.geom", type = "Geometry" },
    { id = "java.net.InetAddress", name = "InetAddress", package_path = "java.net", type = "InetAddress" },
    { id = "java.time.ZoneOffset", name = "ZoneOffset", package_path = "java.time", type = "ZoneOffset" },
  }
end

return M