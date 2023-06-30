@isTest
global class TestSlackMockOut implements HttpCalloutMock{
    
    global HTTPResponse respond(HTTPRequest req) {
        String fullJson = '{"messages": [{"type": "message","subtype": "bot_message","text": "*Name*: Rahul Gupta//n*Email*: <mailto:rg007326@gmail.com|rg007326@gmail.com>//n*Company*: Grazitti Interactive//n*Group Name*: Edge Communications Customer Support,All Support,All Sales//n//nComment: Thread 1.1 , From Community//nTopic: Topic3//n//n//n", "ts": "1626339720.003400", "username": "bot", "bot_id": "B01MX1U3JE5", "thread_ts": "1626339720.003400","subscribed": false  }   ]}';    
        HTTPResponse res = new HTTPResponse();   
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
    }
    global HTTPResponse respond1(HTTPRequest req) {
        String fullJson = 'pass test Comment:';
        HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
    }
      global HTTPResponse respond2(HTTPRequest req) {
          String fullJson = '{"messages": [ {"type": "message", "subtype": "bot_message","text": "*Name*: Amit Grazitti\n*Email*: <mailto:amitgrazitti@gmail.com|amitgrazitti@gmail.com>\n*Company*: Grazitti Interactive\n\nSubject: Ne test\nDescription: test desc  \nTopic: Support\n\n\n",             "ts": "1628152265.002200",             "username": "bot",             "bot_id": "B01MX1U3JE5",             "thread_ts": "1628152265.002200",             "reply_count": 5,             "reply_users_count": 1,             "latest_reply": "1628162019.003100",             "reply_users": [                 "B01MX1U3JE5"             ],             "is_locked": false,             "subscribed": false         }     ]}';    
        HTTPResponse res = new HTTPResponse();   
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
    }
}