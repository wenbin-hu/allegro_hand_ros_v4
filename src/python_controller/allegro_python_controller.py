import rospy
from sensor_msgs.msg import JointState
import numpy as np
import scipy.io as sio


class AllegroController:
    def __init__(self):
        # define the publisher and subscriber
        self.joint_cmd_pub = rospy.Publisher("allegroHand_0/joint_cmd", JointState, queue_size=10)
        self.joint_state_sub = rospy.Subscriber("allegroHand_0/joint_states", JointState, self.sub_joint_info)
        rospy.init_node('python_allegro_controller')

        # initiate the robot data
        self.current_joint_state = JointState()
        self.log_desired_joint_position = 0
        self.log_real_joint_position = 0

        # define the poses in radian.
        self.home_pose = np.array([0.0, -10.0, 45.0, 45.0,
                                   0.0, -10.0, 45.0, 45.0,
                                   5.0, -5.0, 50.0, 45.0,
                                   60.0, 25.0, 15.0, 45.0]) * np.pi / 180

        self.grasp_pose = np.array([-0.116546, 1.088680, 1.235494, 1.020421,
                                    0.126044, 0.967163, 1.377515, 0.786175,
                                    0.340407, 1.195107, 1.154542, 0.982874,
                                    1.403346, 0.459971, 0.020060, 1.784139])

        self.zero_pose = np.array([0.0, 0.0, 0.0, 0.0,
                                   0.0, 0.0, 0.0, 0.0,
                                   0.0, 0.0, 0.0, 0.0,
                                   0.3, 0.0, 0.0, 0.0])

        self.rock_pose = np.array([-0.1194, 1.2068, 1.0, 1.4042,
                                   -0.0093, 1.2481, 1.4073, 0.8163,
                                   0.1116, 1.2712, 1.3881, 1.0122,
                                   0.6017, 0.2976, 0.9034, 0.7929])

        self.paper_pose = np.array([-0.1220, 0.4, 0.6, -0.0769,
                                    0.0312, 0.4, 0.6, -0.0,
                                    0.1767, 0.4, 0.6, -0.0528,
                                    0.5284, 0.3693, 0.8977, 0.4863])

        self.scissor_pose = np.array([0.0885, 0.4, 0.6, -0.0704,
                                      0.0312, 0.4, 0.6, -0.0,
                                      0.1019, 1.2375, 1.1346,
                                      1.0244, 1.0, 0.6331, 1.3509, 1.0])

        self.test_pose = np.array([0.0, 0.0, 0.0, 0.0,
                                   0.0, 0.0, 0.0, 0.0,
                                   0.0, 0.0, 0.0, 0.0,
                                   0.0, 0.0, 0.0, 10.0]) * np.pi / 180

        # define the joint limits
        self.joint_lower_limit = np.array([-0.47, -0.196, -0.174, -0.227,
                                           -0.47, -0.196, -0.174, -0.227,
                                           -0.47, -0.196, -0.174, -0.227,
                                           0.263, -0.105, -0.189, -0.162])
        self.joint_upper_limit = np.array([0.47, 1.61, 1.709, 1.618,
                                           0.47, 1.61, 1.709, 1.618,
                                           0.47, 1.61, 1.709, 1.618,
                                           1.396, 1.163, 1.644, 1.719])

    def sub_joint_info(self, msg):
        self.current_joint_state = msg

    def pub_joint_cmd(self, desired_joint_state):
        # clip the desired joint positions with the joint limits
        for i in range(desired_joint_state.position.shape[0]):
            if desired_joint_state.position[i] > self.joint_upper_limit[i]:
                desired_joint_state.position[i] = self.joint_upper_limit[i]
            elif desired_joint_state.position[i] < self.joint_lower_limit[i]:
                desired_joint_state.position[i] = self.joint_lower_limit[i]
            else:
                pass
        self.joint_cmd_pub.publish(desired_joint_state)

    def step_response_test(self):
        freq = 50
        rate = rospy.Rate(freq)
        desired_joint_state = JointState()
        self.log_desired_joint_position = np.zeros([16, 3 * freq])
        self.log_real_joint_position = np.zeros([16, 3 * freq])
        # wait for the first subscribe
        rospy.Rate(10).sleep()
        # test every finger joint
        for i in range(16):
            for j in range(freq * 2):
                desired_joint_state.position = self.zero_pose.copy()
                self.log_desired_joint_position[i][j] = desired_joint_state.position[i]
                self.log_real_joint_position[i][j] = self.current_joint_state.position[i]
                self.pub_joint_cmd(desired_joint_state)
                rate.sleep()
            for k in range(freq * 2):
                desired_joint_state.position[i] = self.zero_pose[i] + 5 * np.pi / 180
                self.log_desired_joint_position[i][freq*1+k] = desired_joint_state.position[i]
                self.log_real_joint_position[i][freq*1+k] = self.current_joint_state.position[i]
                self.pub_joint_cmd(desired_joint_state)
                rate.sleep()


def main():
    hand_controller = AllegroController()
    desired_joint_state = JointState()
    # target joint positions
    # don't have to set target joint velocities and torques
    desired_joint_state.position = hand_controller.grasp_pose
    rate = rospy.Rate(50)  # 50hz
    while not rospy.is_shutdown():
        hand_controller.pub_joint_cmd(desired_joint_state)
        rate.sleep()

    # step response test
    # hand_controller.step_response_test()
    # sio.savemat('step_response.mat', {'desired_joint_position': hand_controller.log_desired_joint_position,
    #                                   'real_joint_position': hand_controller.log_real_joint_position})


if __name__ == '__main__':
    main()
