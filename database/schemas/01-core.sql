-- Core foundation tables for CineFlow AI

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ============================================================================
-- MODULE 1: IDENTITY PLATFORM
-- ============================================================================

-- Organizations
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  description TEXT,
  logo_url TEXT,
  metadata JSONB DEFAULT '{}',
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deleted')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID,
  INDEX idx_orgs_slug (slug),
  INDEX idx_orgs_created_at (created_at)
);

-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  username VARCHAR(255) UNIQUE,
  password_hash VARCHAR(255),
  first_name VARCHAR(128),
  last_name VARCHAR(128),
  avatar_url TEXT,
  bio TEXT,
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'banned')),
  email_verified BOOLEAN DEFAULT FALSE,
  email_verified_at TIMESTAMP,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login_at TIMESTAMP,
  CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'),
  INDEX idx_users_email (email),
  INDEX idx_users_username (username),
  INDEX idx_users_created_at (created_at)
);

-- OAuth Providers
CREATE TABLE oauth_providers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider VARCHAR(50) NOT NULL CHECK (provider IN ('google', 'github', 'microsoft', 'apple')),
  provider_user_id VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  name VARCHAR(255),
  picture_url TEXT,
  raw_data JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(provider, provider_user_id),
  INDEX idx_oauth_user_id (user_id),
  INDEX idx_oauth_provider (provider)
);

-- Memberships (User -> Organization)
CREATE TABLE memberships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  invited_by UUID REFERENCES users(id),
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  invited_at TIMESTAMP,
  metadata JSONB DEFAULT '{}',
  UNIQUE(user_id, organization_id),
  INDEX idx_memberships_org_id (organization_id),
  INDEX idx_memberships_user_id (user_id)
);

-- Teams
CREATE TABLE teams (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  icon_url TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID NOT NULL REFERENCES users(id),
  INDEX idx_teams_org_id (organization_id),
  INDEX idx_teams_created_at (created_at)
);

-- Team Memberships
CREATE TABLE team_memberships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('lead', 'member')),
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(team_id, user_id),
  INDEX idx_team_members_team_id (team_id),
  INDEX idx_team_members_user_id (user_id)
);

-- Projects
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  project_type VARCHAR(50) DEFAULT 'experience' CHECK (project_type IN ('experience', 'component', 'dataset', 'model')),
  status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'archived', 'deleted')),
  visibility VARCHAR(50) DEFAULT 'private' CHECK (visibility IN ('private', 'team', 'organization', 'public')),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID NOT NULL REFERENCES users(id),
  UNIQUE(organization_id, slug),
  INDEX idx_projects_org_id (organization_id),
  INDEX idx_projects_created_at (created_at),
  INDEX idx_projects_status (status)
);

-- API Keys
CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  key_hash VARCHAR(255) NOT NULL UNIQUE,
  key_prefix VARCHAR(20) NOT NULL,
  permissions JSONB DEFAULT '[]',
  rate_limit_per_minute INTEGER DEFAULT 1000,
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'revoked')),
  last_used_at TIMESTAMP,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID NOT NULL REFERENCES users(id),
  INDEX idx_api_keys_org_id (organization_id),
  INDEX idx_api_keys_project_id (project_id),
  INDEX idx_api_keys_key_hash (key_hash)
);

-- Permissions (RBAC)
CREATE TABLE permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  resource_type VARCHAR(100) NOT NULL,
  resource_id UUID NOT NULL,
  action VARCHAR(100) NOT NULL,
  granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  granted_by UUID REFERENCES users(id),
  metadata JSONB DEFAULT '{}',
  INDEX idx_permissions_user (user_id, resource_type, resource_id),
  INDEX idx_permissions_team (team_id, resource_type, resource_id),
  INDEX idx_permissions_org (organization_id, resource_type, resource_id)
);

-- Audit Logs
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  action VARCHAR(100) NOT NULL,
  resource_type VARCHAR(100) NOT NULL,
  resource_id UUID,
  changes JSONB,
  ip_address INET,
  user_agent TEXT,
  status VARCHAR(50) DEFAULT 'success' CHECK (status IN ('success', 'failure')),
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_org_id (organization_id),
  INDEX idx_audit_user_id (user_id),
  INDEX idx_audit_created_at (created_at),
  INDEX idx_audit_resource (resource_type, resource_id)
);

-- MFA Settings
CREATE TABLE mfa_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  method VARCHAR(50) CHECK (method IN ('totp', 'sms', 'email')),
  secret VARCHAR(255),
  phone_number VARCHAR(20),
  backup_codes JSONB,
  enabled BOOLEAN DEFAULT FALSE,
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_mfa_user_id (user_id)
);

-- Sessions
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) UNIQUE NOT NULL,
  ip_address INET,
  user_agent TEXT,
  device_name VARCHAR(255),
  expires_at TIMESTAMP NOT NULL,
  revoked_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_sessions_user_id (user_id),
  INDEX idx_sessions_expires_at (expires_at),
  INDEX idx_sessions_token_hash (token_hash)
);

-- ============================================================================
-- MODULE 2-3: STORY ENGINE & STATE ENGINE
-- ============================================================================

-- Experiences (Main Project/Experience Record)
CREATE TABLE experiences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  genre VARCHAR(100),
  target_audience VARCHAR(255),
  runtime_minutes INTEGER,
  status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'production', 'review', 'published', 'archived')),
  visibility VARCHAR(50) DEFAULT 'private',
  metadata JSONB DEFAULT '{}',
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID NOT NULL REFERENCES users(id),
  published_at TIMESTAMP,
  published_by UUID REFERENCES users(id),
  INDEX idx_experiences_project_id (project_id),
  INDEX idx_experiences_status (status),
  INDEX idx_experiences_created_at (created_at)
);

-- World State (Global state for an experience)
CREATE TABLE world_states (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  name VARCHAR(255),
  description TEXT,
  settings JSONB DEFAULT '{}',
  facts JSONB DEFAULT '{}',
  lore JSONB DEFAULT '{}',
  economy_state JSONB DEFAULT '{}',
  time_of_day VARCHAR(50) DEFAULT 'day',
  weather_state JSONB DEFAULT '{}',
  npcs_alive TEXT[] DEFAULT '{}',
  locations_discovered JSONB DEFAULT '{}',
  events_triggered TEXT[] DEFAULT '{}',
  objects_state JSONB DEFAULT '{}',
  relationships JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(experience_id, version),
  INDEX idx_world_states_exp_id (experience_id),
  INDEX idx_world_states_version (version)
);

-- Characters
CREATE TABLE characters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(100),
  personality_archetype VARCHAR(100),
  voice_id VARCHAR(255),
  appearance JSONB DEFAULT '{}',
  backstory TEXT,
  goals JSONB DEFAULT '{}',
  beliefs JSONB DEFAULT '{}',
  secrets JSONB DEFAULT '{}',
  status VARCHAR(50) DEFAULT 'alive' CHECK (status IN ('alive', 'dead', 'absent', 'dormant')),
  appearance_model VARCHAR(255),
  animation_profile VARCHAR(255),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES users(id),
  INDEX idx_characters_exp_id (experience_id),
  INDEX idx_characters_name (name),
  INDEX idx_characters_status (status)
);

-- Character Memory
CREATE TABLE character_memory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
  memory_type VARCHAR(50) CHECK (memory_type IN ('episodic', 'semantic', 'procedural', 'emotional')),
  content TEXT NOT NULL,
  importance DECIMAL(3,2) DEFAULT 0.5 CHECK (importance >= 0 AND importance <= 1),
  related_characters TEXT[] DEFAULT '{}',
  related_events TEXT[] DEFAULT '{}',
  embedding VECTOR(1536),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_accessed_at TIMESTAMP,
  decay_rate DECIMAL(3,2) DEFAULT 0.01,
  INDEX idx_char_memory_char_id (character_id),
  INDEX idx_char_memory_type (memory_type),
  INDEX idx_char_memory_importance (importance)
);

-- Character Relationships
CREATE TABLE character_relationships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  character_a_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
  character_b_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
  relationship_type VARCHAR(100) NOT NULL,
  sentiment DECIMAL(3,2) DEFAULT 0 CHECK (sentiment >= -1 AND sentiment <= 1),
  history_summary TEXT,
  shared_memories JSONB DEFAULT '{}',
  inside_jokes TEXT[] DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(character_a_id, character_b_id),
  INDEX idx_char_rels_char_a (character_a_id),
  INDEX idx_char_rels_char_b (character_b_id)
);

-- Scenes
CREATE TABLE scenes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  scene_type VARCHAR(50),
  location VARCHAR(255),
  time_period VARCHAR(255),
  characters_present TEXT[] DEFAULT '{}',
  sequence_number INTEGER,
  duration_seconds INTEGER,
  prompt TEXT,
  generated_at TIMESTAMP,
  version INTEGER DEFAULT 1,
  status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'generated', 'reviewed', 'approved', 'archived')),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_scenes_exp_id (experience_id),
  INDEX idx_scenes_status (status),
  INDEX idx_scenes_sequence (sequence_number)
);

-- Events (for event sourcing)
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  event_type VARCHAR(100) NOT NULL,
  actor_id VARCHAR(255),
  actor_type VARCHAR(100),
  target_id VARCHAR(255),
  target_type VARCHAR(100),
  action VARCHAR(255),
  payload JSONB,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  sequence_number BIGINT,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_events_exp_id (experience_id),
  INDEX idx_events_type (event_type),
  INDEX idx_events_actor (actor_id),
  INDEX idx_events_timestamp (timestamp),
  INDEX idx_events_sequence (sequence_number)
);

-- Event Snapshots (for event sourcing optimization)
CREATE TABLE event_snapshots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  entity_id VARCHAR(255) NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  snapshot_version INTEGER NOT NULL,
  state JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(experience_id, entity_id, entity_type, snapshot_version),
  INDEX idx_snapshots_exp_id (experience_id),
  INDEX idx_snapshots_entity (entity_id, entity_type)
);

-- ============================================================================
-- MODULE 4: NARRATIVE PLANNER
-- ============================================================================

-- Story Arcs
CREATE TABLE story_arcs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  arc_type VARCHAR(50) CHECK (arc_type IN ('rising_action', 'climax', 'falling_action', 'resolution')),
  main_character_id UUID REFERENCES characters(id),
  conflict_type VARCHAR(100),
  stakes_level VARCHAR(50) CHECK (stakes_level IN ('low', 'medium', 'high', 'existential')),
  planned_pacing JSONB,
  actual_pacing JSONB,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_story_arcs_exp_id (experience_id)
);

-- Narrative Branches
CREATE TABLE narrative_branches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES narrative_branches(id) ON DELETE CASCADE,
  choice_point_id UUID,
  choice_text VARCHAR(255),
  outcome_summary TEXT,
  probability DECIMAL(3,2) DEFAULT 0.5,
  depth_level INTEGER,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_branches_exp_id (experience_id),
  INDEX idx_branches_parent_id (parent_id),
  INDEX idx_branches_depth (depth_level)
);

-- ============================================================================
-- MODULE 6: VIDEO GENERATION
-- ============================================================================

-- Video Generations
CREATE TABLE video_generations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scene_id UUID REFERENCES scenes(id) ON DELETE SET NULL,
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  generation_engine VARCHAR(100) CHECK (generation_engine IN ('openai', 'runway', 'luma', 'pika', 'svd', 'cogvideo', 'custom')),
  prompt TEXT NOT NULL,
  negative_prompt TEXT,
  duration_seconds DECIMAL(5,2),
  resolution VARCHAR(50),
  fps INTEGER DEFAULT 24,
  quality_level VARCHAR(50),
  video_url TEXT,
  thumbnail_url TEXT,
  raw_output_url TEXT,
  processing_time_ms INTEGER,
  cost_usd DECIMAL(10,4),
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  error_message TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  INDEX idx_video_gen_scene_id (scene_id),
  INDEX idx_video_gen_exp_id (experience_id),
  INDEX idx_video_gen_status (status),
  INDEX idx_video_gen_created_at (created_at)
);

-- Video Composites
CREATE TABLE video_composites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scene_id UUID NOT NULL REFERENCES scenes(id) ON DELETE CASCADE,
  video_url TEXT,
  layers JSONB DEFAULT '[]',
  composition_config JSONB,
  rendering_time_ms INTEGER,
  final_resolution VARCHAR(50),
  codec VARCHAR(50),
  bitrate_kbps INTEGER,
  file_size_mb DECIMAL(10,2),
  status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'rendering', 'completed', 'failed')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_composite_scene_id (scene_id),
  INDEX idx_composite_status (status)
);

-- ============================================================================
-- MODULE 8: VOICE ENGINE
-- ============================================================================

-- Voice Configurations
CREATE TABLE voice_configs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
  experience_id UUID REFERENCES experiences(id) ON DELETE CASCADE,
  voice_engine VARCHAR(100) CHECK (voice_engine IN ('elevenlabs', 'google', 'azure', 'aws', 'custom')),
  voice_id VARCHAR(255),
  voice_name VARCHAR(255),
  language VARCHAR(50) DEFAULT 'en',
  accent VARCHAR(100),
  emotional_profile JSONB DEFAULT '{}',
  speaking_rate DECIMAL(3,2) DEFAULT 1.0,
  pitch DECIMAL(3,2) DEFAULT 1.0,
  timbre_description TEXT,
  voice_sample_url TEXT,
  cloned_from UUID REFERENCES voice_configs(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_voice_char_id (character_id),
  INDEX idx_voice_exp_id (experience_id)
);

-- Voice Generations
CREATE TABLE voice_generations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  character_id UUID REFERENCES characters(id),
  voice_config_id UUID REFERENCES voice_configs(id),
  text_to_speak TEXT NOT NULL,
  language VARCHAR(50),
  emotion VARCHAR(100),
  emotion_intensity DECIMAL(3,2) DEFAULT 0.5,
  audio_url TEXT,
  audio_duration_ms INTEGER,
  processing_time_ms INTEGER,
  cost_usd DECIMAL(10,4),
  phonemes JSONB,
  lip_sync_data JSONB,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP,
  INDEX idx_voice_gen_exp_id (experience_id),
  INDEX idx_voice_gen_char_id (character_id),
  INDEX idx_voice_gen_status (status)
);

-- ============================================================================
-- MODULE 9: INTERACTIVE ENGINE
-- ============================================================================

-- Interactive Elements
CREATE TABLE interactive_elements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scene_id UUID NOT NULL REFERENCES scenes(id) ON DELETE CASCADE,
  element_type VARCHAR(100) CHECK (element_type IN ('dialogue_choice', 'clickable_object', 'gesture', 'voice_command', 'gesture_swipe', 'eye_gaze')),
  position JSONB,
  trigger_text VARCHAR(255),
  interaction_prompt TEXT,
  action_outcomes JSONB,
  consequences JSONB,
  branch_to UUID REFERENCES narrative_branches(id),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_interactive_scene_id (scene_id),
  INDEX idx_interactive_type (element_type)
);

-- User Interactions
CREATE TABLE user_interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  viewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  interactive_element_id UUID REFERENCES interactive_elements(id),
  interaction_type VARCHAR(100),
  interaction_data JSONB,
  timestamp_seconds DECIMAL(8,2),
  session_id VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_interactions_exp_id (experience_id),
  INDEX idx_interactions_viewer_id (viewer_id),
  INDEX idx_interactions_session_id (session_id),
  INDEX idx_interactions_created_at (created_at)
);

-- ============================================================================
-- Indexes for Performance
-- ============================================================================

CREATE INDEX idx_experiences_updated_at ON experiences(updated_at);
CREATE INDEX idx_events_created_at ON events(created_at);
CREATE INDEX idx_scenes_created_at ON scenes(created_at);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_organizations_created_at ON organizations(created_at);
CREATE INDEX idx_projects_updated_at ON projects(updated_at);
