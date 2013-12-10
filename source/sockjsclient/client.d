module sockjsclient.client;

import std.stdio;
import vibe.d;
import std.uuid;
import std.random;
import std.base64;
import std.regex;
import xtea.XteaCrypto;
import std.string;

class SockJsClient
{	
private:
	string m_url_send;
	string m_url_poll;
	enum pollRegex = ctRegex!(q"{a\[\"(.*)\"\]}");
		
	private XTEA m_xtea;
	bool m_connected = false;

public:
	
	alias void delegate() EventOnConnect;
	alias void delegate(string) EventOnData;
	alias void delegate(string,int) EventOnDisconnect;

	EventOnConnect	OnConnect;
	EventOnData		OnData;
	EventOnDisconnect	OnDisconnect;

	private align (1) struct NetworkMsgHeader 
	{ 
		align (1):
		byte msgVersion;
		uint msgLength;
	}

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

		auto content = res.bodyReader.readAllUTF8();
		logInfo("Response: %s", content);
		
		if (content == "o\n") 
		{
			if(OnConnect != null)
			{
				OnConnect();
				m_connected = true;
			}
		} else if (content == "h\n") 
		{
			logInfo("got heartbeat");
		} else 
		{
			if (m_connected) 
			{
				logInfo("Connected");
				auto m = match(content,pollRegex);
				byte[] bytes = cast(byte[])Base64.decode(m.captures[1]);
				
				m_xtea.Decrypt(bytes,1);
				logInfo("'%s'",bytes);
				auto msgHeader = cast(NetworkMsgHeader*)&bytes[0]; 

				auto msg = cast(string)bytes[NetworkMsgHeader.sizeof .. NetworkMsgHeader.sizeof + msgHeader.msgLength]; 

				logInfo("%s",msg);
				//return array(msg.splitter(";"));
			}
		}
		StartPoll();
	}
}

