import std.stdio;
import vibe.d;
import std.uuid;
import std.random;

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
		auto randomUUId = randomUUID();
		auto randomInt = uniform(100,999);
		auto url = format("%s/%s/%s/%s/xhr",host,prefix,randomInt,randomUUId);
		m_url_poll = url;
		m_url_send = format("%s_send",m_url_poll);
	}

	public void connect() 
	{
		StartPoll();
	}

	public void send(string message) 
	{	
		logInfo(message);
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
		} else if (content == "h\n") {
			logInfo("got heartbeat");
		}
		StartPoll();
	}
	

}


//TODO:
// Close function onClose
// Message function onMessage(str)
// 
shared static this()
{
	SockJsClient client;
	client = new SockJsClient("http://localhost:8989","echo");
	
	client.onConnect = (){
		logInfo("connected");

		client.send("hello,dasd");
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
