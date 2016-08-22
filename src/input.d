module src.input;

import derelict.glfw3.glfw3;

class Input
{
	this(GLFWwindow* window)
	{
		this.window = window;
	}
	
	bool isPressed(int key)
	{
		return glfwGetKey(window, key) == GLFW_PRESS;
	}
	
private:
	GLFWwindow* window;
}

Input input;