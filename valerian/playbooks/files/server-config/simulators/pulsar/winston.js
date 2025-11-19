/*
https://www.digitalocean.com/community/tutorials/how-to-use-winston-to-log-node-js-applications
0: error
1: warn
2: info
3: verbose
4: debug
5: silly
*/
var fs = require("fs");
var appRoot = require("app-root-path");
var winston = require("winston");
require("winston-daily-rotate-file");
const { createLogger, format, transports } = require("winston");
const { combine, timestamp, label, printf } = format;

const myFormat = printf((info) => {
  return `${info.timestamp} ${info.level}: ${info.message}`;
});

// define the custom settings for each transport (file, console)
var options = {
  rotatedfile: {
    level: "silly",
    filename: `${appRoot}/logs/pulsar-%DATE%.log`,
    datePattern: "YYYY-MM-DD",
    prepend: true,
    //zippedArchive: true,
    maxSize: "10m",
    maxFiles: "10d",

    format: winston.format.combine(
      winston.format.timestamp({ format: "YYYY-MM-DD HH:mm:ss.SSS" }),
      format.errors({ stack: true }),
      myFormat
    ),
  },
  file: {
    level: "info",
    filename: `${appRoot}/logs/pulsar.log`,
    //handleExceptions: true,
    // json: false,
    maxsize: 5242880, // 5MB
    maxFiles: 5,

    format: winston.format.combine(
      winston.format.timestamp({ format: "YYYY-MM-DD HH:mm:ss.SSS" }),
      myFormat
    ),
  },
  console: {
    level: "info",
    format: winston.format.combine(
      winston.format.timestamp({ format: "YYYY-MM-DD HH:mm:ss.SSS" }),
      winston.format.colorize(),
      myFormat
    ),
  },
};

var logDir = `${appRoot}/logs`;

if (!fs.existsSync(logDir)) {
  // Create the directory if it does not exist
  fs.mkdirSync(logDir);
}

// instantiate a new Winston Logger with the settings defined above
var logger = winston.createLogger({
  //format: combine(
  //label({ label: 'right meow!' }),
  //timestamp(),
  //myFormat
  //),
  transports: [
    new winston.transports.DailyRotateFile(options.rotatedfile),
    new winston.transports.Console(options.console),
  ],
  exitOnError: false, // do not exit on handled exceptions
});

// create a stream object with a 'write' function that will be used by `morgan`
logger.stream = {
  write: function (message, encoding) {
    // use the 'info' log level so the output will be picked up by both transports (file and console)
    logger.info(message);
  },
};

module.exports = logger;
