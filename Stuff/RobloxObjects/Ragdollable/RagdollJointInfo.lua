export type attachmentProperties = {
	Orientation: Vector3?;
	Position: Vector3;
}

export type constraintProperties = {
	LimitsEnabled: boolean;
	TwistLimitsEnabled: boolean?;
	UpperAngle: number?;
	TwistLowerAngle: number?;
	TwistUpperAngle: number?;
	LowerAngle: number?;
}

export type r6LimbStruct = {
	attachment0: attachmentProperties;
	attachment1: attachmentProperties;
}

export type r15LimbStruct = {
	limb1: string;
	limb2: string;
	attachment1: string?;
	properties: constraintProperties?;
	class: 'BallSocketConstraint' | 'HingeConstraint'
}

local v3 = Vector3.new
local info: {
	r6: {[string]: r6LimbStruct};
	r15: {[string]: r15LimbStruct}
} = {
	r6 = {
		['Left Arm'] = {
			attachment0 = {Orientation=v3(0,180);Position=v3(-1,1)};
			attachment1 = {Orientation=v3(0,180);Position=v3(.5,1)};
			ballSocketJoint = {
				LimitsEnabled=true;
				TwistLimitsEnabled=true;
				UpperAngle=-45;
				TwistLowerAngle=-45;
			};
		};

		['Right Arm']={
			attachment0 = {Position=v3(1,1);};
			attachment1 = {Position=v3(-.5,1);};
			ballSocketJoint = {
				LimitsEnabled=true;
				TwistLimitsEnabled=true;
				UpperAngle=-45;
				TwistLowerAngle=-45;
			};
		};

		['Right Leg']={
			attachment0 = {Orientation=v3(90,0,-90);Position=v3(.5,-1);};
			attachment1 = {Orientation=v3(90,0,-90);Position=v3(0,1);};
			ballSocketJoint = {LimitsEnabled=true;UpperAngle=165;};
		};

		['Left Leg'] = {
			attachment0 = {Orientation=v3(90,0,-90);Position=v3(-.5,-1);};
			attachment1 = {Orientation=v3(90,0,-90);Position=v3(0,1);};
			ballSocketJoint = {LimitsEnabled=true;UpperAngle=165;};
		};

		['Head'] = {
			attachment0 = {Orientation=v3(180,90);Position=v3(0,1);};
			attachment1 = {Orientation=v3(180,90);Position=v3(0,-.5);};
			ballSocketJoint = {
				LimitsEnabled=true;
				TwistLimitsEnabled=true;
				UpperAngle=-45;
				TwistLowerAngle=-45
			};
		};
	};
	
	r15 = {
		-- left leg
		LeftAnkleRigAttachment = {
			limb1 = 'LeftFoot',
			limb2 = 'LeftLowerLeg';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 40;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -30;
				TwistUpperAngle = 30
			}
		};

		LeftKneeRigAttachment = {
			limb1 = 'LeftLowerLeg';
			limb2 = 'LeftUpperLeg';
			class = 'HingeConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 135;
				LowerAngle = 0;
			}
		};

		LeftHipRigAttachment = {
			limb1 = 'LeftUpperLeg';
			limb2 = 'LowerTorso';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 70;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -95;
				TwistUpperAngle = 25;
			}
		};
		
		-- right leg
		RightAnkleRigAttachment = {
			limb1 = 'RightFoot';
			limb2 = 'RightLowerLeg';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 40;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -30;
				TwistUpperAngle = 30
			}
		};

		RightKneeRigAttachment = {
			limb1 = 'RightLowerLeg';
			limb2 = 'RightUpperLeg';
			class = 'HingeConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 135;
				LowerAngle = 0;
			}
		};

		RightHipRigAttachment = {
			limb1 = 'RightUpperLeg';
			limb2 = 'LowerTorso';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 70;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -25;
				TwistUpperAngle = 95;
			}
		};
		
		-- left arm
		LeftWristRigAttachment = {
			limb1 = 'LeftHand';
			limb2 = 'LeftLowerArm';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 45;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -95;
				TwistUpperAngle = 95
			}
		};

		LeftElbowRigAttachment = {
			limb1 = 'LeftLowerArm';
			limb2 = 'LeftUpperArm';
			class = 'HingeConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 45;
				LowerAngle = -135;
			}
		};

		LeftShoulderRigAttachment = {
			limb1 = 'LeftUpperArm';
			limb2 = 'UpperTorso';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 15;
				TwistLowerAngle = -135;
				TwistLimitsEnabled = true;
				TwistUpperAngle = 135;
			}
		};
		
		-- right arm
		RightWristRigAttachment = {
			limb1 = 'RightHand';
			limb2 = 'RightLowerArm';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 45;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -95;
				TwistUpperAngle = 95
			}
		};

		RightElbowRigAttachment = {
			limb1 = 'RightLowerArm';
			limb2 = 'RightUpperArm';
			class = 'HingeConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 45;
				LowerAngle = -135;
			}
		};

		RightShoulderRigAttachment = {
			limb1 = 'RightUpperArm';
			limb2 = 'UpperTorso';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 15;
				TwistLowerAngle = -135;
				TwistLimitsEnabled = true;
				TwistUpperAngle = 135;
			}
		};
		
		-- waist
		WaistRigAttachment = {
			limb1 = 'UpperTorso';
			limb2 = 'LowerTorso';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 0;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -0;
				TwistUpperAngle = 0;
			}
		};
		
		-- neck
		NeckRigAttachment = {
			limb1 = 'UpperTorso';
			limb2 = 'Head';
			class = 'BallSocketConstraint';
			properties = {
				LimitsEnabled = true;
				UpperAngle = 40;
				TwistLimitsEnabled = true;
				TwistLowerAngle = -45;
				TwistUpperAngle = 45;
			};
		};
	};
}

return info
