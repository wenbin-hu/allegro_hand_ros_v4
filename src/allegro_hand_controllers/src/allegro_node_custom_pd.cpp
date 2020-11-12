#include "allegro_node_custom_pd.h"

#include "bhand/BHand.h"

AllegroNodeCustomPD::AllegroNodeCustomPD()
        : AllegroNode() {

  initController(whichHand);

  joint_cmd_sub = nh.subscribe(
          DESIRED_STATE_TOPIC, 3, &AllegroNodeCustomPD::setJointCallback, this);

}

AllegroNodeCustomPD::~AllegroNodeCustomPD() {
  delete pBHand;
}

// the gains are from http://wiki.wonikrobotics.com/AllegroHandWiki/index.php/PD_control_api
// This function should be called after the function SetMotionType() is called.
// Once SetMotionType() function is called, all gains are reset using the default values.
void AllegroNodeCustomPD::setJointGains(){
    if (!pBHand) return;
    // A little bit too high for grasping
    double kp[16] = {
		500, 800, 900, 500,
		500, 800, 900, 500,
		500, 800, 900, 500,
		1500, 700, 600, 600
	};
	double kd[16] = {
		25, 50, 55, 40,
		25, 50, 55, 40,
		25, 50, 55, 40,
		50, 50, 50, 40
	};

    // Default parameters from allegro_node_pd.cpp
    // A little bit too high for grasping experiment.
    // double kp[16] = {
    //     600.0, 600.0, 600.0, 1000.0, 600.0, 600.0, 600.0, 1000.0,
    //     600.0, 600.0, 600.0, 1000.0, 1000.0, 1000.0, 1000.0, 600.0
    //     };

    // double kd[16] = {
    //     15.0, 20.0, 15.0, 15.0, 15.0, 20.0, 15.0, 15.0,
    //     15.0, 20.0, 15.0, 15.0, 30.0, 20.0, 20.0, 15.0
    //     };

    // tuned by Wenbin, with the hand mounted on the default pillar, placed on the table.
    // the P gains are TOO high for grasping. Use default for now.
    // double kp[16] = {
    //     1000.0, 875.0, 875.0, 875.0, 
    //     1000.0, 875.0, 875.0, 875.0, 
    //     1000.0, 875.0, 875.0, 875.0, 
    //     1000.0, 1000.0, 1000.0, 600.0
    //     };

    // double kd[16] = {
    //     20.0, 20.0, 15.0, 15.0, 
    //     20.0, 20.0, 15.0, 15.0, 
    //     20.0, 20.0, 15.0, 15.0, 
    //     30.0, 20.0, 20.0, 15.0
    //     };
	pBHand->SetGainsEx(kp, kd);
}

// Called when a desired joint position message is received
void AllegroNodeCustomPD::setJointCallback(const sensor_msgs::JointState &msg) {
  mutex->lock();

  for (int i = 0; i < DOF_JOINTS; i++)
    desired_position[i] = msg.position[i];
  mutex->unlock();

  pBHand->SetJointDesiredPosition(desired_position);
  pBHand->SetMotionType(eMotionType_JOINT_PD);
  setJointGains();
}


void AllegroNodeCustomPD::computeDesiredTorque() {
  // compute control torque using Bhand library
  pBHand->SetJointPosition(current_position_filtered);

  // BHand lib control updated with time stamp
  pBHand->UpdateControl((double) frame * ALLEGRO_CONTROL_TIME_INTERVAL);

  // Necessary torque obtained from Bhand lib
  pBHand->GetJointTorque(desired_torque);

  //ROS_INFO("desired torque = %.3f %.3f %.3f %.3f", desired_torque[0], desired_torque[1], desired_torque[2], desired_torque[3]);
}

void AllegroNodeCustomPD::initController(const std::string &whichHand) {
  // Initialize BHand controller
  if (whichHand.compare("left") == 0) {
    pBHand = new BHand(eHandType_Left);
    ROS_WARN("CTRL: Left Allegro Hand controller initialized.");
  }
  else {
    pBHand = new BHand(eHandType_Right);
    ROS_WARN("CTRL: Right Allegro Hand controller initialized.");
  }
  pBHand->SetTimeInterval(ALLEGRO_CONTROL_TIME_INTERVAL);
  pBHand->SetMotionType(eMotionType_NONE);
  setJointGains();

  // sets initial desired pos at start pos for PD control
  for (int i = 0; i < DOF_JOINTS; i++)
    desired_position[i] = current_position[i];

  pBHand->SetJointDesiredPosition(desired_position);
  pBHand->SetMotionType(eMotionType_JOINT_PD);
  setJointGains();
}

void AllegroNodeCustomPD::doIt(bool polling) {
  if (polling) {
    ROS_INFO("Polling = true.");
    ros::Rate r(333);
    while (ros::ok()) {
      updateController();
      ros::spinOnce();
      r.sleep();
    }
  } else {
    ROS_INFO("Polling = false.");

    // Timer callback (not recommended).
    ros::Timer timer = startTimerCallback();
    ros::spin();
  }
}

int main(int argc, char **argv) {
  ros::init(argc, argv, "allegro_hand_core_grasp");
  AllegroNodeCustomPD grasping;

  bool polling = false;
  if (argv[1] == std::string("true")) {
    polling = true;
  }
  ROS_INFO("Start controller with polling = %d", polling);

  grasping.doIt(polling);
}
