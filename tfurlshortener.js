var aws = require('aws-sdk');
var crypto = require('crypto');

exports.handler = (event, context, callback) => {
    
    var ddb = new aws.DynamoDB();        
    var apiResponse = {};
    var longUrl = JSON.stringify(event.headers.url);
    var shortUrl = crypto.createHash('md5').update(longUrl).digest('hex').substring(0,6);
    console.log(longUrl);
    console.log(shortUrl);
    console.log(event);
    console.log(event.Host);
 
    
    var params = {
        Item: {
            "yourUrl": {
                S: longUrl
                }, 
            "shortUrl": {
                S: shortUrl
                } 
            },
            ReturnConsumedCapacity: "TOTAL", 
            TableName: "url_shortener"
        }

    var request = ddb.putItem(params);
    
    request.
        on('success', function(response) {
                apiResponse = {
                statusCode: 200,
                headers: {
                    "Access-Control-Allow-Origin":"*"
                    },
                body: "https://" + event.headers.Host + "/test/" + shortUrl
            };
            callback(null, apiResponse);
        }).
        on('error', function(response){
            console.log(response)
            apiResponse = {
                statusCode: 500,
                headers: {},
                body: "There was an error processing your request " + JSON.stringify(response.data)
            }; callback(null, apiResponse)
            
        }).
    
    send();
};

