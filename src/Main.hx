import PropsSystemTest.PropSystemTest;
import EventSystemTest;

class Main {
	public static function main() {
		utest.UTest.run([new EventSystemTest(), new EventNetworkTest(), new PropSystemTest(), new IntentSystemTest(), new ComponentTest()]);
	  }
}
