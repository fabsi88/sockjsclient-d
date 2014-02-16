import sockjsclient.client;
import vibe.d:logInfo;

shared static this()
{
	SockJsClient client;
	client = new SockJsClient("http://127.0.0.1:8989","echo");
	
	client.OnConnect = (){
		logInfo("connected");
		client.send("Hello World!");
	};
	client.OnDisconnect = (int code, string msg) {
		logInfo("disconnected");
	};
	client.OnData = (string _data) {
		logInfo("OnData rec: %s",_data);
	};
	
	client.connect();	
}


