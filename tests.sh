psql -h cloudwithben-postgres.c74i68iououn.eu-west-1.rds.amazonaws.com -U appuser -d mvp



CREATE SEQUENCE  django_migrations_id_seq as integer start 
CREATE SEQUENCE django_migrations_id_seq as integer start with XYZ;


ALTER TABLE django_migrations ALTER id SET DEFAULT nextval('django_migrations_id_seq'::regclass);
ALTER TABLE django_migrations ALTER id SET DEFAULT nextval('django_migrations_id_seq'::regclass);


ALTER SEQUENCE django_migrations_id_seq OWNED BY django_migrations.id;
ALTER SEQUENCE django_migrations_id_seq OWNED BY django_migrations.id;



aws ssm start-session --target i-031181f7e3c24c748 --region eu-west-1


aws s3 sync /opt/app/cloudtalents/static


s3://cloudwithben-media-dev/media/
s3://cloudwithben-media-dev/media/


aws s3 sync /opt/app/cloudtalents/static s3://cloudwithben-media-dev/media/
