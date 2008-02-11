package example.sorter;

import example.*;
import java.util.*;

/**
 * An ad-hoc class that demonstrates advising Java classes with Aquarium.
 * See the specs that use this class for examples of what you can and can't do with them!
 */
public class StringListSorter implements Worker<List<String>, List<String>> {
	private Comparator<String> comparator;
	
	public StringListSorter(Comparator<String> comparator) {
		this.comparator = comparator;
	}
	
	public List<String> doWork(List<String> input) {
		List<String> newList = new ArrayList<String>(input);
		Collections.sort(newList, comparator);
		return newList;
	}
}