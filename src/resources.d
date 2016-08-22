module src.resources;

import core.time;
import core.thread;
import derelict.opengl3.gl3;
import src.constants;
import std.concurrency;
import std.container;
import std.conv : to;
import std.file;
import std.outbuffer;
import std.stdio : writeln;
import std.typecons;

alias void delegate(bool) Done;
alias void delegate() Complete;
alias void delegate(string fileName) ErrorHandler;
template Loaded(T) { alias void delegate(T) Loaded; }

interface Resource
{
}

interface HardcodedResource : Resource
{
	void load(Done done);
}

interface FileResource : Resource
{
	void load(Done done, const(ubyte[]) data);
}

class FileLoader
{
	this()
	{
		outBuffer = new OutBuffer();
		thread = spawn(&run);
	}
	
	void load(Done done, FileResource resource, string fileName)
	{
		Descriptor descriptor;
		descriptor.done = done;
		descriptor.resource = resource;
		queue.insertBack(descriptor);
		
		thread.send(fileName);
	}
	
	void process(float maxProcessTime)
	{
		long startTick = TickDuration.currSystemTick().length;
		
		while (receiveTimeout(Duration.zero,
		                      (immutable(ubyte[]) data)
		                      {
			outBuffer.write(data);
		},
		(bool ready)
		{
			Descriptor descriptor = queue.front;
			
			if (ready)
			{
				try
				{
					descriptor.resource.load(descriptor.done, outBuffer.toBytes());
				}
				catch (Exception e)
				{
					writeln(e);
					descriptor.done(false);
				}
			}
			else
				descriptor.done(false);
			
			queue.removeFront();
			outBuffer = new OutBuffer();
		}))
		{
			if ((TickDuration.currSystemTick().length - startTick) / cast(float)TickDuration.ticksPerSec >= maxProcessTime)
				return;
		}
	}
	
private:
	struct Descriptor
	{
		Done done;
		FileResource resource;
	}
	
	OutBuffer outBuffer;
	DList!Descriptor queue;
	Tid thread;
	
	static void run()
	{
		Tid owner = ownerTid;
		bool running = true;
		while (running)
		{
			receive(
				(string fileName)
				{
				try
				{
					ubyte[] data = cast(ubyte[])read(dataPath ~ fileName);
					owner.send(data.idup);
					owner.send(true);
				}
				catch
				{
					owner.send(false);
				}
			},
			(OwnerTerminated err)
			{
				running = false;
			}
			);
		}
	}
}

class ResourceManager
{
	ErrorHandler errorHandler;
	float maxProcessTime = 0.005;
	
	this()
	{
		fileLoader = new FileLoader();
	}
	
	~this()
	{
		debug foreach (string fileName, Instance instance; instances)
		{
			if (instance.references > 0)
				writeln("Resource '", fileName, "' has still ", instance.references, " reference(s).");
		}
	}
	
	void process()
	{
		while (!pendingCompleteDelegates.empty)
		{
			Complete complete = pendingCompleteDelegates.front;
			pendingCompleteDelegates.removeFront();
			complete();
		}
		
		fileLoader.process(maxProcessTime);
	}
	
	void updateAllResources(Complete complete = null)
	{
		uint resourceCount;
		bool error;
		
		void loaded(Object resource)
		{
			--resourceCount;
			if (!resourceCount && complete)
			{
				complete();
			}
		}
		
		foreach (string fileName, ref Instance instance; instances)
		{
			++resourceCount;
			instance.status = Status.LOADING;
			instance.loadedDelegates ~= &loaded;
			
			loadResource(fileName);
		}
	}
	
	void updateFailedResources(Complete complete = null)
	{
		uint resourceCount;
		bool error;
		
		void loaded(Object resource)
		{
			--resourceCount;
			if (!resourceCount && complete)
			{
				complete();
			}
		}
		
		foreach (string fileName, ref Instance instance; instances)
		{
			if (instance.status == Status.ERROR)
			{
				++resourceCount;
				instance.status = Status.LOADING;
				instance.loadedDelegates ~= &loaded;
				
				loadResource(fileName);
			}
		}
	}
	
package:
	T acquireResource(T)(string fileName, Loaded!T loaded)
	{
		debug writeln("Acquiring ", fileName);
		Instance* instance = fileName in instances;
		if (instance)
		{
			++instance.references;
			if (loaded)
			{
				if (instance.status == Status.READY)
					pendingCompleteDelegates.insert({
						loaded(cast(T)instance.resource);
					});
				else if (instance.status == Status.LOADING)
					instance.loadedDelegates ~= genericize!T(loaded);
			}
			return cast(T)instance.resource;
		}
		
		T newResource = new T();
		
		Instance newInstance;
		newInstance.resource = newResource;
		
		if (loaded)
			newInstance.loadedDelegates = [genericize!T(loaded)];
		
		static if (is(T:FileResource))
		{
			newInstance.origin = Origin.FILE;
		}
		
		instances[fileName] = newInstance;
		
		loadResource(fileName);
		
		return newResource;
	}
	
	void releaseResource(string fileName)
	{
		debug writeln("Releasing ", fileName);
		Instance* instance = fileName in instances;
		if (instance)
		{
			--instance.references;
			if (!instance.references)
			{
				Object resource = instance.resource;
				instances.remove(fileName);
				delete resource;
			}
		}
		else
			throw new Exception("Resource " ~ fileName ~ " is unknown");
	}
	
private:
	enum Origin
	{
		HARDCODED,
		FILE
	}
	
	enum Status
	{
		LOADING,
		READY,
		ERROR
	}
	
	struct Instance
	{
		Object resource;
		Loaded!Object[] loadedDelegates;
		uint references = 1;
		Status status = Status.LOADING;
		Origin origin;
	}
	
	FileLoader fileLoader;
	Instance[string] instances;
	DList!string lruInstances;
	SList!Complete pendingCompleteDelegates;
	
	void loadResource(string fileName)
	{
		Instance *instance = fileName in instances;
		
		void done(bool success)
		{
			if (success)
			{
				instance.status = Status.READY;
				foreach (loaded; instance.loadedDelegates)
				{
					loaded(instance.resource);
				}
			}
			else
			{
				instance.status = Status.ERROR;
				if (errorHandler)
					errorHandler(fileName);
			}
			
			instance.loadedDelegates.length = 0;
		}
		
		final switch (instance.origin)
		{
			case Origin.HARDCODED:
				pendingCompleteDelegates.insert({
					(cast(HardcodedResource)instance.resource).load(&done);
				});
				break;
				
			case Origin.FILE:
				fileLoader.load(&done, cast(FileResource)instance.resource, fileName);
				break;
		}
	}
	
	static Loaded!Object genericize(T)(Loaded!T loaded)
	{
		return ((Object resource) {
			loaded(cast(T)resource);
		});
	}
}

ResourceManager resourceManager;

class ResourceSet
{
	this(Complete complete = null)
	{
		this.complete = complete;
	}
	
	~this()
	{
		foreach (fileName; resources)
		{
			resourceManager.releaseResource(fileName);
		}
	}
	
	T acquire(T:HardcodedResource)(Loaded!T loaded = null)
	{
		return acquireResource!T(typeid(T).name, loaded);
	}
	
	T acquire(T:FileResource)(string fileName, Loaded!T loaded = null)
	{
		return acquireResource!T(fileName, loaded);
	}
	
private:
	uint resourceCount;
	string[] resources;
	Complete complete;
	
	T acquireResource(T)(string fileName, Loaded!T loaded = null)
	{
		++resourceCount;
		resources ~= fileName;
		T resource = resourceManager.acquireResource!T(fileName, (T resource) {
			if (loaded)
				loaded(resource);
			--resourceCount;
			if (!resourceCount && complete)
			{
				complete();
			}
		});
		return resource;
	}
	
}