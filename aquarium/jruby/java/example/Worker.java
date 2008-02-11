package example;

/**
 * An ad-hoc interface that demonstrates advising Java classes with Aquarium.
 * See the specs that use this interface for examples of what you can and can't do with them!
 */
public interface Worker<Input, Output> {
	Output doWork(Input input);
}