module sockjsclient.client;

import std.stdio;
import vibe.d;
import std.uuid;
import std.random;
import std.regex;
import std.string;

class SockJsClient
{	
private:
	string m_url_send;
	string m_url_poll;
	enum ConnectionState { none, connecting, connected, clientDisconnected, hostDisconnected }
	ConnectionState m_connState = ConnectionState.none;
public:
	
	alias void delegate() EventOnConnect;
	alias void delegate(string) EventOnData;
	alias void delegate(int,string) EventOnDisconnect;

	EventOnConnect		OnConnect;
	EventOnData			OnData;	
	EventOnDisconnect	OnDisconnect;

	@property bool isConnected() const { return m_connState == ConnectionState.connected; }
	@property bool isConnecting() const { return m_connState == ConnectionState.connecting; }

	///
	this(string host, string prefix)
	{
		auto randomUUId = randomUUID();
		auto randomInt = uniform(100,999);
		auto url = format("%s/%s/%s/%s/xhr",host,prefix,randomInt,randomUUId);
		m_url_poll = url;
		m_url_send = format("%s_send",m_url_poll);
	}

	///
	public void connect() 
	{
		if (m_connState == ConnectionState.none) 
		{
			m_connState = ConnectionState.connecting;
			StartPoll();
		}
		else
		{
			throw new Exception("only one connect allowed");		
		}
	}

	///
	public void disconnect()
	{
		//TODO: Should send an message on close url
		if (m_connState == ConnectionState.connected)
		{
			m_connState = ConnectionState.clientDisconnected;
		}
		else 
		{
			throw new Exception("Not connected");
		}
	}

	///
	public void send(string message) 
	{	
		if (m_connState == ConnectionState.connected)
		{
			runTask({
				requestHTTP(m_url_send,
				            (scope HTTPClientRequest req) {
					req.method = HTTPMethod.POST;
					auto prep_message = "[\""~message~"\"]";
					req.writeBody(cast (ubyte[])prep_message,"text/plain");
					},
					(scope res) { 
						onSendResult(res);
					}
				);
			});
		} 
		else 
		{
			throw new Exception("Not connected");
		}
	}

	///
	private void onSendResult( HTTPClientResponse res) {
		// TODO: Error handling - HTTP ERROR CODES
		//logInfo("Response: %s", res.bodyReader.readAllUTF8());
		if (res.statusCode != 204)
		{
			throw new Exception("Send error - Status Code: " ~ to!string(res.statusCode));
		}

	}

	///
	private void StartPoll()
	{
		if (m_connState == ConnectionState.connected || m_connState == ConnectionState.connecting)
		{
			requestHTTP(m_url_poll,
						(scope req) {},
						(scope res) { 
							onPollResult(res);
						}
			);
		}
		else
		{
			throw new Exception("Not connected");
		}
	}

	///
	private void onPollResult( HTTPClientResponse res) 
	{
		auto content = res.bodyReader.readAllUTF8();

		if (m_connState == ConnectionState.clientDisconnected)
			return;
		
		if (content == "o\n") 
		{
			m_connState = ConnectionState.connected;

			CallOnConnect();
		} 
		else if (content == "h\n") 
		{
			//logInfo("got heartbeat");
		} 
		else 
		{
			if (m_connState == ConnectionState.connected) 
			{
				if (content[0] == 'a')
				{
					if (OnData != null)
					{
						auto arr = content[3..$-3];
						foreach(a; splitter(arr,regex(q"{","}")))
						{
							CallOnData(a);
						}
					}
				}
				else if (content[0] == 'c') 
				{
					m_connState = ConnectionState.hostDisconnected;
					if (OnDisconnect != null)
					{
						auto closeString = content[2..$-2];
						auto closeArray = closeString.split(",");
						if (closeArray.length >= 2) 
						{
							int closeCode = closeArray[0].to!int;
							string closeMessage = closeArray[1][1..$-1];

							CallOnDisconnect(closeCode, closeMessage);
						}
						else 
						{
							CallOnDisconnect();
						}
					}
				}	
			}
		}

		if (m_connState == ConnectionState.connected || m_connState == ConnectionState.connecting)
		{
			runTask({
				StartPoll();
			});
		}
	}

	///
	private void CallOnConnect()
	{
		if(OnConnect)
		{
			runTask({
				OnConnect();
			});
		}
	}

	///
	private void CallOnData(string _msg)
	{
		if(OnData)
		{
			runTask({
				OnData(_msg);
			});
		}
	}

	///
	private void CallOnDisconnect(int _code=0, string _msg="")
	{
		if(OnDisconnect)
		{
			runTask({
				if(OnDisconnect)
					OnDisconnect(_code, _msg);
			});
		}
	}
}

