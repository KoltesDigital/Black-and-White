module src.bnw;

import derelict.alure.alure;
import derelict.devil.il;
import derelict.devil.ilu;
import derelict.devil.ilut;
import derelict.glfw3.glfw3;
import derelict.openal.al;
import derelict.opengl3.gl3;
import src.background;
import src.constants;
import src.input;
import src.joystick;
import src.particles;
import src.players;
import src.resources;
import src.scenes;
import src.shaders;
import src.variables;
import std.conv;
import std.datetime;
import std.file;
import std.json;
import std.random;
import std.range;
import std.stdio;
import std.string;

debug bool variableMode = false;

Scene scene, nextScene, loadingScene, gameScene;

void setScene(Scene scene)
{
	debug writeln("Changing scene to ", scene);
	nextScene = scene;
}

void takeScreenshot()
{
	immutable string fileName = "screenshots/" ~ Clock.currTime().toISOString() ~ ".png";
	ILuint imageID = ilGenImage();
	ilBindImage(imageID);
	ilutGLScreen();
	ilEnable(IL_FILE_OVERWRITE);
	ilSaveImage(toStringz(fileName));
	ilDeleteImage(imageID);
	writeln("Screenshot saved to ", fileName);
}

extern (C) void keyCallback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
	if (key == GLFW_KEY_ESC)
		glfwSetWindowShouldClose(window, true);
	
	debug if (key == GLFW_KEY_V && action == GLFW_PRESS)
	{
		if (variableMode)
		{
			variableMode = false;
			writeln("variable mode off");
		}
		else
		{
			variableMode = true;
			writeln("variable mode on");
			writeln("> ", variableSet.loadedFileName);
			writeln(">> ", variableSet.currentVariableName);
		}
	}
	
	if (key == GLFW_KEY_ENTER && action == GLFW_PRESS)
	{
		players[0].swapJoystick();
		players[1].swapJoystick();
	}
	
	if (key == GLFW_KEY_SPACE && action == GLFW_PRESS)
	{
		takeScreenshot();
	}
}

extern (C) void focusCallback(GLFWwindow* window, int focus)
{
	//	if (focus)
	//	{
	//		resourceManager.updateAllResources({
	//			setScene(gameScene);
	//		});
	//	}
}

/// Program entry!
void main()
{
	// Youou, we're going to have fun!
	DerelictAL.load();
	DerelictALURE.load();
	DerelictGL3.load();
	DerelictGLFW3.load();
	DerelictIL.load();
	DerelictILU.load();
	DerelictILUT.load();
	
	auto init = glfwInit();
	assert(init);
	
	/*glfwWindowHint(GLFW_RESIZABLE, false);
	 glfwWindowHint(GLFW_SAMPLES, 4);*/
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
	//glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
	
	GLFWmonitor* monitor;
	debug {}
	else
	{
		monitor = glfwGetPrimaryMonitor();
	}
	
	auto window = glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Black and White", monitor, null);
	
	if (!window)
	{
		writeln("Unable to open window.");
		return;
	}
	
	glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
	
	input = new Input(window);
	glfwSetKeyCallback(window, &keyCallback);
	
	glfwMakeContextCurrent(window);
	
	// Load OpenGL in earnest
	auto glVersion = DerelictGL3.reload();
	if (glVersion < 31)
	{
		writeln("OpenGL 3.1 is not supported, up to ", glVersion);
		return;
	}
	
	Joystick joystick = new Joystick();
	
	debug initVariables();
	
	ilInit();
	iluInit();
	ilutRenderer(ILUT_OPENGL);
	ilutEnable(ILUT_OPENGL_CONV);
	
	glGetError(); // reset
	
	ALCdevice *dev;
	ALCcontext *ctx;
	dev = alcOpenDevice(null);
	if(!dev)
	{
		writeln("Cannot open audio device");
		return ;
	}
	ctx = alcCreateContext(dev, null);
	alcMakeContextCurrent(ctx);
	if(!ctx)
	{
		writeln("Cannot get audio context");
		return ;
	}
	
	immutable float[6] orientation = [0, 0, -1, 0, 1, 0];
	checkAlError(alListener3f(AL_POSITION, 0, 0, 0));
	checkAlError(alListener3f(AL_VELOCITY, 0, 0, 0));
	checkAlError(alListenerfv(AL_ORIENTATION, orientation.ptr));
	checkAlError(alDistanceModel(AL_NONE));
	
	resourceManager = new ResourceManager();
	resourceManager.errorHandler = (string fileName) {
		debug writeln("Error while loading ", fileName);
		setScene(loadingScene);
	};
	
	glfwSetWindowFocusCallback(window, &focusCallback);
	
	loadingScene = new Scene();
	gameScene = new GameScene();
	
	scene = loadingScene;
	setScene(gameScene);
	
	createPlayers();
	
	debug glClearColor(1, 0, 0, 0);
	else glClearColor(0, 0, 0, 0);
	assert(!glGetError());
	
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glEnable(GL_CULL_FACE);
	
	glfwSwapInterval(1);
	
	double currentTime = glfwGetTime();
	double lastTime = currentTime;
	float dt;
	
	double variableLastTime = currentTime;
	
	bool refresh = false;
	
	double nextSpawnTime = currentTime;
	float x = 0, y = 0;
	
	while (!glfwWindowShouldClose(window))
	{
		currentTime = glfwGetTime();
		dt = currentTime - lastTime;
		lastTime = currentTime;
		
		resourceManager.process();
		
		if (nextScene && nextScene.isLoaded)
		{
			scene = nextScene;
			nextScene = null;
		}
		
		debug
		{
			if (variableMode)
				variableSet.update(dt);
		}
		
		scene.update(dt);
		
		glfwSwapBuffers(window);
		
		glfwPollEvents();
	}
	
	scene = nextScene = null;
	
	delete loadingScene;
	delete gameScene;
	
	deletePlayers();
	
	delete resourceManager;
	
	glfwTerminate();
	
	DerelictAL.unload();
	DerelictALURE.unload();
	DerelictGL3.unload();
	DerelictGLFW3.unload();
	DerelictIL.unload();
	DerelictILU.unload();
	DerelictILUT.unload();
}
