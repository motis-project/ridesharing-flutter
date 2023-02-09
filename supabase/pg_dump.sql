--
-- PostgreSQL database dump
--

-- Dumped from database version 15.1
-- Dumped by pg_dump version 15.1 (Debian 15.1-1.pgdg110+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_cron; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "extensions";


--
-- Name: pgsodium; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA "public" OWNER TO "postgres";

--
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";


--
-- Name: pgjwt; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";


--
-- Name: approve_ride(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."approve_ride"("ride_id" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  if is_ride_update_allowed(ride_id)
  then 
  update rides
  /* status = 2 is the approved status for a ride */
  set status = 2
  where id = ride_id;
  end if;
end;
$$;


ALTER FUNCTION "public"."approve_ride"("ride_id" integer) OWNER TO "postgres";

--
-- Name: create_chat(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."create_chat"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  insert into chats
  default values
  returning id into new.chat_id;

  return new;
end;$$;


ALTER FUNCTION "public"."create_chat"() OWNER TO "postgres";

--
-- Name: create_ride_event(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."create_ride_event"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  
  if old is null or new.status != old.status then
    insert into ride_events(ride_id,category)
    values(
      new.id,
      /* the corresponding status of a event is the ride status -1 since there is now event for preview and the ride status therrefore begins with one in Supabase*/
      new.status -1
    );
  end if;
  return new;
end;$$;


ALTER FUNCTION "public"."create_ride_event"() OWNER TO "postgres";

--
-- Name: delete_claim("uuid", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."delete_claim"("uid" "uuid", "claim" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    BEGIN
      IF NOT is_claims_admin() THEN
          RETURN 'error: access denied';
      ELSE        
        update auth.users set raw_app_meta_data = 
          raw_app_meta_data - claim where id = uid;
        return 'OK';
      END IF;
    END;
$$;


ALTER FUNCTION "public"."delete_claim"("uid" "uuid", "claim" "text") OWNER TO "postgres";

--
-- Name: get_claim("uuid", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."get_claim"("uid" "uuid", "claim" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    DECLARE retval jsonb;
    BEGIN
      IF NOT is_claims_admin() THEN
          RETURN '{"error":"access denied"}'::jsonb;
      ELSE
        select coalesce(raw_app_meta_data->claim, null) from auth.users into retval where id = uid::uuid;
        return retval;
      END IF;
    END;
$$;


ALTER FUNCTION "public"."get_claim"("uid" "uuid", "claim" "text") OWNER TO "postgres";

--
-- Name: get_claims("uuid"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."get_claims"("uid" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    DECLARE retval jsonb;
    BEGIN
      IF NOT is_claims_admin() THEN
          RETURN '{"error":"access denied"}'::jsonb;
      ELSE
        select raw_app_meta_data from auth.users into retval where id = uid::uuid;
        return retval;
      END IF;
    END;
$$;


ALTER FUNCTION "public"."get_claims"("uid" "uuid") OWNER TO "postgres";

--
-- Name: get_my_claim("text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."get_my_claim"("claim" "text") RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$
  select 
  	coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb -> 'app_metadata' -> claim, null)
$$;


ALTER FUNCTION "public"."get_my_claim"("claim" "text") OWNER TO "postgres";

--
-- Name: get_my_claims(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."get_my_claims"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$
  select 
  	coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb -> 'app_metadata', '{}'::jsonb)::jsonb
$$;


ALTER FUNCTION "public"."get_my_claims"() OWNER TO "postgres";

--
-- Name: is_claims_admin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."is_claims_admin"() RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
  BEGIN
    IF session_user = 'authenticator' THEN
     return false;
    ELSE -- not a user session, probably being called from a trigger or something
      return true;
    END IF;
  END;
$$;


ALTER FUNCTION "public"."is_claims_admin"() OWNER TO "postgres";

--
-- Name: is_ride_update_allowed(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."is_ride_update_allowed"("ride_id" integer) RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$/* Users are allowed to update the status of rides where they are the driver */
begin
  return (select profiles.id from profiles where profiles.auth_id = auth.uid()) = 
  (select drives.driver_id from drives where id = (select rides.drive_id from rides where id = ride_id));
end;
$$;


ALTER FUNCTION "public"."is_ride_update_allowed"("ride_id" integer) OWNER TO "postgres";

--
-- Name: mark_message_as_read(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."mark_message_as_read"("message_id" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update messages
  set read = true
  where id = message_id;
end;$$;


ALTER FUNCTION "public"."mark_message_as_read"("message_id" integer) OWNER TO "postgres";

--
-- Name: mark_ride_event_as_read(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."mark_ride_event_as_read"("ride_event_id" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  update ride_events
  set read = true
  where id = ride_event_id;
end;$$;


ALTER FUNCTION "public"."mark_ride_event_as_read"("ride_event_id" integer) OWNER TO "postgres";

--
-- Name: reject_ride(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."reject_ride"("ride_id" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  if is_ride_update_allowed(ride_id)
  then 
  update rides
  /* status = 3 ist the rejected status for a ride in the app */
  set status = 3
  where id = ride_id;
  end if;
end;
$$;


ALTER FUNCTION "public"."reject_ride"("ride_id" integer) OWNER TO "postgres";

--
-- Name: ride_event_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."ride_event_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin

  update public.ride_events 
  set read = true
  where ride_id = new.ride_id;
      
  return new;
end;$$;


ALTER FUNCTION "public"."ride_event_insert"() OWNER TO "postgres";

--
-- Name: set_admin_role(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."set_admin_role"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$/* users are admins if they get invited into supabase */
begin
    if new.invited_at notnull then 
     update auth.users
    set raw_app_meta_data = raw_app_meta_data || jsonb_build_object('admin', 'true')
    where id = new.id;
    else 
      update auth.users
    set raw_app_meta_data = raw_app_meta_data || jsonb_build_object('admin', 'false')
    where id = new.id;
    end if;
    return new;
end;$$;


ALTER FUNCTION "public"."set_admin_role"() OWNER TO "postgres";

--
-- Name: set_claim("uuid", "text", "jsonb"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."set_claim"("uid" "uuid", "claim" "text", "value" "jsonb") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    BEGIN
      IF NOT is_claims_admin() THEN
          RETURN 'error: access denied';
      ELSE        
        update auth.users set raw_app_meta_data = 
          raw_app_meta_data || 
            json_build_object(claim, value)::jsonb where id = uid;
        return 'OK';
      END IF;
    END;
$$;


ALTER FUNCTION "public"."set_claim"("uid" "uuid", "claim" "text", "value" "jsonb") OWNER TO "postgres";

--
-- Name: update_ride_status(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."update_ride_status"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
    if new.cancelled = True and old.cancelled = False then 
      update public.rides 
      /* status = 4 is the cancelledByDriver status for rides in the app */
      set status = 4
      where rides.drive_id = new.id 
      /* the update  is only for rides with status = 2 (approved rides)*/
        and (rides.status = 2);
      update public.rides 
      /* status = 3 is the rejected status for drives in the app */
      set status = 3
      where rides.drive_id = new.id 
      /* the status is only pdated when status = 1 (pending ride) */
        and (rides.status = 1);
    end if;
    return new;
end;$$;


ALTER FUNCTION "public"."update_ride_status"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

--
-- Name: chats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."chats" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."chats" OWNER TO "postgres";

--
-- Name: chats_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."chats" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."chats_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: drives; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."drives" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "driver_id" bigint NOT NULL,
    "start" character varying NOT NULL,
    "start_time" timestamp with time zone NOT NULL,
    "end" character varying NOT NULL,
    "end_time" timestamp with time zone NOT NULL,
    "seats" smallint NOT NULL,
    "cancelled" boolean DEFAULT false NOT NULL,
    "hide_in_list_view" boolean DEFAULT false NOT NULL,
    "start_lat" real NOT NULL,
    "start_lng" real NOT NULL,
    "end_lat" real NOT NULL,
    "end_lng" real NOT NULL,
    "recurring_drive_id" bigint,
    CONSTRAINT "seats_validator" CHECK (("seats" >= 1))
);


ALTER TABLE "public"."drives" OWNER TO "postgres";

--
-- Name: drives_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."drives" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."drives_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."messages" (
    "id" bigint NOT NULL,
    "sender_id" bigint NOT NULL,
    "content" character varying,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "read" boolean DEFAULT false NOT NULL,
    "chat_id" bigint NOT NULL
);


ALTER TABLE "public"."messages" OWNER TO "postgres";

--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."messages" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."messages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: profile_features; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."profile_features" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "profile_id" bigint NOT NULL,
    "feature" smallint,
    "rank" smallint,
    CONSTRAINT "feature_validator" CHECK ((("feature" >= 0) AND ("feature" <= 14))),
    CONSTRAINT "rank_validator" CHECK (("rank" >= 0))
);


ALTER TABLE "public"."profile_features" OWNER TO "postgres";

--
-- Name: profile_features_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."profile_features" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."profile_features_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."profiles" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "username" "text",
    "email" character varying,
    "auth_id" "uuid" NOT NULL,
    "description" "text",
    "birth_date" timestamp with time zone,
    "surname" "text",
    "name" "text",
    "gender" smallint,
    "avatar_url" "text",
    CONSTRAINT "gender_validator" CHECK ((("gender" IS NULL) OR (("gender" >= 0) AND ("gender" <= 2))))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";

--
-- Name: recurring_drives; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."recurring_drives" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "driver_id" bigint NOT NULL,
    "start" character varying NOT NULL,
    "start_time" timestamp with time zone NOT NULL,
    "end" character varying NOT NULL,
    "end_time" timestamp with time zone NOT NULL,
    "seats" smallint NOT NULL,
    "start_lat" real NOT NULL,
    "start_lng" real NOT NULL,
    "end_lat" real NOT NULL,
    "end_lng" real NOT NULL,
    "weekdays" boolean[] NOT NULL,
    "stopped" boolean DEFAULT false NOT NULL,
    CONSTRAINT "seats_validator" CHECK (("seats" >= 1))
);


ALTER TABLE "public"."recurring_drives" OWNER TO "postgres";

--
-- Name: recurring_drives_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."recurring_drives" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."recurring_drives_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."reports" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "offender_id" bigint NOT NULL,
    "reporter_id" bigint NOT NULL,
    "category" smallint NOT NULL,
    "text" "text",
    CONSTRAINT "category_validator" CHECK ((("category" >= 0) AND ("category" <= 5)))
);


ALTER TABLE "public"."reports" OWNER TO "postgres";

--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."reports" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."reports_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."reviews" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "rating" smallint NOT NULL,
    "text" "text" DEFAULT ''::"text",
    "writer_id" bigint NOT NULL,
    "receiver_id" bigint NOT NULL,
    "comfort_rating" smallint,
    "safety_rating" smallint,
    "reliability_rating" smallint,
    "hospitality_rating" smallint
);


ALTER TABLE "public"."reviews" OWNER TO "postgres";

--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."reviews" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."reviews_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: ride_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."ride_events" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "ride_id" bigint NOT NULL,
    "category" smallint NOT NULL,
    "read" boolean DEFAULT false NOT NULL,
    CONSTRAINT "category_validator" CHECK ((("category" >= 0) AND ("category" <= 5)))
);


ALTER TABLE "public"."ride_events" OWNER TO "postgres";

--
-- Name: rider_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."ride_events" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."rider_events_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: rides; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."rides" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "rider_id" bigint NOT NULL,
    "drive_id" bigint NOT NULL,
    "seats" smallint DEFAULT '1'::smallint NOT NULL,
    "start" character varying NOT NULL,
    "start_time" timestamp with time zone NOT NULL,
    "end" character varying NOT NULL,
    "end_time" timestamp with time zone NOT NULL,
    "price" double precision NOT NULL,
    "status" smallint NOT NULL,
    "hide_in_list_view" boolean DEFAULT false NOT NULL,
    "start_lat" real NOT NULL,
    "end_lat" real NOT NULL,
    "end_lng" real NOT NULL,
    "start_lng" real NOT NULL,
    "chat_id" bigint,
    CONSTRAINT "price_validator" CHECK (("price" >= (0)::double precision)),
    CONSTRAINT "seats_validator" CHECK (("seats" >= 1)),
    CONSTRAINT "status_validator" CHECK ((("status" >= 1) AND ("status" <= 6)))
);


ALTER TABLE "public"."rides" OWNER TO "postgres";

--
-- Name: rides_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."rides" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."rides_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."profiles" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."users_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: chats chats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."chats"
    ADD CONSTRAINT "chats_pkey" PRIMARY KEY ("id");


--
-- Name: drives drives_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."drives"
    ADD CONSTRAINT "drives_pkey" PRIMARY KEY ("id");


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");


--
-- Name: profile_features profile_features_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."profile_features"
    ADD CONSTRAINT "profile_features_pkey" PRIMARY KEY ("id");


--
-- Name: recurring_drives recurring_drives_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."recurring_drives"
    ADD CONSTRAINT "recurring_drives_pkey" PRIMARY KEY ("id");


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_pkey" PRIMARY KEY ("id");


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_pkey" PRIMARY KEY ("id");


--
-- Name: ride_events rider_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."ride_events"
    ADD CONSTRAINT "rider_events_pkey" PRIMARY KEY ("id");


--
-- Name: rides rides_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."rides"
    ADD CONSTRAINT "rides_pkey" PRIMARY KEY ("id");


--
-- Name: profiles users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "users_email_key" UNIQUE ("email");


--
-- Name: profiles users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");


--
-- Name: rides create_chat_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "create_chat_trigger" BEFORE INSERT ON "public"."rides" FOR EACH ROW EXECUTE FUNCTION "public"."create_chat"();


--
-- Name: rides create_ride_event_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "create_ride_event_trigger" AFTER INSERT OR UPDATE ON "public"."rides" FOR EACH ROW EXECUTE FUNCTION "public"."create_ride_event"();


--
-- Name: ride_events ride_event_insert_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "ride_event_insert_trigger" BEFORE INSERT ON "public"."ride_events" FOR EACH ROW EXECUTE FUNCTION "public"."ride_event_insert"();


--
-- Name: drives update_ride_status_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "update_ride_status_trigger" AFTER UPDATE ON "public"."drives" FOR EACH ROW EXECUTE FUNCTION "public"."update_ride_status"();


--
-- Name: drives drives_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."drives"
    ADD CONSTRAINT "drives_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."profiles"("id");


--
-- Name: drives drives_recurring_drive_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."drives"
    ADD CONSTRAINT "drives_recurring_drive_id_fkey" FOREIGN KEY ("recurring_drive_id") REFERENCES "public"."recurring_drives"("id");


--
-- Name: messages messages_chat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_chat_id_fkey" FOREIGN KEY ("chat_id") REFERENCES "public"."chats"("id");


--
-- Name: messages messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id");


--
-- Name: profile_features profile_features_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."profile_features"
    ADD CONSTRAINT "profile_features_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id");


--
-- Name: profiles profiles_auth_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_auth_id_fkey" FOREIGN KEY ("auth_id") REFERENCES "auth"."users"("id");


--
-- Name: recurring_drives recurring_drives_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."recurring_drives"
    ADD CONSTRAINT "recurring_drives_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."profiles"("id");


--
-- Name: reports reports_offender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_offender_id_fkey" FOREIGN KEY ("offender_id") REFERENCES "public"."profiles"("id");


--
-- Name: reports reports_reporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "public"."profiles"("id");


--
-- Name: reviews reviews_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_receiver_id_fkey" FOREIGN KEY ("receiver_id") REFERENCES "public"."profiles"("id");


--
-- Name: reviews reviews_writer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_writer_id_fkey" FOREIGN KEY ("writer_id") REFERENCES "public"."profiles"("id");


--
-- Name: ride_events ride_events_ride_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."ride_events"
    ADD CONSTRAINT "ride_events_ride_id_fkey" FOREIGN KEY ("ride_id") REFERENCES "public"."rides"("id");


--
-- Name: rides rides_chat_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."rides"
    ADD CONSTRAINT "rides_chat_id_fkey" FOREIGN KEY ("chat_id") REFERENCES "public"."chats"("id");


--
-- Name: rides rides_original_drive_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."rides"
    ADD CONSTRAINT "rides_original_drive_id_fkey" FOREIGN KEY ("drive_id") REFERENCES "public"."drives"("id");


--
-- Name: rides rides_original_rider_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."rides"
    ADD CONSTRAINT "rides_original_rider_id_fkey" FOREIGN KEY ("rider_id") REFERENCES "public"."profiles"("id");


--
-- Name: job cron_job_policy; Type: POLICY; Schema: cron; Owner: supabase_admin
--

-- CREATE POLICY "cron_job_policy" ON "cron"."job" USING (("username" = CURRENT_USER));


--
-- Name: job_run_details cron_job_run_details_policy; Type: POLICY; Schema: cron; Owner: supabase_admin
--

-- CREATE POLICY "cron_job_run_details_policy" ON "cron"."job_run_details" USING (("username" = CURRENT_USER));


--
-- Name: job; Type: ROW SECURITY; Schema: cron; Owner: supabase_admin
--

-- ALTER TABLE "cron"."job" ENABLE ROW LEVEL SECURITY;

--
-- Name: job_run_details; Type: ROW SECURITY; Schema: cron; Owner: supabase_admin
--

-- ALTER TABLE "cron"."job_run_details" ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles Enable authenticated users to create a profile with their id; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable authenticated users to create a profile with their id" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "auth_id"));


--
-- Name: drives Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON "public"."drives" FOR SELECT USING (true);


--
-- Name: profile_features Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON "public"."profile_features" FOR SELECT USING (true);


--
-- Name: profiles Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON "public"."profiles" FOR SELECT USING (true);


--
-- Name: reviews Enable read access for all users; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Enable read access for all users" ON "public"."reviews" FOR SELECT USING (true);


--
-- Name: rides Users can create rides only for themselves; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can create rides only for themselves" ON "public"."rides" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "rides"."rider_id"))));


--
-- Name: messages Users can insert Messages for themselves in their own chats; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert Messages for themselves in their own chats" ON "public"."messages" FOR INSERT TO "authenticated" WITH CHECK ((("sender_id" IN ( SELECT "profiles"."id"
   FROM "public"."profiles"
  WHERE ("profiles"."auth_id" = "auth"."uid"()))) AND (EXISTS ( SELECT 1
   FROM "public"."chats"
  WHERE ("chats"."id" = "messages"."chat_id")))));


--
-- Name: drives Users can only create drives for themselves; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can only create drives for themselves" ON "public"."drives" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "drives"."driver_id"))));


--
-- Name: profile_features Users can only create features for themselves; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can only create features for themselves" ON "public"."profile_features" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "profile_features"."profile_id"))));


--
-- Name: reviews Users can only create reviews that they wrote; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can only create reviews that they wrote" ON "public"."reviews" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reviews"."writer_id"))));


--
-- Name: profile_features Users can only delete their own profile features; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can only delete their own profile features" ON "public"."profile_features" FOR DELETE TO "authenticated" USING (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "profile_features"."profile_id"))));


--
-- Name: reports Users can only insert their own reports; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can only insert their own reports" ON "public"."reports" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reports"."reporter_id"))));


--
-- Name: reports Users can read their own reports; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can read their own reports" ON "public"."reports" FOR SELECT USING (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reports"."reporter_id"))));


--
-- Name: rides Users can see rides for their own drives; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can see rides for their own drives" ON "public"."rides" FOR SELECT TO "authenticated" USING (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" IN ( SELECT "drives"."driver_id"
           FROM "public"."drives"
          WHERE ("drives"."id" = "rides"."drive_id"))))));


--
-- Name: rides Users can see their own rides; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can see their own rides" ON "public"."rides" FOR SELECT TO "authenticated" USING (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "rides"."rider_id"))));


--
-- Name: reviews Users can update reviews that they wrote; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update reviews that they wrote" ON "public"."reviews" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "reviews"."writer_id")))) WITH CHECK (true);


--
-- Name: drives Users can update their own drives; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own drives" ON "public"."drives" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "drives"."driver_id")))) WITH CHECK (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "drives"."driver_id"))));


--
-- Name: profiles Users can update their own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own profile" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "auth_id")) WITH CHECK (("auth"."uid"() = "auth_id"));


--
-- Name: profile_features Users can update their own profile_features; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own profile_features" ON "public"."profile_features" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "profile_features"."profile_id")))) WITH CHECK (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "profile_features"."profile_id"))));


--
-- Name: rides Users can update their own rides; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can update their own rides" ON "public"."rides" FOR UPDATE TO "authenticated" USING (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "rides"."rider_id")))) WITH CHECK (("auth"."uid"() IN ( SELECT "profiles"."auth_id"
   FROM "public"."profiles"
  WHERE ("profiles"."id" = "rides"."rider_id"))));


--
-- Name: chats admins have full control; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins have full control" ON "public"."chats" TO "authenticated" USING (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb")) WITH CHECK (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb"));


--
-- Name: drives admins have full control; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins have full control" ON "public"."drives" TO "authenticated" USING (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb")) WITH CHECK (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb"));


--
-- Name: messages admins have full control; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins have full control" ON "public"."messages" TO "authenticated" USING (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb")) WITH CHECK (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb"));


--
-- Name: profile_features admins have full control; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins have full control" ON "public"."profile_features" TO "authenticated" USING (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb")) WITH CHECK (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb"));


--
-- Name: profiles admins have full control; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins have full control" ON "public"."profiles" TO "authenticated" USING (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb")) WITH CHECK (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb"));


--
-- Name: reports admins have full control; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins have full control" ON "public"."reports" TO "authenticated" USING (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb")) WITH CHECK (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb"));


--
-- Name: reviews admins have full control; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins have full control" ON "public"."reviews" TO "authenticated" USING (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb")) WITH CHECK (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb"));


--
-- Name: ride_events admins have full control; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins have full control" ON "public"."ride_events" TO "authenticated" USING (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb")) WITH CHECK (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb"));


--
-- Name: rides admins have full control; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins have full control" ON "public"."rides" TO "authenticated" USING (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb")) WITH CHECK (("public"."get_claim"("auth"."uid"(), 'admin'::"text") = '{"admin": "true"}'::"jsonb"));


--
-- Name: chats; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."chats" ENABLE ROW LEVEL SECURITY;

--
-- Name: drives; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."drives" ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;

--
-- Name: profile_features; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."profile_features" ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

--
-- Name: recurring_drives; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."recurring_drives" ENABLE ROW LEVEL SECURITY;

--
-- Name: reports; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."reports" ENABLE ROW LEVEL SECURITY;

--
-- Name: reviews; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."reviews" ENABLE ROW LEVEL SECURITY;

--
-- Name: ride_events; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."ride_events" ENABLE ROW LEVEL SECURITY;

--
-- Name: rides; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."rides" ENABLE ROW LEVEL SECURITY;

--
-- Name: chats users can select chats from rides they can see; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "users can select chats from rides they can see" ON "public"."chats" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."rides"
  WHERE ("rides"."chat_id" = "chats"."id"))));


--
-- Name: ride_events users can select events from rides they can see; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "users can select events from rides they can see" ON "public"."ride_events" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."rides"
  WHERE ("rides"."id" = "ride_events"."ride_id"))));


--
-- Name: messages users can select messages from their chats; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "users can select messages from their chats" ON "public"."messages" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."chats"
  WHERE ("chats"."id" = "messages"."chat_id"))));


--
-- Name: SCHEMA "public"; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT ALL ON SCHEMA "public" TO PUBLIC;
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";


--
-- Name: FUNCTION "job_cache_invalidate"(); Type: ACL; Schema: cron; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "cron"."job_cache_invalidate"() TO "postgres" WITH GRANT OPTION;


--
-- Name: FUNCTION "schedule"("schedule" "text", "command" "text"); Type: ACL; Schema: cron; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "cron"."schedule"("schedule" "text", "command" "text") TO "postgres" WITH GRANT OPTION;


--
-- Name: FUNCTION "schedule"("job_name" "text", "schedule" "text", "command" "text"); Type: ACL; Schema: cron; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "cron"."schedule"("job_name" "text", "schedule" "text", "command" "text") TO "postgres" WITH GRANT OPTION;


--
-- Name: FUNCTION "unschedule"("job_id" bigint); Type: ACL; Schema: cron; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "cron"."unschedule"("job_id" bigint) TO "postgres" WITH GRANT OPTION;


--
-- Name: FUNCTION "unschedule"("job_name" "name"); Type: ACL; Schema: cron; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "cron"."unschedule"("job_name" "name") TO "postgres" WITH GRANT OPTION;


--
-- Name: FUNCTION "algorithm_sign"("signables" "text", "secret" "text", "algorithm" "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."algorithm_sign"("signables" "text", "secret" "text", "algorithm" "text") TO "dashboard_user";


--
-- Name: FUNCTION "armor"("bytea"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."armor"("bytea") TO "dashboard_user";


--
-- Name: FUNCTION "armor"("bytea", "text"[], "text"[]); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."armor"("bytea", "text"[], "text"[]) TO "dashboard_user";


--
-- Name: FUNCTION "crypt"("text", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."crypt"("text", "text") TO "dashboard_user";


--
-- Name: FUNCTION "dearmor"("text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."dearmor"("text") TO "dashboard_user";


--
-- Name: FUNCTION "decrypt"("bytea", "bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."decrypt"("bytea", "bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "decrypt_iv"("bytea", "bytea", "bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."decrypt_iv"("bytea", "bytea", "bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "digest"("bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."digest"("bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "digest"("text", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."digest"("text", "text") TO "dashboard_user";


--
-- Name: FUNCTION "encrypt"("bytea", "bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."encrypt"("bytea", "bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "encrypt_iv"("bytea", "bytea", "bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."encrypt_iv"("bytea", "bytea", "bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "gen_random_bytes"(integer); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."gen_random_bytes"(integer) TO "dashboard_user";


--
-- Name: FUNCTION "gen_random_uuid"(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."gen_random_uuid"() TO "dashboard_user";


--
-- Name: FUNCTION "gen_salt"("text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."gen_salt"("text") TO "dashboard_user";


--
-- Name: FUNCTION "gen_salt"("text", integer); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."gen_salt"("text", integer) TO "dashboard_user";


--
-- Name: FUNCTION "hmac"("bytea", "bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."hmac"("bytea", "bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "hmac"("text", "text", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."hmac"("text", "text", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pg_stat_statements"("showtext" boolean, OUT "userid" "oid", OUT "dbid" "oid", OUT "toplevel" boolean, OUT "queryid" bigint, OUT "query" "text", OUT "plans" bigint, OUT "total_plan_time" double precision, OUT "min_plan_time" double precision, OUT "max_plan_time" double precision, OUT "mean_plan_time" double precision, OUT "stddev_plan_time" double precision, OUT "calls" bigint, OUT "total_exec_time" double precision, OUT "min_exec_time" double precision, OUT "max_exec_time" double precision, OUT "mean_exec_time" double precision, OUT "stddev_exec_time" double precision, OUT "rows" bigint, OUT "shared_blks_hit" bigint, OUT "shared_blks_read" bigint, OUT "shared_blks_dirtied" bigint, OUT "shared_blks_written" bigint, OUT "local_blks_hit" bigint, OUT "local_blks_read" bigint, OUT "local_blks_dirtied" bigint, OUT "local_blks_written" bigint, OUT "temp_blks_read" bigint, OUT "temp_blks_written" bigint, OUT "blk_read_time" double precision, OUT "blk_write_time" double precision, OUT "temp_blk_read_time" double precision, OUT "temp_blk_write_time" double precision, OUT "wal_records" bigint, OUT "wal_fpi" bigint, OUT "wal_bytes" numeric, OUT "jit_functions" bigint, OUT "jit_generation_time" double precision, OUT "jit_inlining_count" bigint, OUT "jit_inlining_time" double precision, OUT "jit_optimization_count" bigint, OUT "jit_optimization_time" double precision, OUT "jit_emission_count" bigint, OUT "jit_emission_time" double precision); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pg_stat_statements"("showtext" boolean, OUT "userid" "oid", OUT "dbid" "oid", OUT "toplevel" boolean, OUT "queryid" bigint, OUT "query" "text", OUT "plans" bigint, OUT "total_plan_time" double precision, OUT "min_plan_time" double precision, OUT "max_plan_time" double precision, OUT "mean_plan_time" double precision, OUT "stddev_plan_time" double precision, OUT "calls" bigint, OUT "total_exec_time" double precision, OUT "min_exec_time" double precision, OUT "max_exec_time" double precision, OUT "mean_exec_time" double precision, OUT "stddev_exec_time" double precision, OUT "rows" bigint, OUT "shared_blks_hit" bigint, OUT "shared_blks_read" bigint, OUT "shared_blks_dirtied" bigint, OUT "shared_blks_written" bigint, OUT "local_blks_hit" bigint, OUT "local_blks_read" bigint, OUT "local_blks_dirtied" bigint, OUT "local_blks_written" bigint, OUT "temp_blks_read" bigint, OUT "temp_blks_written" bigint, OUT "blk_read_time" double precision, OUT "blk_write_time" double precision, OUT "temp_blk_read_time" double precision, OUT "temp_blk_write_time" double precision, OUT "wal_records" bigint, OUT "wal_fpi" bigint, OUT "wal_bytes" numeric, OUT "jit_functions" bigint, OUT "jit_generation_time" double precision, OUT "jit_inlining_count" bigint, OUT "jit_inlining_time" double precision, OUT "jit_optimization_count" bigint, OUT "jit_optimization_time" double precision, OUT "jit_emission_count" bigint, OUT "jit_emission_time" double precision) TO "dashboard_user";


--
-- Name: FUNCTION "pg_stat_statements_info"(OUT "dealloc" bigint, OUT "stats_reset" timestamp with time zone); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pg_stat_statements_info"(OUT "dealloc" bigint, OUT "stats_reset" timestamp with time zone) TO "dashboard_user";


--
-- Name: FUNCTION "pg_stat_statements_reset"("userid" "oid", "dbid" "oid", "queryid" bigint); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pg_stat_statements_reset"("userid" "oid", "dbid" "oid", "queryid" bigint) TO "dashboard_user";


--
-- Name: FUNCTION "pgp_armor_headers"("text", OUT "key" "text", OUT "value" "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_armor_headers"("text", OUT "key" "text", OUT "value" "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_key_id"("bytea"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_key_id"("bytea") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_pub_decrypt"("bytea", "bytea"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_pub_decrypt"("bytea", "bytea") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_pub_decrypt"("bytea", "bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_pub_decrypt"("bytea", "bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_pub_decrypt"("bytea", "bytea", "text", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_pub_decrypt"("bytea", "bytea", "text", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_pub_decrypt_bytea"("bytea", "bytea"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_pub_decrypt_bytea"("bytea", "bytea") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_pub_decrypt_bytea"("bytea", "bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_pub_decrypt_bytea"("bytea", "bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_pub_decrypt_bytea"("bytea", "bytea", "text", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_pub_decrypt_bytea"("bytea", "bytea", "text", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_pub_encrypt"("text", "bytea"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_pub_encrypt"("text", "bytea") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_pub_encrypt"("text", "bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_pub_encrypt"("text", "bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_pub_encrypt_bytea"("bytea", "bytea"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_pub_encrypt_bytea"("bytea", "bytea") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_pub_encrypt_bytea"("bytea", "bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_pub_encrypt_bytea"("bytea", "bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_sym_decrypt"("bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_sym_decrypt"("bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_sym_decrypt"("bytea", "text", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_sym_decrypt"("bytea", "text", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_sym_decrypt_bytea"("bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_sym_decrypt_bytea"("bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_sym_decrypt_bytea"("bytea", "text", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_sym_decrypt_bytea"("bytea", "text", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_sym_encrypt"("text", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_sym_encrypt"("text", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_sym_encrypt"("text", "text", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_sym_encrypt"("text", "text", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_sym_encrypt_bytea"("bytea", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_sym_encrypt_bytea"("bytea", "text") TO "dashboard_user";


--
-- Name: FUNCTION "pgp_sym_encrypt_bytea"("bytea", "text", "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."pgp_sym_encrypt_bytea"("bytea", "text", "text") TO "dashboard_user";


--
-- Name: FUNCTION "sign"("payload" "json", "secret" "text", "algorithm" "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."sign"("payload" "json", "secret" "text", "algorithm" "text") TO "dashboard_user";


--
-- Name: FUNCTION "try_cast_double"("inp" "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."try_cast_double"("inp" "text") TO "dashboard_user";


--
-- Name: FUNCTION "url_decode"("data" "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."url_decode"("data" "text") TO "dashboard_user";


--
-- Name: FUNCTION "url_encode"("data" "bytea"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."url_encode"("data" "bytea") TO "dashboard_user";


--
-- Name: FUNCTION "uuid_generate_v1"(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."uuid_generate_v1"() TO "dashboard_user";


--
-- Name: FUNCTION "uuid_generate_v1mc"(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."uuid_generate_v1mc"() TO "dashboard_user";


--
-- Name: FUNCTION "uuid_generate_v3"("namespace" "uuid", "name" "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."uuid_generate_v3"("namespace" "uuid", "name" "text") TO "dashboard_user";


--
-- Name: FUNCTION "uuid_generate_v4"(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."uuid_generate_v4"() TO "dashboard_user";


--
-- Name: FUNCTION "uuid_generate_v5"("namespace" "uuid", "name" "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."uuid_generate_v5"("namespace" "uuid", "name" "text") TO "dashboard_user";


--
-- Name: FUNCTION "uuid_nil"(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."uuid_nil"() TO "dashboard_user";


--
-- Name: FUNCTION "uuid_ns_dns"(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."uuid_ns_dns"() TO "dashboard_user";


--
-- Name: FUNCTION "uuid_ns_oid"(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."uuid_ns_oid"() TO "dashboard_user";


--
-- Name: FUNCTION "uuid_ns_url"(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."uuid_ns_url"() TO "dashboard_user";


--
-- Name: FUNCTION "uuid_ns_x500"(); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."uuid_ns_x500"() TO "dashboard_user";


--
-- Name: FUNCTION "verify"("token" "text", "secret" "text", "algorithm" "text"); Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "extensions"."verify"("token" "text", "secret" "text", "algorithm" "text") TO "dashboard_user";


--
-- Name: FUNCTION "comment_directive"("comment_" "text"); Type: ACL; Schema: graphql; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "graphql"."comment_directive"("comment_" "text") TO "postgres";
-- GRANT ALL ON FUNCTION "graphql"."comment_directive"("comment_" "text") TO "anon";
-- GRANT ALL ON FUNCTION "graphql"."comment_directive"("comment_" "text") TO "authenticated";
-- GRANT ALL ON FUNCTION "graphql"."comment_directive"("comment_" "text") TO "service_role";


--
-- Name: FUNCTION "exception"("message" "text"); Type: ACL; Schema: graphql; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "graphql"."exception"("message" "text") TO "postgres";
-- GRANT ALL ON FUNCTION "graphql"."exception"("message" "text") TO "anon";
-- GRANT ALL ON FUNCTION "graphql"."exception"("message" "text") TO "authenticated";
-- GRANT ALL ON FUNCTION "graphql"."exception"("message" "text") TO "service_role";


--
-- Name: FUNCTION "get_schema_version"(); Type: ACL; Schema: graphql; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "graphql"."get_schema_version"() TO "postgres";
-- GRANT ALL ON FUNCTION "graphql"."get_schema_version"() TO "anon";
-- GRANT ALL ON FUNCTION "graphql"."get_schema_version"() TO "authenticated";
-- GRANT ALL ON FUNCTION "graphql"."get_schema_version"() TO "service_role";


--
-- Name: FUNCTION "increment_schema_version"(); Type: ACL; Schema: graphql; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "graphql"."increment_schema_version"() TO "postgres";
-- GRANT ALL ON FUNCTION "graphql"."increment_schema_version"() TO "anon";
-- GRANT ALL ON FUNCTION "graphql"."increment_schema_version"() TO "authenticated";
-- GRANT ALL ON FUNCTION "graphql"."increment_schema_version"() TO "service_role";


--
-- Name: FUNCTION "graphql"("operationName" "text", "query" "text", "variables" "jsonb", "extensions" "jsonb"); Type: ACL; Schema: graphql_public; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "graphql_public"."graphql"("operationName" "text", "query" "text", "variables" "jsonb", "extensions" "jsonb") TO "postgres";
-- GRANT ALL ON FUNCTION "graphql_public"."graphql"("operationName" "text", "query" "text", "variables" "jsonb", "extensions" "jsonb") TO "anon";
-- GRANT ALL ON FUNCTION "graphql_public"."graphql"("operationName" "text", "query" "text", "variables" "jsonb", "extensions" "jsonb") TO "authenticated";
-- GRANT ALL ON FUNCTION "graphql_public"."graphql"("operationName" "text", "query" "text", "variables" "jsonb", "extensions" "jsonb") TO "service_role";


--
-- Name: TABLE "valid_key"; Type: ACL; Schema: pgsodium; Owner: supabase_admin
--

-- REVOKE SELECT ON TABLE "pgsodium"."valid_key" FROM "pgsodium_keyiduser";
-- GRANT ALL ON TABLE "pgsodium"."valid_key" TO "pgsodium_keyiduser";


--
-- Name: FUNCTION "crypto_aead_det_decrypt"("message" "bytea", "additional" "bytea", "key_uuid" "uuid", "nonce" "bytea"); Type: ACL; Schema: pgsodium; Owner: pgsodium_keymaker
--

-- GRANT ALL ON FUNCTION "pgsodium"."crypto_aead_det_decrypt"("message" "bytea", "additional" "bytea", "key_uuid" "uuid", "nonce" "bytea") TO "service_role";


--
-- Name: FUNCTION "crypto_aead_det_encrypt"("message" "bytea", "additional" "bytea", "key_uuid" "uuid", "nonce" "bytea"); Type: ACL; Schema: pgsodium; Owner: pgsodium_keymaker
--

-- GRANT ALL ON FUNCTION "pgsodium"."crypto_aead_det_encrypt"("message" "bytea", "additional" "bytea", "key_uuid" "uuid", "nonce" "bytea") TO "service_role";


--
-- Name: FUNCTION "crypto_aead_det_keygen"(); Type: ACL; Schema: pgsodium; Owner: supabase_admin
--

-- GRANT ALL ON FUNCTION "pgsodium"."crypto_aead_det_keygen"() TO "service_role";


--
-- Name: FUNCTION "approve_ride"("ride_id" integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."approve_ride"("ride_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."approve_ride"("ride_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."approve_ride"("ride_id" integer) TO "service_role";


--
-- Name: FUNCTION "create_chat"(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."create_chat"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_chat"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_chat"() TO "service_role";


--
-- Name: FUNCTION "create_ride_event"(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."create_ride_event"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_ride_event"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_ride_event"() TO "service_role";


--
-- Name: FUNCTION "delete_claim"("uid" "uuid", "claim" "text"); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."delete_claim"("uid" "uuid", "claim" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."delete_claim"("uid" "uuid", "claim" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_claim"("uid" "uuid", "claim" "text") TO "service_role";


--
-- Name: FUNCTION "get_claim"("uid" "uuid", "claim" "text"); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."get_claim"("uid" "uuid", "claim" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_claim"("uid" "uuid", "claim" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_claim"("uid" "uuid", "claim" "text") TO "service_role";


--
-- Name: FUNCTION "get_claims"("uid" "uuid"); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."get_claims"("uid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_claims"("uid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_claims"("uid" "uuid") TO "service_role";


--
-- Name: FUNCTION "get_my_claim"("claim" "text"); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."get_my_claim"("claim" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_claim"("claim" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_claim"("claim" "text") TO "service_role";


--
-- Name: FUNCTION "get_my_claims"(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."get_my_claims"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_claims"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_claims"() TO "service_role";


--
-- Name: FUNCTION "is_claims_admin"(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."is_claims_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_claims_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_claims_admin"() TO "service_role";


--
-- Name: FUNCTION "is_ride_update_allowed"("ride_id" integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."is_ride_update_allowed"("ride_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."is_ride_update_allowed"("ride_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_ride_update_allowed"("ride_id" integer) TO "service_role";


--
-- Name: FUNCTION "mark_message_as_read"("message_id" integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."mark_message_as_read"("message_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."mark_message_as_read"("message_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_message_as_read"("message_id" integer) TO "service_role";


--
-- Name: FUNCTION "mark_ride_event_as_read"("ride_event_id" integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."mark_ride_event_as_read"("ride_event_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."mark_ride_event_as_read"("ride_event_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_ride_event_as_read"("ride_event_id" integer) TO "service_role";


--
-- Name: FUNCTION "reject_ride"("ride_id" integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."reject_ride"("ride_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."reject_ride"("ride_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."reject_ride"("ride_id" integer) TO "service_role";


--
-- Name: FUNCTION "ride_event_insert"(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."ride_event_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."ride_event_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ride_event_insert"() TO "service_role";


--
-- Name: FUNCTION "set_admin_role"(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."set_admin_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_admin_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_admin_role"() TO "service_role";


--
-- Name: FUNCTION "set_claim"("uid" "uuid", "claim" "text", "value" "jsonb"); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."set_claim"("uid" "uuid", "claim" "text", "value" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."set_claim"("uid" "uuid", "claim" "text", "value" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_claim"("uid" "uuid", "claim" "text", "value" "jsonb") TO "service_role";


--
-- Name: FUNCTION "update_ride_status"(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION "public"."update_ride_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_ride_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_ride_status"() TO "service_role";


--
-- Name: TABLE "pg_stat_statements"; Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON TABLE "extensions"."pg_stat_statements" TO "dashboard_user";


--
-- Name: TABLE "pg_stat_statements_info"; Type: ACL; Schema: extensions; Owner: supabase_admin
--

-- GRANT ALL ON TABLE "extensions"."pg_stat_statements_info" TO "dashboard_user";


--
-- Name: SEQUENCE "seq_schema_version"; Type: ACL; Schema: graphql; Owner: supabase_admin
--

-- GRANT ALL ON SEQUENCE "graphql"."seq_schema_version" TO "postgres";
-- GRANT ALL ON SEQUENCE "graphql"."seq_schema_version" TO "anon";
-- GRANT ALL ON SEQUENCE "graphql"."seq_schema_version" TO "authenticated";
-- GRANT ALL ON SEQUENCE "graphql"."seq_schema_version" TO "service_role";


--
-- Name: TABLE "decrypted_key"; Type: ACL; Schema: pgsodium; Owner: supabase_admin
--

-- GRANT ALL ON TABLE "pgsodium"."decrypted_key" TO "pgsodium_keyholder";


--
-- Name: SEQUENCE "key_key_id_seq"; Type: ACL; Schema: pgsodium; Owner: supabase_admin
--

-- GRANT ALL ON SEQUENCE "pgsodium"."key_key_id_seq" TO "pgsodium_keyiduser";


--
-- Name: TABLE "masking_rule"; Type: ACL; Schema: pgsodium; Owner: supabase_admin
--

-- GRANT ALL ON TABLE "pgsodium"."masking_rule" TO "pgsodium_keyholder";


--
-- Name: TABLE "mask_columns"; Type: ACL; Schema: pgsodium; Owner: supabase_admin
--

-- GRANT ALL ON TABLE "pgsodium"."mask_columns" TO "pgsodium_keyholder";


--
-- Name: TABLE "chats"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."chats" TO "anon";
GRANT ALL ON TABLE "public"."chats" TO "authenticated";
GRANT ALL ON TABLE "public"."chats" TO "service_role";


--
-- Name: SEQUENCE "chats_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."chats_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."chats_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."chats_id_seq" TO "service_role";


--
-- Name: TABLE "drives"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."drives" TO "anon";
GRANT ALL ON TABLE "public"."drives" TO "authenticated";
GRANT ALL ON TABLE "public"."drives" TO "service_role";


--
-- Name: SEQUENCE "drives_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."drives_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."drives_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."drives_id_seq" TO "service_role";


--
-- Name: TABLE "messages"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";


--
-- Name: SEQUENCE "messages_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "service_role";


--
-- Name: TABLE "profile_features"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."profile_features" TO "anon";
GRANT ALL ON TABLE "public"."profile_features" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_features" TO "service_role";


--
-- Name: SEQUENCE "profile_features_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."profile_features_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."profile_features_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."profile_features_id_seq" TO "service_role";


--
-- Name: TABLE "profiles"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";


--
-- Name: TABLE "recurring_drives"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."recurring_drives" TO "anon";
GRANT ALL ON TABLE "public"."recurring_drives" TO "authenticated";
GRANT ALL ON TABLE "public"."recurring_drives" TO "service_role";


--
-- Name: SEQUENCE "recurring_drives_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."recurring_drives_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."recurring_drives_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."recurring_drives_id_seq" TO "service_role";


--
-- Name: TABLE "reports"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."reports" TO "anon";
GRANT ALL ON TABLE "public"."reports" TO "authenticated";
GRANT ALL ON TABLE "public"."reports" TO "service_role";


--
-- Name: SEQUENCE "reports_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."reports_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."reports_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."reports_id_seq" TO "service_role";


--
-- Name: TABLE "reviews"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."reviews" TO "anon";
GRANT ALL ON TABLE "public"."reviews" TO "authenticated";
GRANT ALL ON TABLE "public"."reviews" TO "service_role";


--
-- Name: SEQUENCE "reviews_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."reviews_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."reviews_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."reviews_id_seq" TO "service_role";


--
-- Name: TABLE "ride_events"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."ride_events" TO "anon";
GRANT ALL ON TABLE "public"."ride_events" TO "authenticated";
GRANT ALL ON TABLE "public"."ride_events" TO "service_role";


--
-- Name: SEQUENCE "rider_events_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."rider_events_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."rider_events_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."rider_events_id_seq" TO "service_role";


--
-- Name: TABLE "rides"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."rides" TO "anon";
GRANT ALL ON TABLE "public"."rides" TO "authenticated";
GRANT ALL ON TABLE "public"."rides" TO "service_role";


--
-- Name: SEQUENCE "rides_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."rides_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."rides_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."rides_id_seq" TO "service_role";


--
-- Name: SEQUENCE "users_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."users_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."users_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."users_id_seq" TO "service_role";


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
-- ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";


--
-- PostgreSQL database dump complete
--

RESET ALL;

