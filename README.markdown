# Aquarium README #

Aquarium is a toolkit for Aspect-Oriented Programming (AOP) whose goals include:

* A powerful *pointcut* language for specifying where to apply aspects, comparable to the pointcut language in AspectJ for Java.
* Management of concurrent aspects (i.e., those acting on the same *join points*).
* Adding and removing aspects dynamically.
* A user-friendly DSL.
* Support for advising Java types through JRuby.

## Why Is an AOP Framework Useful in Ruby?

Ruby's metaprogramming facilities already provide some of the capabilities for which static-language AOP toolkits like AspectJ are typically used. With Ruby, you can easily add new methods and attributes to existing classes and objects. You can alias and redefine existing methods, which provides the method interception and "wrapping" needed to extend or modify existing behavior.

However, what is missing in Ruby is an expressive language for describing systemic modifications, a so-called *pointcut language*. If you have simple needs for method interception and wrapping, then Aquarium will be overkill. However, if you have system-wide concerns that cross the boundaries of many objects, then an AOP tookit like Aquarium can help you implement these concerns in a more modular way.

So, if you are designing with aspects, wouldn't you like to write your code using the same language? Without AOP support, you have to map your aspect designs to metaprogramming idioms, which will often be slower to implement and harder to maintain. Imagine writing objects without native support for OOP!

## Terminology

Several terms are used in the AOP community.

* **Join Point** - A point of execution in a program where *advice* might be invoked.
* **Pointcut** - (yes, one word...) A set of join points of particular interest, like a query over all join points in the system.
* **Advice** - The behavior invoked at a join point. There are several kinds of advice:
  * **Before advice** - Advice invoked before the actual join point is invoked.
  * **After returning advice** - Advice invoked after the join point executes successfully.
  * **After raising advice** - Advice invoked only after the join point raises an exception.
  * **After advice** - Advice invoked after the join point executes successfully or raises an exception.
  * **Around advice** - Advice invoked instead of the join point. The around advice must choose whether or not to invoke the join point by calling a special `proceed` method. Otherwise, the join point is NOT executed.

Only around advice can prevent execution of the join point, except for the special case where before advice raises an exception.

## Installation

Aquarium is available from [RubyForge](http://aquarium.rubyforge.org). It is now maintained on [GitHub](http://github.com/deanwampler/Aquarium).

The simplest approach is to install the gem:

    gem install aquarium    # sudo may be required on non-Windows systems

## Examples

Several complete examples are provided in the *examples* directory.

In most cases, you can either declare the appropriate classes or use the optional DSL, which adds convenience methods to classes, objects, or even Object itself. The API also supports many synonyms for things like types, objects, and methods. The best place to see the full list of synonyms is the output of `pointcut_spec.rb`.

Here is an example that traces invocations of all public instance methods (included inherited ones) of the classes or modules Foo and Bar.

	require 'aquarium'
	Aspect.new :around, :calls_to => :all_methods, :on_types => [Foo, Bar] do |join_point, object, *args|
		p "Entering: #{join_point.target_type.name}##{join_point.method_name} for object #{object}"
		result = join_point.proceed
		p "Leaving: #{join_point.target_type.name}##{join_point.method_name} for object #{object}"
		result  # block needs to return the result of the "proceed"!
	end

The advice to execute at each join point is the block. The pointcut is the set of all public instance methods in Foo and Bar. (There are additional options available for specifying class methods, protected methods, excluding inherited (ancestor) methods, etc.) Here is the same example using the convenience DSL that adds aspect methods to Object (available only if you require aquarium/dsl/object_dsl', since other toolkits, like Rails, define similar methods on Object!).

	require 'aquarium/dsl/object_dsl'
	around :calls_to => :all_methods, :on_types => [Foo, Bar] do |join_point, object, *args|
		p "Entering: #{join_point.target_type.name}##{join_point.method_name} for object #{object}"
		result = join_point.proceed
		p "Leaving: #{join_point.target_type.name}##{join_point.method_name} for object #{object}"
		result  # block needs to return the result of the "proceed"!
	end

See `examples/method_tracing_example.rb` for a more detailed version of this example.

If you don't want to add these methods to Object, you can also add them individually to modules, classes, or objects:

	require 'aquarium'
	...
	module MyModule
		include Aquarium::DSL
	end

	class MyClass
		include Aquarium::DSL
	end

	my_object = MyOtherClass.new
	my_object.extend (Aquarium::DSL)

If you use the DSL inside a class and omit the `:type`, `:types`, `:object` `:objects` options, `self` is assumed.

	class Foo
		include Aquarium::DSL
		...
		def critical_operation *args
			...
		end
	end
	...
	class Foo
		around :critical_operation do |join_point, object, *args|
			p "Entering: Foo#critical_operation"
			result = join_point.proceed
			p "Leaving: Foo#critical_operation"
			result
		end
	end

It is important to note that aspect *instances* usually behave like class (static) variables, in terms of the lifetime of their effects. In the example shown, class Foo is permanently modified to do the print statements shown for all *critical methods*, unless you save the result of calling `around` to a variable, e.g., critical_operation_logging, and you explicitly call `critical_operation_logging.unadvise` at some future time. Put another way, the effects scope just like changes made when you reopen a class or module.

A common mistake is to create an aspect in an initialize method and assign it to an attribute. This usually means that you are creating long-lived, redundant aspects every time an instance of your class is created. The aspect modifications remain in effect even when the instances themselves are garbage collected!
 
Here are some more succinct examples, illustrating the API (using the DSL methods) and some of the various synonyms for methods, types, etc.

You can pass in pointcuts defined elsewhere:

	my_pointcut = Pointcut.new :invocations_of => /^do_/, :within_types => /Foo::Bar::/
	around :pointcuts => my_pointcut do |jp, obj, *args| ...         # Pass in a pointcut
	around :pointcuts => [my_pointcut, ...] do |jp, obj, *args| ...  # Pass in a pointcut array

As a convenience, since a `JoinPoint` is a `Pointcut` with one element, you can pass a `JoinPoint` object where `Pointcut` objects are expected:

    my_join_point1 = JoinPoint.new :type => Foo::Bar, :method => do_this
    my_join_point2 = JoinPoint.new :type => Foo::Bar, :method => do_that
    around :pointcuts => my_join_point1 do |jp, obj, *args| ...         
    around :pointcuts => [my_join_point1, my_join_point2, ...] do |jp, obj, *args| ...  

You can specify a single type, a type name, a type regular expression, or an array of the same. Note that `:type` and `:types` are synonymous. Use the singular form for better readability when you are specifying just one type. Other synonyms include `:on_types`, `:within_types`, and `:in_types`, plus the singular forms.

	around :type = A, ...
	around :type = "A", ...
	around :types => [A, B, ...], ...
	around :types => %w[A, B, ...], ...
	around :types => /A::.*Helper$/, ...
	around :types => [/A::.*Helper$/, /B::Foo.*/], ...

Everywhere `:type` is used, you can substitute `:class`, `:classes`, `:module`, or `:modules`. Note that they are treated as synonyms; there is currently no enforcement that the values passed with `:class`, for example, are actually classes, not modules.

There are also several prepositional prefixes allowed for any of the synonyms. E.g.,

	around :for_types = A, ...
	around :on_types = A, ...
	around :in_types = A, ...
	around :within_types = A, ...

Using the plural versions of the synonyms with method specifications sometimes read better:

	around :calls_to => :all_methods, :on_types => [A, B, ...], ...
	around :calls_to => :all_methods, :in_types => [A, B, ...], ...
	around :calls_to => :all_methods, :within_types => [A, B, ...], ...

You can specify types and their descendents (subclasses or included modules) or ancestors. The same synonym prefixes for `:types` and `:type` also apply.

	around :type_and_ancestors = A, ...
	around :types_and_ancestors = A, ...
	around :type_and_descendents = A, ...
	around :types_and_descendents = A, ...
	around :classes_and_descendents = A, ...
	around :modules_and_descendents = A, ...

Some of the synonyms:

	around :calls_to => :all_methods, :on_types_and_ancestors = A, ...
	around :calls_to => :all_methods, :in_types_and_ancestors = A, ...
	around :calls_to => :all_methods, :within_types_and_ancestors = A, ...
	and similarly for descendents
	
You can specify a single object or an array of objects. As for `:types`, you can use `:object`, `:objects`, `:on_objects`, `:within_object`, `:in_objects`, and the singular forms synonymously. 

	a1 = A.new
	a2 = A.new
	around :object = a1, ...
	around :objects => [a1, a2], ...

Some of the synonyms:

	around :calls_to => :all_methods, :on_objects = [a1, a2], ...
	around :calls_to => :all_methods, :in_objects = [a1, a2], ...
	around :calls_to => :all_methods, :within_objects = [a1, a2], ...

If no types or objects are specified, the object defaults to `self`. However, this default is only supported when using the DSL to create an aspect, e.g.,

	class MyClass
		include Aquarium::DSL
		def doit; ...; end
	
		around :method => doit, ...   # Implicit :object => self, i.e., MyClass
	end

You can specify a single method symbol (name), a regular expression, or an array of the same. The synonyms for `:methods` include `:method`, `:calls_to`, `:invoking`, `:invocations_of`, and `:sending_messages_to`. The special keywords `:all` and `:all_methods` mean match all methods, subject to the `:method_options` discussed next.

	around :method = :all_methods, ...
	around :method = :foo, ...
	around :methods = [:foo, :bar, :baz], ...
	around :methods = /^foo/, ...
	around :methods = [/^foo/, /bar$/], ...

Using the synonyms:

	around :calls_to = :all_methods, ...
	after  :invoking = :all_methods, ...
	after  :invocations_of = :all_methods, ...
	after  :sending_messages_to = :all_methods, ...
	after  :within_methods = :all_methods, ...

You can specify method options. By default, public instance methods only are matched. Note that `:methods => :all` or `:all_methods` with no method options matches all public instance methods, including ancestor (inherited and included module) methods. For all the method options (except for `:exclude_ancestor_methods`), you can append the suffix `_methods`. You can also use the `:restrict_methods_to` synonym for `:method_options`.

	around :methods = /foo/, :method_options => [:instance], ...  # match instance methods (default)
	around :methods = /foo/, :method_options => [:class], ...     # match class methods
	around :methods = /foo/, :method_options => [:public, :protected, :private], ... 
		# match public, protected, and private instance methods
	around :methods = /foo/, :method_options => [:singleton], ... # match singleton methods
	around :methods = /foo/, :method_options => [:exclude_ancestor_methods], ... 
		# ignore methods defined in ancestors, inherited classes and included modules 

With synonyms:

	around :calls_to = /foo/, :restricting_methods_to => [:singleton_methods], ... 

You can specify attributes, which are actually convenience methods for the attribute accessors. They work very much like the `:method` options. Note that `:all` is NOT supported in this case. The available synonyms are slightly more complicated, as shown in these examples.

	around :attribute  = :foo, ...                                 # defaults to methods #foo and #foo=
	around :attributes = :foo, ...                                 # the same
	around :accessing  = :foo, ...                                 # the same

	around :attribute = :foo, :attribute_options => [:readers]...  # only matches #foo 
	around :reading   = :foo                                       # the same
	
	
	around :attribute = :foo, :attribute_options => [:writers]...  # only matches #foo= 
	around :writing   = :foo                                       # the same

	around :attributes = [:foo, :bar, :baz], ...
	around :attributes = /^foo/, ...
	around :attributes = [/^foo/, /bar$/], ...

Again, it's important to remember that actually advising the attribute accesses is not done; it's the public accessor methods that are advised! This may change in a future release.

You can specify a *Pointcut* that encapsulates one or more pre-defined Pointcuts or JoinPoints.

	around :pointcut = pc, ...                                     # for pre-defined pointcut "pc"
	around :pointcuts = [pc, ...], ...                             # for pre-defined pointcut list
	around :pointcut = jp, ...                                     # for pre-defined join point "jp"
	around :pointcuts = [jp, ...], ...                             # for pre-defined join point list
	around :pointcut = {:type => T, :method => :m}, ...            # same as around :type => T, :method => :m, ..

Using the plural versions of the synonyms, with method specifications so they read better:

	around :for_pointcuts => [pc1, pc2, ...], ...
	around :on_pointcuts => [pc1, pc2, ...], ...
	around :in_pointcuts => [pc1, pc2, ...], ...
	around :within_pointcuts => [pc1, pc2, ...], ...

Since V0.4.2, you can also specify *named* pointcuts, which are searched for just like methods in types (as discussed below).
For example, if several classes in module `App` define class constant pointcuts named STATE_CHANGE, the following expression
in an around advice aspect will match all of them:

	around :named_pointcuts => { :constants_matching => :STATE_CHANGE, :in_types => /App::.*/ } ...

For the type specification, which is required, any valid option for the TypeFinder class is allowed. 

You can also match on class variables, using `:class_variables_matching`. To match on either kind of definition, use just
`:matching`. If no :*matching is specified, then any class constant or variable Pointcut found will be matched. 

Here are the various `:*matching` options and their synonyms:

	around :named_pointcuts => { :constants_matching            => :STATE_CHANGE, ... } ...   # class constants only
	around :named_pointcuts => { :constants_named               => :STATE_CHANGE, ... } ...
	around :named_pointcuts => { :constants_with_names_matching => :STATE_CHANGE, ... } ...

	around :named_pointcuts => { :class_variables_matching            => :STATE_CHANGE, ... } ...   # class variables only
	around :named_pointcuts => { :class_variables_named               => :STATE_CHANGE, ... } ...
	around :named_pointcuts => { :class_variables_with_names_matching => :STATE_CHANGE, ... } ...

	around :named_pointcuts => { :matching            => :STATE_CHANGE, ... } ...   # class constants and variables
	around :named_pointcuts => { :named               => :STATE_CHANGE, ... } ...
	around :named_pointcuts => { :with_names_matching => :STATE_CHANGE, ... } ...

The `:*matching` options take a name, regular expression or array of the same (you can mix names and regular expressions).

You can also use the following synonyms for `:named_pointcuts`:

	around :named_pointcut => {...}
	around :for_named_pointcut => {...}
	around :on_named_pointcut => {...}
	around :in_named_pointcut => {...}
	around :within_named_pointcut => {...}
	around :for_named_pointcuts => {...}
	around :on_named_pointcuts => {...}
	around :in_named_pointcuts => {...}
	around :within_named_pointcuts => {...}
	
You can specifically exclude particular pointcuts, join points, types, objects, methods, or attributes. This is useful when you specify a list or regular expression of "items" to match and you want to exclude some of the items.
Note that there is an open bug (#15202) that appears to affect advising types, unadvising the types, then advising objects of the same types. (This is not likely to happen a lot in real applications, but it shows up when running Aquarium's specs.)

	around ..., :exclude_pointcut = pc, ...
	around ..., :exclude_pointcuts = [pc, ...]
	around ..., :exclude_named_pointcut = {...}
	around ..., :exclude_named_pointcuts = {...}
	around ..., :exclude_join_point = jp, ...
	around ..., :exclude_join_points = [jp, ...]
	around ..., :exclude_type = t, ...
	around ..., :exclude_types = [t, ...]
	around ..., :exclude_type_and_ancestors = t, ...
	around ..., :exclude_types_and_ancestors = [t, ...]
	around ..., :exclude_type_and_descendents = t, ...
	around ..., :exclude_types_and_descendents = [t, ...]
	around ..., :exclude_object = o, ...
	around ..., :exclude_objects = [o, ...]
	around ..., :exclude_method = m, ...
	around ..., :exclude_methods = [m, ...]
	around ..., :exclude_attribute = a, ...
	around ..., :exclude_attributes = [a, ...]

All the same synonyms for `:pointcuts`, `:named_pointcuts`, `:types`, `:objects`, and `:methods` apply here as well (after the `exclude_` prefix).

You can advice methods before execution:

	before :types => ...

You can advice methods after returning successfully (i.e., no exceptions were raised):

	after_returning :types => ...
	after_returning_from :types => ...	# synonym
	
You can advice methods after raising exceptions:

	after_raising :types => ...              # After any exception is thrown
	after_raising_within :types => ...       # synonym
	after_raising => MyError, :types => ...  # Only invoke advice if "MyError" is raised.
	after_raising => [MyError1, MyError2], :types => ...  
		# Only invoke advice if "MyError1" or "MyError2" is raised.
	 
You can advice methods after returning successfully or raising exceptions. (You can't specify
a set of exceptions in this case.):

	after :types => ...
	after_raising_within_or_returning_from : types =>	# synonym
	
You can advice methods both before after. This is different from around advice, where the around advice has to explicitly invoke the join point (using JoinPoint#proceed). Instead, the before-and-after methods are convenience wrappers around the creation of separate before advice and the corresponding after advice.

	before_and_after :types =>, ...
	before_and_after_returning :types =>, ...
	before_and_after_returning_from :types =>, ...	# synonym
	before_and_after_raising :types =>, ...
	before_and_after_raising_within :types =>, ...	# synonym
	before_and_after_raising_within_or_returning_from :types =>, ...	# synonym

If you pass a block to Aspect.new, it will be the advice. When invoked, the advice will be passed the following three arguments, 
	1) the JoinPoint, which will contain a `JoinPoint::Context` object with useful context information, 
	2) the object being sent the current message, and 
	3) the parameters passed with the original message. 
Recall that a Proc doesn't check the number of arguments (while lambdas do), so if you don't care about any of the trailing parameters, you can leave them out of the parameter list. Recall that the other difference between the two is that a return statement in a Proc returns from the method that contains it. As rule, do NOT use return statements in advices!

	around :type => [...], :methods => :all do |join_point, object, *args|
	  advice_to_execute_before_the_jp
	  result = join_point.proceed	# Invoke the join point, passing *args implicitly (you can override...)
	  advice_to_execute_after_the_jp
	  result     # return the result of the "proceed", unless you override the value.
	end
	around(:type => [...], :methods => :all) {|join_point, object, *args| ...}  # (...) necessary for precedence...

In the example, we show that you must be careful to return the correct value, usually the value returned by `proceed` or a value created by the block itself.

**NOTE:** prior to V0.2.0, the advice argument list was `|join_point, *args|`. Aquarium will look for such obsolete signatures (by looking at the arity of the proc) and raise an exception, if found. This check will be removed in a future release.
 
Rather than passing a block as the advice, you can pass a previously-created Proc:
	
	around :type => [...], :methods => :all, :advice => advice 
	around :type => [...], :methods => :all, :advise_with => advice  # synonym for advice. Note the "s"!
	around :type => [...], :methods => :all, :call => advice         # synonym for advice.
	around :type => [...], :methods => :all, :invoke => advice       # synonym for advice.

Finally, when running in *JRuby*, you can advise Java types! See the examples in the separate RSpec suite in the `jruby` directory and the discussion above concerning known limitations.

## Building Aquarium ##

The gem is ready to go, but if you want to rebuild it, run the tests, etc., here's what to do.

### Building the Aquarium gem

If you prefer to build the gem locally, check out source from GitHub

    git clone git@github.com:deanwampler/Aquarium.git

(or fork it)

WARNING: The older RubyForge SVN repository (`svn://rubyforge.org/var/svn/aquarium/trunk`) is now obsolete!!    

Use the following commands to build everything:

    rake gem
    gem install pkg/aquarium-x.y.z.gem   # sudo may be required

### Running Aquarium's RSpecs

In order to run Aquarium's full suite of specs (`rake pre_commit`) you must install the following gems and tools:

* **rake** - Runs the build script
* **rspec** - Used instead of Test::Unit for TDD
* **rcov** - Verifies that the code is 100% covered by specs
* **webgen** - Generates the static HTML website
* **RedCloth** - Required by webgen
* **syntax** - Required by RSpec's custom webgen extension to highlight ruby code
* **diff-lcs** - Required if you use the --diff switch
* **win32console** - Required by the --colour switch if you're on Windows
* **meta_project** - Required in order to make releases at RubyForge
* **heckle** - Required if you use the --heckle switch
* **jruby** - Required if run the separate spec suite in the "jruby" directory

Once those are all installed, you should be able to run the suite with the following steps:

    git clone git@github.com:deanwampler/Aquarium.git
    cd aquarium
    rake spec

or

    rake spec_rcov      # also runs rcov

Note that Aquarium itself, once built, doesn't have any dependencies outside the Ruby core and stdlib.

If you want to run the tests for the JRuby support, you must also have JRuby 1.1 or later installed. To run the specs for JRuby, use the command

    rake verify_jruby

This command runs the standard Aquarium specs using JRuby instead of MRI, then runs a separate set of specs in the `jruby/spec` directory which test Aquarium with Java classes inside JRuby.

See [http://aquarium.rubyforge.org](http://aquarium.rubyforge.org) for further documentation.

### Internals: Package Structure

`Aquarium::Aspects` contains the `Aspect` class and supporting classes `Pointcut`, `JoinPoint`, etc.

`Aquarium::Finders` provides tools for locating types, objects, and methods in the runtime, using names, symbols, or regular expressions.

`Aquarium::Extensions` provides extensions to several Ruby core library routines.

`Aquarium::Utils` provides general-purpose utilities for manipulating `Strings`, `Sets`, `Hashes`, etc. as well as some generic types.

`Aquarium::Extras` provides add-ons for Aquarium, such as a *Design by Contract* implementation. These extras are NOT included when you require the general `aquarium.rb` file. You have to explicitly include `aquarium/extras` or one of the `aquarium/extras/*` if you want to use them.

## Miscellania ##

A few other topics that might be of interest.

### Differences With Other Ruby AOP Toolkits

There are several other AOP toolkits for Ruby that precede Aquarium. The most notable are AspectR and the aspect capabilities in the Facets toolkit. There are also Ruby 2.0 proposals to add method wrappers for `before`, `after` and `wrap` behavior.

The goal of Aquarium is to provide a superset of the functionality provided by these other toolkits. Aquarium is suitable for non-trivial and large-scale aspect-oriented components in systems. Aquarium will be most valuable for systems where aspects might be added and removed dynamically at runtime and systems where nontrivial pointcut descriptions are needed, requiring a full-featured pointcut language (as discussed above...). For less demanding needs, the alternatives are lighter weight and hence may be more appropriate.

### Differences With AspectJ Behavior

Many of AspectJ's features are not currently supported by Aquarium, but some of them are planned for future releases.
 
* Attribute reading and writing join points are not supported. The `:attributes` and `:attributes_options` parameters (and their synonyms) for Aspect.new are actually *syntactic sugar* for the corresponding accessor methods. 
* More advanced AspectJ pointcut language features are not supported, such as the runtime pointcut designators like `if` conditionals and `cflow` (context flow) and the compile time `within` and `withincode` designators. Most of AspectJ pointcut language features are planned, however.
* While AspectJ provides *intertype declaration* capabilities (i.e., adding state and behavior to existing classes), Ruby's native metaprogramming support satisfies this need. There may be convenience hooks added in a future release, however.
* User defined advice precedence is not supported. However, advice precedence is unambiguous; the last aspects created while modules are loaded at runtime have higher precedence than earlier aspects. Ensuring a particular order is not always easy, of course. 

However, Aquarium does have a few advantages over AspectJ, especially when advising Java types when running in JRuby.

* Aquarium can add and remove advice dynamically, at runtime.
* Aquarium can advise individual objects, not just classes.
* Aquarium can advise JDK classes. AspectJ can also do this, but not by default.
* Aquarium supports named advice that can be defined separately from the aspects that use the advice. 
* Aquarium can advise ancestor (parent) types, not just derived (descendent) types of specified types. 

Note: at the time of this writing (V0.4.0 release), there is an important limitation of Aquarium when used with java code; it appears that advice is only invoked if an advised method is called directly from Ruby code. If the advised method is called by other Java code, the advice is *not* invoked. Whether or not this limitation can be removed is under investigation.

Also, as of V0.4.0, the interaction behavior of Aquarium and AspectJ or Spring aspects has not been investigated.

### Known Limitations

* You cannot advice `String`, `Symbol` or instances there of, because trying to specify either one will be confused with naming a type.
* Concurrent advice on type AND advice on objects of the type can't be removed cleanly.
* The pointcut language is still limited, compared to AspectJ's. See also the comparison with AspectJ behavior next.
* The API and wrapper DSL will probably evolve until the 1.0.0 release. Backwards compatibility will be maintained between releases as much as possible. When it is necessary to break backwards compatibility, translation tools will be provided, if possible.
* There are limitations when advising Java types through JRuby. The separate RSpec suite in the `jruby` directory documentations the details on how to use Aquarium with JRuby-wrapped Java types and the limitations thereof. Here we summarize what works and what doesn't:
  * Aquarium advice on a method in a Java type will only be invoked when the method is called directly from Ruby.
  * To have the advice invoked when the method is called from either Java or Ruby, it is necessary to create a subclass of the Java type in Ruby and an override of the method, which can just call `super`. Note that it will be necessary for instances of this Ruby type to be used throughout, not instances of a Java parent type.
  * BUG #18325: If you have Ruby subclasses of Java types *and* you advise a Java method in the hierarchy using @:types_and_descendents => MyJavaBaseClassOrInterface@ *and* you call unadvise on the aspect, the advice "infrastructure" is not correctly removed from the Ruby types. Workaround: Only advise methods in Ruby subclasses of Java types where the method is explicitly overridden in the Ruby class. (The spec and the "Rubyforge bug report":http://rubyforge.org/tracker/index.php?func=detail&aid=18325&group_id=4281&atid=16494 provide examples.)
  * BUG #18326: Normally, you can use either Java- or Ruby-style method names (e.g., `doSomething` vs. `do_something`), for Java types. However, if you write an aspect using the Java-style for a method name and a Ruby subclass of the Java type where the method is actually defined (i.e., the Ruby class doesn't override the method), it appears that the JoinPoint was advised, but the advice is never called. Workaround: Use the Ruby-style name in this scenario.

### Acknowledgments

My colleagues in the AOSD community, in particular those who developed *AspectJ*, have been a big inspiration.

The *RSpec* team, in particular David Chelimsky, have really inspired my thinking about what's possible in Ruby, especially in the realm of DSLs. I also cribbed parts of the RSpec Rake process ;)

My colleagues at [Object Mentor](http://objectmentor.com) are an endless source of insight and inspiration.

Finally, a number of users have contributed valuable feedback. In particular, thanks to Brendan L., Matthew F., and Mark V. 
