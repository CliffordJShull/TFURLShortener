var aws = require('aws-sdk');

exports.handler = (event, context, callback) => {
    
    var ddb = new aws.DynamoDB();        
    var apiResponse = {};
    var longUrl = "";
    var shortUrl = event.path;
    shortUrl = shortUrl.replace("\"","");
    shortUrl = shortUrl.replace("\"","");
    shortUrl = shortUrl.replace("\/", "");
    console.log('\n' + shortUrl + '\n');
    console.log('\nEVENT:\n'+ JSON.stringify(event) + '\n');
    
    var params = {
        Key: {
            "shortUrl": {
                S: shortUrl
                } 
            },
            ReturnConsumedCapacity: "TOTAL", 
            TableName: "url_shortener"
        }

    ddb.getItem(params, function(err, data) {
      if (err) {
        // console.log("Error", err);
        apiResponse = {
            "statusCode": 500,
            "headers": {},
            "body": "There was an error processing your request " + JSON.stringify(err)
        }; 
        callback(null, apiResponse);
      } else {
        // console.log("Success", data);
        longUrl = (data.Item.yourUrl.S);
        longUrl = longUrl.replace("\"","");
        longUrl = longUrl.replace("\"","");
        apiResponse = {
            "statusCode": 301,
            "headers": {
                "Location": longUrl
                },
            "body": "<html><head><title>Moved</title></head><body><h1>Moved</h1><p>This page has moved to <a href=\"http://www.example.org/\">http://www.example.org/</a>.</p></body></html>"
        };
        callback(null, apiResponse);
      }
    });
};
