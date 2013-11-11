import std.stdio;
import vibe.d;

class SockJsClient
{
	
	private:
		string m_url_send;
		string m_url_poll;

	public:
	
	alias void delegate() EventOnConnect;

	EventOnConnect onConnect;

	this(string host, string prefix)
	{
		//auto random = randomUUID();
		m_url_send = format("%s/%s/123/adsjdsadjdajs2131312/xhr_send",host,prefix);
		m_url_poll = format("%s/%s/123/adsjdsadjdajs2131312/xhr",host,prefix);
	}

	public void connect() 
	{
		StartPoll();
	}

	public void send(string message) 
	{	
		requestHTTP(m_url_send,
			(scope req) {
				req.method = HTTPMethod.POST;
				req.writeJsonBody([message]);
			},
			(scope res) { 
				onSendResult(res);
			}
		);
	}

	private void onSendResult( HTTPClientResponse res) {
		logInfo("Response: %s", res.bodyReader.readAllUTF8());
	}

	private void StartPoll()
	{
		requestHTTP(m_url_poll,
					(scope req) {},
					(scope res) { 
						onPollResult(res);
					}
		);
	}

	private void onPollResult( HTTPClientResponse res) {
		//TODO Start Poll am Ende
		auto content = res.bodyReader.readAllUTF8();
		logInfo("Response: %s", content);
		
		if (content == "o\n") {
			if(onConnect != null) {
				onConnect();
			}
		}
	}
	

}


//TODO:
// Close function onClose
// Message function onMessage(str)
// 
shared static this()
{
	SockJsClient client;
	string url = "http://localhost:8989/echo/";
	client = new SockJsClient("http://localhost:8989","echo");
	
	client.onConnect = (){
		logInfo("connected");

		client.send("hello");
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
