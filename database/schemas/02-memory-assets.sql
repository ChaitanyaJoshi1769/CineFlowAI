-- Memory Engine, Asset Library, and related tables

-- ============================================================================
-- MODULE 10: MEMORY ENGINE
-- ============================================================================

-- Global Memory (Experience-level memory)
CREATE TABLE global_memory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  key VARCHAR(255) NOT NULL,
  value JSONB NOT NULL,
  memory_type VARCHAR(50) DEFAULT 'fact' CHECK (memory_type IN ('fact', 'event', 'concept', 'relationship', 'rule')),
  importance DECIMAL(3,2) DEFAULT 0.5,
  source VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  accessed_at TIMESTAMP,
  UNIQUE(experience_id, key),
  INDEX idx_global_mem_exp_id (experience_id),
  INDEX idx_global_mem_type (memory_type),
  INDEX idx_global_mem_accessed (accessed_at)
);

-- Conversation Memory
CREATE TABLE conversation_memory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
  viewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
  turn_number INTEGER,
  speaker VARCHAR(50) CHECK (speaker IN ('user', 'character', 'narrator')),
  message_text TEXT NOT NULL,
  embedding VECTOR(1536),
  emotion VARCHAR(100),
  topics TEXT[] DEFAULT '{}',
  entities_mentioned JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_conv_mem_exp_id (experience_id),
  INDEX idx_conv_mem_char_id (character_id),
  INDEX idx_conv_mem_viewer_id (viewer_id),
  INDEX idx_conv_mem_turn (turn_number)
);

-- Knowledge Graph
CREATE TABLE knowledge_graph_nodes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  node_type VARCHAR(100) CHECK (node_type IN ('entity', 'concept', 'event', 'relationship', 'location')),
  label VARCHAR(255) NOT NULL,
  description TEXT,
  properties JSONB DEFAULT '{}',
  importance DECIMAL(3,2) DEFAULT 0.5,
  embedding VECTOR(1536),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(experience_id, node_type, label),
  INDEX idx_kg_nodes_exp_id (experience_id),
  INDEX idx_kg_nodes_type (node_type),
  INDEX idx_kg_nodes_label (label)
);

CREATE TABLE knowledge_graph_edges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  source_node_id UUID NOT NULL REFERENCES knowledge_graph_nodes(id) ON DELETE CASCADE,
  target_node_id UUID NOT NULL REFERENCES knowledge_graph_nodes(id) ON DELETE CASCADE,
  edge_type VARCHAR(100),
  strength DECIMAL(3,2) DEFAULT 0.5,
  properties JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(source_node_id, target_node_id, edge_type),
  INDEX idx_kg_edges_exp_id (experience_id),
  INDEX idx_kg_edges_source (source_node_id),
  INDEX idx_kg_edges_target (target_node_id)
);

-- Vector Embeddings (for semantic search)
CREATE TABLE embeddings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  entity_id VARCHAR(255) NOT NULL,
  entity_type VARCHAR(100),
  content TEXT,
  embedding VECTOR(1536) NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_embeddings_exp_id (experience_id),
  INDEX idx_embeddings_entity (entity_id, entity_type),
  INDEX idx_embeddings_vector ON embeddings USING HNSW (embedding vector_cosine_ops)
);

-- ============================================================================
-- MODULE 12: ASSET LIBRARY
-- ============================================================================

-- Asset Collections
CREATE TABLE asset_collections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  asset_type VARCHAR(100) CHECK (asset_type IN ('character', 'prop', 'animation', 'music', 'sound_effect', 'texture', 'world', 'environment')),
  tags TEXT[] DEFAULT '{}',
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID NOT NULL REFERENCES users(id),
  INDEX idx_assets_org_id (organization_id),
  INDEX idx_assets_type (asset_type),
  INDEX idx_assets_public (is_public)
);

-- Assets
CREATE TABLE assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_collection_id UUID NOT NULL REFERENCES asset_collections(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  asset_type VARCHAR(100),
  description TEXT,
  file_path TEXT,
  file_size_mb DECIMAL(10,2),
  mime_type VARCHAR(100),
  duration_seconds DECIMAL(8,2),
  tags TEXT[] DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  thumbnail_url TEXT,
  preview_url TEXT,
  s3_key VARCHAR(500),
  version INTEGER DEFAULT 1,
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by UUID REFERENCES users(id),
  INDEX idx_assets_collection_id (asset_collection_id),
  INDEX idx_assets_type (asset_type),
  INDEX idx_assets_name (name),
  INDEX idx_assets_tags (tags)
);

-- Character Asset Details
CREATE TABLE character_assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id UUID NOT NULL UNIQUE REFERENCES assets(id) ON DELETE CASCADE,
  character_model_path TEXT,
  rigging_data JSONB,
  blend_shapes JSONB,
  animation_skeletons JSONB,
  facial_rig_type VARCHAR(100),
  expression_range JSONB,
  movement_capabilities TEXT[] DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_char_asset_asset_id (asset_id)
);

-- Animation Asset Details
CREATE TABLE animation_assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id UUID NOT NULL UNIQUE REFERENCES assets(id) ON DELETE CASCADE,
  animation_type VARCHAR(100) CHECK (animation_type IN ('idle', 'walk', 'run', 'jump', 'gesture', 'emotion', 'interaction', 'transition')),
  frame_count INTEGER,
  frame_rate DECIMAL(5,2),
  bones_affected TEXT[] DEFAULT '{}',
  loop_enabled BOOLEAN DEFAULT FALSE,
  root_motion_enabled BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_anim_asset_asset_id (asset_id),
  INDEX idx_anim_asset_type (animation_type)
);

-- Music/Sound Asset Details
CREATE TABLE audio_assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id UUID NOT NULL UNIQUE REFERENCES assets(id) ON DELETE CASCADE,
  audio_type VARCHAR(100) CHECK (audio_type IN ('music', 'ambience', 'sound_effect', 'speech')),
  sample_rate_hz INTEGER,
  bit_depth INTEGER,
  channels INTEGER,
  loudness_lufs DECIMAL(5,2),
  frequency_profile JSONB,
  emotion_tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audio_asset_asset_id (asset_id),
  INDEX idx_audio_asset_type (audio_type)
);

-- Texture Asset Details
CREATE TABLE texture_assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  asset_id UUID NOT NULL UNIQUE REFERENCES assets(id) ON DELETE CASCADE,
  texture_type VARCHAR(100) CHECK (texture_type IN ('diffuse', 'normal', 'roughness', 'metallic', 'emissive', 'displacement')),
  resolution VARCHAR(50),
  color_space VARCHAR(50),
  uv_tiling JSONB,
  material_properties JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_texture_asset_asset_id (asset_id)
);

-- ============================================================================
-- MODULE 13: WORLD BUILDER
-- ============================================================================

-- Worlds
CREATE TABLE worlds (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  world_type VARCHAR(100) CHECK (world_type IN ('urban', 'rural', 'fantasy', 'sci_fi', 'historical', 'abstract', 'hybrid')),
  description TEXT,
  scale_meters DECIMAL(12,2),
  generation_seed BIGINT,
  procedural_config JSONB,
  biome_distribution JSONB,
  weather_system JSONB,
  time_of_day VARCHAR(50),
  lighting_config JSONB,
  physics_config JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_worlds_exp_id (experience_id),
  INDEX idx_worlds_type (world_type)
);

-- Locations
CREATE TABLE locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  location_type VARCHAR(100),
  x DECIMAL(12,4),
  y DECIMAL(12,4),
  z DECIMAL(12,4),
  radius_meters DECIMAL(10,2),
  description TEXT,
  accessibility VARCHAR(50),
  environment_config JSONB,
  visual_style JSONB,
  audio_ambience_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_locations_world_id (world_id),
  INDEX idx_locations_type (location_type)
);

-- NPCs
CREATE TABLE npcs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  character_type VARCHAR(100),
  occupation VARCHAR(100),
  home_location_id UUID REFERENCES locations(id),
  current_location_id UUID REFERENCES locations(id),
  personality_traits JSONB,
  dialogue_lines JSONB,
  daily_schedule JSONB,
  goals TEXT[] DEFAULT '{}',
  relationships JSONB DEFAULT '{}',
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_npcs_world_id (world_id),
  INDEX idx_npcs_location (current_location_id)
);

-- Events (world events, not state events)
CREATE TABLE world_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  world_id UUID NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
  event_name VARCHAR(255),
  event_type VARCHAR(100),
  occurrence_chance DECIMAL(3,2),
  time_of_occurrence VARCHAR(255),
  location_id UUID REFERENCES locations(id),
  affected_npcs TEXT[] DEFAULT '{}',
  description TEXT,
  consequences JSONB,
  has_occurred BOOLEAN DEFAULT FALSE,
  occurred_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_world_events_world_id (world_id),
  INDEX idx_world_events_type (event_type)
);

-- ============================================================================
-- MODULE 14: REALTIME STREAMING
-- ============================================================================

-- Streaming Sessions
CREATE TABLE streaming_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  viewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_token VARCHAR(255) UNIQUE,
  state_version INTEGER,
  current_scene_id UUID REFERENCES scenes(id),
  bitrate_kbps INTEGER DEFAULT 5000,
  resolution VARCHAR(50) DEFAULT '1920x1080',
  fps INTEGER DEFAULT 30,
  codec VARCHAR(50) DEFAULT 'h264',
  connection_type VARCHAR(50),
  device_type VARCHAR(50),
  location JSONB,
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'ended', 'disconnected')),
  total_bytes_sent BIGINT DEFAULT 0,
  playback_position_seconds DECIMAL(8,2),
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ended_at TIMESTAMP,
  duration_seconds INTEGER,
  INDEX idx_stream_exp_id (experience_id),
  INDEX idx_stream_viewer_id (viewer_id),
  INDEX idx_stream_status (status),
  INDEX idx_stream_started_at (started_at)
);

-- Stream Events (for debugging and analytics)
CREATE TABLE stream_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  streaming_session_id UUID NOT NULL REFERENCES streaming_sessions(id) ON DELETE CASCADE,
  event_type VARCHAR(100) CHECK (event_type IN ('buffering', 'quality_change', 'error', 'interaction', 'frame_drop', 'latency_spike')),
  timestamp_seconds DECIMAL(8,2),
  bitrate_kbps INTEGER,
  latency_ms INTEGER,
  frame_drop_percent DECIMAL(5,2),
  error_message TEXT,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_stream_events_session_id (streaming_session_id),
  INDEX idx_stream_events_type (event_type),
  INDEX idx_stream_events_created_at (created_at)
);

-- ============================================================================
-- MODULE 17: ANALYTICS
-- ============================================================================

-- Viewer Engagement
CREATE TABLE viewer_engagement (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  viewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total_sessions INTEGER DEFAULT 1,
  total_duration_minutes DECIMAL(10,2),
  completion_rate DECIMAL(3,2),
  favorite_scenes TEXT[] DEFAULT '{}',
  most_chosen_branch UUID REFERENCES narrative_branches(id),
  interaction_count INTEGER DEFAULT 0,
  emotion_curve JSONB,
  engagement_score DECIMAL(5,2),
  last_viewed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_engagement_exp_id (experience_id),
  INDEX idx_engagement_viewer_id (viewer_id)
);

-- Quality Metrics
CREATE TABLE quality_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  experience_id UUID NOT NULL REFERENCES experiences(id) ON DELETE CASCADE,
  metric_date DATE NOT NULL,
  avg_generation_time_ms DECIMAL(8,2),
  avg_frame_rate DECIMAL(5,2),
  video_quality_score DECIMAL(3,2),
  audio_quality_score DECIMAL(3,2),
  narrative_coherence_score DECIMAL(3,2),
  character_consistency_score DECIMAL(3,2),
  user_satisfaction_score DECIMAL(3,2),
  total_errors INTEGER DEFAULT 0,
  error_rate DECIMAL(5,4),
  UNIQUE(experience_id, metric_date),
  INDEX idx_quality_metrics_exp_id (experience_id),
  INDEX idx_quality_metrics_date (metric_date)
);

-- Cost Tracking
CREATE TABLE cost_tracking (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  service_type VARCHAR(100),
  unit_count DECIMAL(12,2),
  unit_type VARCHAR(50),
  cost_usd DECIMAL(10,4),
  cost_date DATE,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_cost_org_id (organization_id),
  INDEX idx_cost_service_type (service_type),
  INDEX idx_cost_date (cost_date)
);

-- API Usage
CREATE TABLE api_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  api_key_id UUID REFERENCES api_keys(id),
  endpoint VARCHAR(500),
  method VARCHAR(10),
  status_code INTEGER,
  response_time_ms INTEGER,
  request_size_bytes INTEGER,
  response_size_bytes INTEGER,
  rate_limit_remaining INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_api_usage_org_id (organization_id),
  INDEX idx_api_usage_endpoint (endpoint),
  INDEX idx_api_usage_created_at (created_at)
);

-- Job History
CREATE TABLE job_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  job_type VARCHAR(100),
  job_id VARCHAR(255),
  status VARCHAR(50) CHECK (status IN ('pending', 'running', 'completed', 'failed')),
  progress_percent INTEGER DEFAULT 0,
  input_data JSONB,
  output_data JSONB,
  error_message TEXT,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  duration_seconds INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_jobs_org_id (organization_id),
  INDEX idx_jobs_type (job_type),
  INDEX idx_jobs_status (status),
  INDEX idx_jobs_created_at (created_at)
);

-- ============================================================================
-- Create important additional indexes
-- ============================================================================

CREATE INDEX idx_global_memory_importance ON global_memory(importance);
CREATE INDEX idx_character_memory_importance ON character_memory(importance);
CREATE INDEX idx_embeddings_type ON embeddings(entity_type);
CREATE INDEX idx_assets_updated_at ON assets(updated_at);
CREATE INDEX idx_streaming_sessions_updated_created ON streaming_sessions(started_at, ended_at);
