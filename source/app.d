
//TODO:
// Close function onClose
// Message function onMessage(str)
// 
shared static this()
{
	SockJsClient client;
	client = new SockJsClient("http://funok.de:9876","s4net");
	
	client.onConnect = (){
		logInfo("connected");

		client.send("");

	};

	client.connect();

	//string url = "http://localhost:8989/s4net/123/djashe213121212/";
	
	// Nachricht an Server -> POST -> daten
//	url~="xhr_send";
	// Poll
	//url~="xhr";
	// GET
	// Body = h -> heartbeat -> nächstes GET
	// c = close;
	// a["message","message2"] -> Daten
	// o beim ersten Call (open)
	
}
