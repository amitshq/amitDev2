/**
* Date-21-Aug-2021
* Author- Amit Kumar
* @description Generic logging framework that persists across DML reversions by publishing a Platform Event
* @group With Shared Code
*
*/
public with sharing class SlackLogger {
    /**
* @description A top-level severity enum for SlackLogger, and LogMessage to use Shared Code*/
    public enum LogSeverity {DEBUG,INFO,WARN,ERROR}
    /**
* @description private instance of this log class that backs the
* singleton get() method.
*/
    private static SlackLogger currentInstance;
    /**
* @description private list of LogMessage objects to be published in the
* future
*/
    private static List<LogMessage> buffer;
    /**
* @description establishes the buffer, if one doesn't yet exist
* private, to ensure we can't directly construct this class. Use the
* Singleton, Luke.
*/
    private SlackLogger() {
        buffer = new List<LogMessage>();
    }
    /**
* @description Singleton pattern `get` method.
* @return     `SlackLogger`
*/
    public static SlackLogger get() {
        if (currentInstance == null) {
            currentInstance = new SlackLogger();
        }
        return currentInstance;
    }
    
    /**
* @description Add a message to the buffer without publishing it.
* Assumes a null severity
* @param messageToLog  The string message to add to the buffer.

public static void add(String messageToLog) {
this.add(messageToLog, null);
}*/
    /**
* @description Add a message to the buffer without publishing it.
* @param messageToLog The string message to add to the buffer.
* @param severity     LogSeverity enum
*/
    public static void add(String messageToLog, LogSeverity severity) {
        LogMessage msg = new LogMessage(messageToLog);
        if (severity != null) {
            msg.severity = severity;
        }
        buffer.add(msg);
    }
    /**
* @description Add an formated exception message to the buffer without
* publishing it. Assumes a null Severity
* @param exceptionToLog Exception to format and log

public void add(Exception exceptionToLog) {
this.add(exceptionToLog, null);
}
*/
    /**
* @description Add an formated exception message to the buffer without
* publishing it.
* @param exceptionToLog Exception to format and log
* @param severity       LogSeverity enum
*/
    public static void add(Exception exceptionToLog, LogSeverity severity) {
        LogMessage msg = new LogMessage(exceptionToLog);
        if (severity != null) {
            msg.severity = severity;
        }
        buffer.add(msg);
    }
    
    /**
* @description Publish any messages currently in the buffer, without adding
* any new ones.
*/
    public static void publish() {
        List<SObject> rawLogs = new List<SObject>();
        for (LogMessage msg : buffer) {
            rawLogs.add(msg.toEvent());
        }
        EventBus.publish(rawLogs);
        buffer.clear();
    }
    
    /**
* @description Auto-format exception details, add it to the log buffer,
* and then publish the current buffer. Use the equivelent add
* method if you intend to add multiple messages rapidly to minimize DML
* usage.
* @param exceptionToLog exception to format and log
*/
    public static void publish(Exception exceptionToLog) {
        buffer.add(new LogMessage(exceptionToLog));
        publish();
    }
    
    /**
* @description Auto-format a custom log message string, add it to the log
* buffer, and then publish the current buffer. Use the equivelent add
* method if you intend to add multiple messages rapidly to minimize DML
* usage.
* @param messageToLog String to log
*/
    public static void publish(String messageToLog) {
        buffer.add(new LogMessage(messageToLog));
        publish();
    }
    
    public class LogMessage {
        private  final String EXCEPTION_STRING_FORMAT = 'Exception: [{0}] {1} \n StackTrace: {2}';
        
        /**
* @description public read only property for the request ID. Privately set.
*/
        public String requestId {
            get {
                if (requestId == null) {
                    requestId = Request.getCurrent().getRequestId();
                }
                return requestId;
            }
            private set;
        }
        
        /**
* @description Public read only property for quiddity. Privately set.
*/
        public Quiddity quiddity {
            get {
                if (quiddity == null) {
                    quiddity = Request.getCurrent().getQuiddity();
                }
                return quiddity;
            }
            private set;
        }
        
        /**
* @description Public message property.
*/
        public String message { get; set; }
        
        /**
* @description Public severity property.
*/
        public LogSeverity severity { get; set; }
        
        /**
* @description converts this object to an event for publishing
* @return      `SObject`
*/
        public SlackLog__e  toEvent() {
            return new SlackLog__e (
                Log_Message__c = this.message,
                Request_Id__c = this.requestId,
                Quiddity__c = this.quiddity?.name(),
                Severity__c = this.severity?.name()
            );
        }
        
        /**
* @description   Constructor accepting a message to log.
* Severity is auto set to info
* @param message
*/
        public LogMessage(String message) {
            this.message = message;
            this.severity = LogSeverity.INFO;
        }
        
        /**
* @description Constructor accepting an exception object.
* @param ex
*/
        public LogMessage(Exception ex) {
            this.message = String.format(
                EXCEPTION_STRING_FORMAT,
                new List<String>{
                    ex.getTypeName(),
                        ex.getMessage(),
                        ex.getStackTraceString()
                        }
            );
            this.severity = LogSeverity.ERROR;
        }
    }
}