package example.sorter;

import example.*;
import java.util.*;

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