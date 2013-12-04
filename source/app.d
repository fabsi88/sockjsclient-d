import std.stdio;
import vibe.d;
import std.uuid;
import std.random;
import std.base64;
import std.regex;
import xtea.XteaCrypto;
class SockJsClient
{
	
	private:
		string m_url_send;
		string m_url_poll;
		//enum pollRegex = ctRegex!(q"{a\[\"(.*)\"\]}");
		
		private XTEA m_xtea;
		bool m_connected = false;
	public:
	
	alias void delegate() EventOnConnect;

	EventOnConnect onConnect;

	this(string host, string prefix)
	{
		m_xtea = new XTEA([1,2,3,4],64);
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
				m_connected = true;
			}
		} else if (content == "h\n") {
			logInfo("got heartbeat");
		} else {
			if (m_connected) {
				logInfo("Connected");
				logInfo(content);
				//auto m = match(content,pollRegex);
				content = chop(content);
				content = chop(content);
				content = chop(content);
				content = chompPrefix(content,"a[\"");
				logInfo("%s",content);
				logInfo("%s",content.length);
				
				
				byte[] bytes = cast(byte[])Base64.decode(content);
				logInfo("'%s'",bytes);
				m_xtea.Decrypt(bytes,1);
				logInfo("'%s'",cast(string)bytes);
				/*


				logInfo("'%s'",cast(string)bytes);
				logInfo("%s",bytes.length);
			*/
			}
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
	client = new SockJsClient("http://localhost:9876","s4net");
	
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
