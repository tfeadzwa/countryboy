-- Migration: Add agent code, username, and PIN generation functions
-- This migration adds PostgreSQL functions to auto-generate agent credentials

-- Function to generate unique agent code from full name
-- Format: 3 uppercase letters from name + 3 digits (e.g., JMO001, TMO014)
CREATE OR REPLACE FUNCTION generate_agent_code(p_full_name TEXT, p_depot_id TEXT)
RETURNS TEXT AS $$
DECLARE
  v_prefix TEXT;
  v_counter INT := 1;
  v_agent_code TEXT;
  v_exists BOOLEAN;
  v_names TEXT[];
  v_first_name TEXT;
  v_last_name TEXT;
BEGIN
  -- Split name into parts and get first and last name
  v_names := string_to_array(trim(p_full_name), ' ');
  
  IF array_length(v_names, 1) >= 2 THEN
    v_first_name := v_names[1];
    v_last_name := v_names[array_length(v_names, 1)];
    
    -- Generate 3-letter prefix: First letter of first name + First 2 letters of last name
    v_prefix := upper(substring(v_first_name, 1, 1) || substring(v_last_name, 1, 2));
  ELSE
    -- Single name: take first 3 letters
    v_prefix := upper(substring(p_full_name, 1, 3));
  END IF;
  
  -- Ensure prefix is exactly 3 characters
  WHILE length(v_prefix) < 3 LOOP
    v_prefix := v_prefix || 'X';
  END LOOP;
  v_prefix := substring(v_prefix, 1, 3);
  
  -- Find next available number for this prefix in this depot
  LOOP
    v_agent_code := v_prefix || lpad(v_counter::TEXT, 3, '0');
    
    SELECT EXISTS(
      SELECT 1 FROM "tblAgents" 
      WHERE agent_code = v_agent_code 
      AND depot_id = p_depot_id
    ) INTO v_exists;
    
    EXIT WHEN NOT v_exists;
    
    v_counter := v_counter + 1;
    
    -- Safety check: prevent infinite loop
    IF v_counter > 999 THEN
      RAISE EXCEPTION 'Unable to generate unique agent code for prefix %', v_prefix;
    END IF;
  END LOOP;
  
  RETURN v_agent_code;
END;
$$ LANGUAGE plpgsql;

-- Function to generate unique username from full name
-- Format: lowercase first initial + lowercase last name (e.g., jmoyo, tndlovu)
CREATE OR REPLACE FUNCTION generate_username(p_full_name TEXT, p_depot_id TEXT)
RETURNS TEXT AS $$
DECLARE
  v_username TEXT;
  v_counter INT := 1;
  v_exists BOOLEAN;
  v_names TEXT[];
  v_first_name TEXT;
  v_last_name TEXT;
BEGIN
  -- Split name into parts
  v_names := string_to_array(trim(p_full_name), ' ');
  
  IF array_length(v_names, 1) >= 2 THEN
    v_first_name := v_names[1];
    v_last_name := v_names[array_length(v_names, 1)];
    
    -- Generate username: first letter + last name
    v_username := lower(substring(v_first_name, 1, 1) || v_last_name);
  ELSE
    -- Single name: use as-is
    v_username := lower(p_full_name);
  END IF;
  
  -- Check if username exists, append number if needed
  LOOP
    IF v_counter = 1 THEN
      v_username := lower(substring(v_first_name, 1, 1) || v_last_name);
    ELSE
      v_username := lower(substring(v_first_name, 1, 1) || v_last_name) || v_counter::TEXT;
    END IF;
    
    SELECT EXISTS(
      SELECT 1 FROM "tblAgents" 
      WHERE username = v_username 
      AND depot_id = p_depot_id
    ) INTO v_exists;
    
    EXIT WHEN NOT v_exists;
    
    v_counter := v_counter + 1;
    
    -- Safety check
    IF v_counter > 999 THEN
      RAISE EXCEPTION 'Unable to generate unique username for %', p_full_name;
    END IF;
  END LOOP;
  
  RETURN v_username;
END;
$$ LANGUAGE plpgsql;

-- Function to generate unique 4-digit PIN
-- Returns a random 4-digit PIN that doesn't exist in the depot
CREATE OR REPLACE FUNCTION generate_pin(p_depot_id TEXT)
RETURNS TEXT AS $$
DECLARE
  v_pin TEXT;
  v_exists BOOLEAN;
  v_attempts INT := 0;
BEGIN
  LOOP
    -- Generate random 4-digit PIN (1000 to 9999)
    v_pin := lpad((1000 + floor(random() * 9000))::TEXT, 4, '0');
    
    -- Check if PIN exists (will need to check hashed version in app logic)
    -- For now, just generate random PIN - uniqueness check will be in app layer
    EXIT;
    
    v_attempts := v_attempts + 1;
    
    IF v_attempts > 100 THEN
      RAISE EXCEPTION 'Unable to generate unique PIN after 100 attempts';
    END IF;
  END LOOP;
  
  RETURN v_pin;
END;
$$ LANGUAGE plpgsql;

-- Add comment for documentation
COMMENT ON FUNCTION generate_agent_code(TEXT, TEXT) IS 'Generates unique agent code: 3 letters from name + 3 digits';
COMMENT ON FUNCTION generate_username(TEXT, TEXT) IS 'Generates unique username: first initial + last name';
COMMENT ON FUNCTION generate_pin(TEXT) IS 'Generates random 4-digit PIN';
