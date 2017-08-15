CREATE ROLE vault;
ALTER ROLE vault WITH SUPERUSER LOGIN PASSWORD 'vault';

REVOKE ALL ON schema public FROM public;
GRANT ALL ON schema public TO vault;
GRANT USAGE ON SCHEMA public TO public;

CREATE TABLE public.test(id INT);
INSERT INTO public.test(id) VALUES (0);
