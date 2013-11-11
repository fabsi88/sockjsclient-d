import std.stdio;
import vibe.d;
import sockjsclient.client;



shared static this()
{
	requestHTTP("http://localhost:8989/test",
				(scope req) {
					
				},
				(scope res) {
					logInfo("Response: %s", res.bodyReader.readAllUTF8());
				}
				);

}
