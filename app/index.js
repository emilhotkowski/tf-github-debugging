exports.handler =  async function(event, context) {
    return {
        statusCode: 200,
        headers: {
            "content-type": "text/html"
        },
        body: "Hello from GithubDebugging!",
        isBase64Encoded: true
    }
}