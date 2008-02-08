package example;

public interface Worker<Input, Output> {
	Output doWork(Input input);
}