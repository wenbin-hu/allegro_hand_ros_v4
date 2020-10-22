import rospy
from sensor_msgs.msg import JointState
import numpy as np


class AllegroController:
    def __init__(self):
        # define the publisher and subscriber
        self.joint_cmd_pub = rospy.Publisher("allegroHand/joint_cmd", JointState, queue_size=10)
        self.joint_state_sub = rospy.Subscriber("allegroHand/joint_states", JointState, self.sub_joint_info())
        rospy.init_node('py_pub_jnt_cmd')
        rospy.init_node('py_sub_jnt_state')

        # define the home pose
        self.home_pose = np.int64([0.0, -10.0, 45.0, 45.0,
                                        0.0, -10.0, 45.0, 45.0,
                                        5.0, -5.0, 50.0, 45.0,
                                        60.0, 25.0, 15.0, 45.0])

        # todo: define the joint limits
        self.joint_limit = np.array([])

    def sub_joint_info(self):
        pass

    def pub_joint_cmd(self):
        desired_joint_state = JointState()
        # target joint positions
        desired_joint_state.position = self.home_pose
        # target joint velocities and torques remain 0
        desired_joint_state.velocity = np.int64([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        desired_joint_state.effort = np.int64([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        rate = rospy.Rate(50)  # 50hz
        while not rospy.is_shutdown():
            # rospy.loginfo(desired_joint_state)
            self.joint_cmd_pub.publish(desired_joint_state)
            rate.sleep()


def main():
    hand_controller = AllegroController()
    hand_controller.pub_joint_cmd()


if __name__ == '__main__':
    main()
