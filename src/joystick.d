module src.joystick;

import derelict.glfw3.glfw3;
import std.math;

class Joystick
{
public:
	int id = GLFW_JOYSTICK_1;
	
	void update()
	{
		int buttonCount, axisCount;
		ubyte* buttons = glfwGetJoystickButtons(id, &buttonCount);
		float* axes = glfwGetJoystickAxes(id, &axisCount);
		
		_previousAxes.length = _axes.length;
		_previousAxes[] = _axes;
		
		_axes.length = axisCount;
		_axes[] = axes[0..axisCount];
		
		_previousButtons.length = _buttons.length;
		_previousButtons[] = _buttons;
		
		_buttons.length = buttonCount;
		_buttons[] = buttons[0..buttonCount];
	}
	
	float dialProgress(int xAxis, int yAxis)
	{
		if (xAxis >= _axes.length || xAxis >= _previousAxes.length
		    || yAxis >= _axes.length || yAxis >= _previousAxes.length)
			return 0;
		
		if (_axes[xAxis] ^^ 2 + _axes[yAxis] ^^ 2 < DIAL_THRESHOLD_SQUARED
		|| _previousAxes[xAxis] ^^ 2 + _previousAxes[yAxis] ^^ 2 < DIAL_THRESHOLD_SQUARED)
			return 0;
		
		float angle = atan2(_axes[yAxis], _axes[xAxis]);
		float previousAngle = atan2(_previousAxes[yAxis], _previousAxes[xAxis]);
		
		float delta = angle - previousAngle;
		if (delta >= PI)
			delta -= PI * 2;
		if (delta < -PI)
			delta += PI * 2;
		
		return (delta < 0 ? 1 : -1) * DIAL_FACTOR * abs(delta) ^^ DIAL_EXPONENT;
	}
	
	bool isPressed(int button)
	{
		return button < _buttons.length
			&& _buttons[button] != 0;
	}
	
	bool isToggled(int button)
	{
		return button < _buttons.length && button < _previousButtons.length
			&& _buttons[button] != _previousButtons[button];
	}
	
	bool isFirstPressed(int button)
	{
		return isPressed(button) && isToggled(button);
	}
	
	float axis(int axis)
	{
		if (axis < _axes.length)
		{
			float value = _axes[axis];
			if (abs(value) > AXIS_DEAD_ZONE)
				return value;
		}
		return 0;
	}
	
private:
	float[] _axes;
	ubyte[] _buttons;
	
	float[] _previousAxes;
	ubyte[] _previousButtons;
	
	static const float DIAL_THRESHOLD_SQUARED = 0.8;
	static const float DIAL_EXPONENT = 2;
	static const float DIAL_FACTOR = 1000;
	
	static const float AXIS_DEAD_ZONE = 0.2;
}
