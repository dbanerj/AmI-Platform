#include "ami_environment.h"
#include <stdlib.h>

char* getKestrelServerIP() {
	char *result = getenv("AMI_KESTREL_SERVER_IP");
	if (result == NULL)
		return "ami-crunch-01.local";
	else
		return result;
}

int getKestrelServerPort() {
	char *result = getenv("AMI_KESTREL_SERVER_PORT");
	if (result == NULL)
		return 22133;
	else
		return atoi(result);
}

char* getSensorPosition() {
    char *result = getenv("AMI_SENSOR_POSITION");
    if (result == NULL)
        return "{\"X\": 0.0, \"Y\": 0.0, \"Z\": 0.0, "
               "\"alpha\": 0.0, \"beta\": 0.0, \"gamma\": 0.0}";
    return result;
}

char* getSensorID() {
	// gets value of AMI_SENSOR_ID env variable
	// set in ~/.pam_environment
	char *sensor_id = getenv("AMI_SENSOR_ID");
	if (sensor_id == NULL)
		return "anonymous";
	return sensor_id;
}

char* getKinectXMLConfig() {
	char *config = getenv("AMI_KINECT_CONFIG_XML");
	if (config == NULL)
		return "/home/ami/AmI-Platform/acquisition/kinect/SamplesConfig.xml";
	return config;
}

