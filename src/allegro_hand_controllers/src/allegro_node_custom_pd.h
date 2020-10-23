#ifndef PROJECT_ALLEGRO_NODE_CUSTOM_PD_H
#define PROJECT_ALLEGRO_NODE_CUSTOM_PD_H

#include "allegro_node.h"

#include "ros/ros.h"
#include "std_msgs/String.h"
#include "std_msgs/Float32.h"

// Forward class declaration.
class BHand;

// Hand controller that uses the BHand library
// Author: Wenbin HU
//
class AllegroNodeCustomPD : public AllegroNode {

 public:

    AllegroNodeCustomPD();

    ~AllegroNodeCustomPD();

    void initController(const std::string &whichHand);

    void computeDesiredTorque();

    void libCmdCallback(const std_msgs::String::ConstPtr &msg);

    void setJointGains();

    void setJointCallback(const sensor_msgs::JointState &msg);

    void envelopTorqueCallback(const std_msgs::Float32 &msg);

    void doIt(bool polling);

 protected:

    // Handles external joint command (sensor_msgs/JointState).
    ros::Subscriber joint_cmd_sub;

    // Handles defined grasp commands (std_msgs/String).
    ros::Subscriber lib_cmd_sub;

    ros::Subscriber envelop_torque_sub;

    // Initialize BHand
    BHand *pBHand = NULL;

  double desired_position[DOF_JOINTS] = {0.0};
};

#endif //PROJECT_ALLEGRO_NODE_CUSTOM_PD_H
