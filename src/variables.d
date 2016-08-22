module src.variables;

import src.joystick;
import std.conv;
import std.datetime;
import std.file;
import std.json;
import std.math;
import std.range;
import std.stdio : writeln;

interface Variable
{
	@property string name();
	@property string value();
	void read(JSONValue *value);
	void write(JSONValue *value);
	void handle(Joystick joystick, float dt);
}

class FloatVariable : Variable
{
public:
	this(string name, float* var, float factor = 1.0)
	{
		_name = name;
		_var = var;
		_factor = factor;
	}
	
	@property string name()
	{
		return _name;
	}
	
	@property string value()
	{
		return to!string(*_var);
	}
	
	void read(JSONValue *value)
	{
		if (value.type == JSON_TYPE.FLOAT)
			*_var = value.floating;
		else if (value.type == JSON_TYPE.INTEGER)
			*_var = value.integer;
		else if (value.type == JSON_TYPE.UINTEGER)
			*_var = value.uinteger;
	}
	
	void write(JSONValue *value)
	{
		value.type = JSON_TYPE.FLOAT;
		value.floating = *_var;
	}
	
	void handle(Joystick joystick, float dt)
	{
		if (!joystick.isPressed(0))
			*_var += (joystick.dialProgress(0, 1) - joystick.axis(2)) * _factor * dt;
		
		if (joystick.isFirstPressed(1))
			*_var += _factor;
		
		if (joystick.isFirstPressed(2))
			*_var -= _factor;
	}
	
private:
	string _name;
	float* _var;
	float _factor;
	
}

class IntVariable : FloatVariable
{
public:
	this(string name, int* var, float factor = 1.0)
	{
		_var = var;
		_floatVar = *var;
		super(name, &_floatVar, factor);
	}
	
	override void read(JSONValue *value)
	{
		if (value.type == JSON_TYPE.INTEGER)
			*_var = cast(int)value.integer;
		else if (value.type == JSON_TYPE.UINTEGER)
			*_var = cast(int)value.uinteger;
		else if (value.type == JSON_TYPE.FLOAT)
			*_var = cast(int)round(value.floating);
	}
	
	override void write(JSONValue *value)
	{
		value.type = JSON_TYPE.INTEGER;
		value.integer = *_var;
	}
	
	override void handle(Joystick joystick, float dt)
	{
		super.handle(joystick, dt);
		*_var = cast(int)round(_floatVar);
	}
	
private:
	int* _var;
	float _floatVar;
	
}

class FloatRange : Variable
{
public:
	this(string name, float* min, float* max, float factor = 1.0)
	{
		_name = name;
		_min = min;
		_max = max;
		_factor = factor;
	}
	
	@property string name()
	{
		return _name;
	}
	
	@property string value()
	{
		return "[" ~ to!string(*_min) ~ "," ~ to!string(*_max) ~ "]";
	}
	
	void read(JSONValue *value)
	{
		if (value.type == JSON_TYPE.ARRAY && value.array.length == 2)
		{
			JSONValue min = value.array[0];
			JSONValue max = value.array[1];
			
			if (min.type == JSON_TYPE.FLOAT)
				*_min = min.floating;
			else if (min.type == JSON_TYPE.INTEGER)
				*_min = min.integer;
			else if (min.type == JSON_TYPE.UINTEGER)
				*_min = min.uinteger;
			
			if (max.type == JSON_TYPE.FLOAT)
				*_max = max.floating;
			else if (max.type == JSON_TYPE.INTEGER)
				*_max = max.integer;
			else if (max.type == JSON_TYPE.UINTEGER)
				*_max = max.uinteger; 
		}
	}
	
	void write(JSONValue *value)
	{
		value.type = JSON_TYPE.ARRAY;
		value.array.length = 2;
		
		value.array[0].type = JSON_TYPE.FLOAT;
		value.array[0].floating = *_min;
		
		value.array[1].type = JSON_TYPE.FLOAT;
		value.array[1].floating = *_max;
	}
	
	void handle(Joystick joystick, float dt)
	{
		if (!joystick.isPressed(0))
		{
			float common = joystick.axis(2);
			*_min += (joystick.dialProgress(0, 1) - common) * _factor * dt;
			*_max += (joystick.dialProgress(3, 4) - common) * _factor * dt;
		}
		
		if (joystick.isFirstPressed(1))
		{
			*_min -= _factor;
			*_max += _factor;
		}
		
		if (joystick.isFirstPressed(2))
		{
			*_min += _factor;
			*_max -= _factor;
		}
		
		if (*_max < *_min)
			*_max = *_min;
	}
	
private:
	string _name;
	float* _min;
	float* _max;
	float _factor;
	
}

class VariableSet
{
public:
	this(Variable[] variables)
	{
		_variables = variables;
		joystick = new Joystick();
	}
	
	@property string currentVariableName()
	{
		return _variables[_currentVariable].name;
	}
	
	@property string currentVariableValue()
	{
		return _variables[_currentVariable].value;
	}
	
	@property string loadedFileName()
	{
		return _loadedFileName;
	}
	
	void load(string fileName)
	{
		_loadedFileName = fileName;
		string content = std.file.readText(fileName);
		auto data = parseJSON(content);
		
		if (data.type == JSON_TYPE.OBJECT)
		{
			foreach (Variable variable; _variables)
			{
				if (variable.name in data.object)
				{
					variable.read(&data.object[variable.name]);
				}
			}
		}
	}
	
	void save(string fileName)
	{
		_loadedFileName = fileName;
		
		JSONValue data;
		data.type = JSON_TYPE.OBJECT;
		
		foreach (Variable variable; _variables)
		{
			JSONValue value;
			variable.write(&value);
			data.object[variable.name] = value;
		}
		
		string content = toJSON(&data);
		std.file.write(fileName, content);
	}
	
	void loadNext(string dir)
	{
		++_currentVariableSet;
		auto entries = dirEntries(dir, SpanMode.breadth);
		popFrontN(entries, _currentVariableSet);
		if (entries.empty())
		{
			if (_currentVariableSet == 0)
				return;
			else
			{
				_currentVariableSet = -1;
				loadNext(dir);
			}
		}
		else
		{
			load(entries.front);
		}
	}
	
	void reload()
	{
		load(_loadedFileName);
	}
	
	void previousVariable()
	{
		--_currentVariable;
		if (_currentVariable < 0)
			_currentVariable = _variables.length - 1;
	}
	
	void nextVariable()
	{
		++_currentVariable;
		if (_currentVariable >= _variables.length)
			_currentVariable = 0;
	}
	
	void update(float dt)
	{
		joystick.update();
		
		if (joystick.isFirstPressed(4))
		{
			previousVariable();
			writeln(">> ", currentVariableName);
		}
		
		if (joystick.isFirstPressed(5))
		{
			nextVariable();
			writeln(">> ", currentVariableName);
		}
		
		if (joystick.isFirstPressed(6))
		{
			reload();
			writeln("> ", loadedFileName);
		}
		
		if (joystick.isFirstPressed(7))
		{
			load("variables.json");
			writeln("> ", loadedFileName);
		}
		
		if (joystick.isFirstPressed(8))
		{
			loadNext("variables");
			writeln("> ", loadedFileName);
		}
		
		if (joystick.isFirstPressed(9))
		{
			string fileName = "variables/" ~ Clock.currTime().toISOString();
			save(fileName);
			writeln("< ", fileName);
		}
		
		_variables[_currentVariable].handle(joystick, dt);
		
		writeln(loadedFileName, "\t", currentVariableName, "\t", currentVariableValue);
	}
	
private:
	Joystick joystick;
	Variable[] _variables;
	int _currentVariable = 0;
	
	int _currentVariableSet = -1;
	string _loadedFileName;
}