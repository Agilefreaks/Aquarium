package example.sorter.converter;

import example.sorter.*;
import java.util.*;

/**
 * A really ad-hoc, strange class that demonstrates advising Java classes with Aquarium.
 * Disclaimer:
 * Normally, the "and" in the class name would be a sign of a bad design and it's usually
 * a bad idea to extend concreate classes and override concrete methods! So, don't take this
 * class as an example of good Java design, please! ;)
 */
public class StringListCaseConverterAndSorter extends StringListSorter {
	private boolean convertToLowerCase = true;

	public StringListCaseConverterAndSorter(boolean convertToLowerCase, Comparator<String> comparator) {
		super(comparator);
		this.convertToLowerCase = convertToLowerCase;
	}
	
	public StringListCaseConverterAndSorter(Comparator<String> comparator) {
		super(comparator);
	}
	
	public List<String> doWork(List<String> input) {
		List<String> newList = convertCase(input);
		return super.doWork(newList);
	}
	
	public List<String> convertCase(List<String> input) {
		List<String> newList = new ArrayList<String>(input.size());
		for (String s: input) {
			if (convertToLowerCase)
				newList.add(s.toLowerCase());
			else
				newList.add(s.toUpperCase());
		}
		return newList;
	}
}