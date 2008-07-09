package example.visibility;
import java.util.ArrayList;

public class Visibility {
	private ArrayList<String> messages = new ArrayList<String>();
	public  ArrayList<String> getMessages() { return messages; }
	
	public    void publicMethod   (String s, int i) { protectedMethod("public: "+s, i); }
	protected void protectedMethod(String s, int i) { privateMethod("protected: "+s, i); }
	private   void privateMethod  (String s, int i) { 
		messages.add("private: "+s+", i="+i);
	}
}