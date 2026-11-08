aws organizations list-policies-for-target \
  --target-id ou-w9g6-s660arda \
  --filter SERVICE_CONTROL_POLICY



  aws organizations describe-policy --policy-id p-agd0sn11



  aws organizations describe-policy --policy-id p-FullAWSAccess



aws sts decode-authorization-message --encoded-message "Hb63q2hH6KQ7VTtMMm6-dztm4LiEH3eCZ92Z59Up7RNbcSemX3mVJkKEb3ctY3aUDP0p58FYMCehU_MClcnOnaSUIT9VWStWdaaHB4Lt1B-x3xDq7QWeHGPm9KnUTjkuNbIlHC0jfg7jlcTiHvTB-IoiUUy-CxDovrVM3AgCjHnpF_ZHlcquu_5Fz4Jp3ltz7N7yxpLM-6IVMgLF394nP2wrl67I7G-Au-mMgodo4ms1QUczcfsPTArqVf_nJv9nB9yygWYUuOUdH_NVvOYONe37QasMKr3F3xQyLNokEI8iuEjwTM_GlZUSz3F33W26LT677ip7smUK1eNhyTUoffXxm2Grzh_OHU4P7OVAZQ7JKB7o1Z1ibHQtuSpIF0lQJ4fTrCf1DwF"




Line 26
{
			"Sid": "DenyNonT2MicroInstances",
			"Effect": "Deny",
			"Action": "ec2:RunInstances",
			"Resource": "*",
			"Condition": {
				"StringNotEqualsIfExists": {
					"ec2:InstanceType": "t2.micro"
				}
			}
		},




psql -h cloudwithben-postgres.c74i68iououn.eu-west-1.rds.amazonaws.com -U appuser -d mvp

ALTER TABLE startup_image ALTER id ADD GENERATED ALWAYS AS IDENTITY (START WITH 2);
ALTER TABLE startup_image ADD CONSTRAINT startup_image_user_id FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE startup_image ADD CONSTRAINT startup_image_user_id FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE startup_image ADD CONSTRAINT startup_image_user_id FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED;
