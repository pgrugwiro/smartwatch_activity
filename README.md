# Activity_Monitor
Activity monitoring using smartphone and smart watch. Opensource dataset from UCI ML Dataset repository at: https://archive.ics.uci.edu/ml/datasets/WISDM+Smartphone+and+Smartwatch+Activity+and+Biometrics+Dataset+

The objective of this project is to build a model that would accurately recognize the physical activity being
performed by an individual based on the data collected by the smartwatch’s accelerometer. An accelerometer
is an electromechanical device built into a mobile device that measures the dynamic acceleration forces,
commonly known as g-forces. Along with a gyroscope, the accelerometer allows the mobile device to track
its movements. The accelerometer collects the g-forces by measuring the change in velocity in the threedimensional
space, i.e. along the x, y, and z axes and reports the values in increments of the gravitational
acceleration in a given direction, x, y, or z. A value of 1.0 represents 9.81 meters per second per second.
Below is a visual sketch (image from apple.com) of the accelerator.
Based on accelerometer readings, can we accurately recognize the physical activity being performed among
these four activities: A= walking, B= jogging, C= climbing stairs, or P= dribbling a basketball?
Dataset
The dataset that is used in this project was taken from UCI Machine Learning Repository archive (https://
archive.ics.uci.edu/ml/machine-learning-databases/00507/) and was simplified for this project. The overall
dataset contains high speed (20Hz) time series data from both a smartphone and a smartwatch from 50 test
subjects as they perform 18 activities for 3 minutes per activity. In addition, for each device, the gyroscope
and the accelerometer were both used to collect raw data. There are therefore 4 different directories of data.
For this project, a subset of this data was used:
• Collection method: Smartwatch accelerometer.
• Activity: Only 4 activities were considered for this study (A, B, C, & P)
• Logging: Instead of using the entire 20Hz data, a 10-second window average was used for this project,
i.e. 200 datapoints per window were averaged to provide one datapoint. This reduced the total number
of datapoints to 18 per user per activity.
