/**
 * CineFlow AI JavaScript SDK
 * Interactive stateful AI video platform client library
 */

export interface CineFlowConfig {
  apiUrl: string;
  apiKey: string;
  graphqlEndpoint?: string;
}

export class CineFlowClient {
  private apiUrl: string;
  private apiKey: string;

  constructor(config: CineFlowConfig) {
    this.apiUrl = config.apiUrl;
    this.apiKey = config.apiKey;
  }

  async createExperience(title: string, description: string) {
    return fetch(`${this.apiUrl}/api/v1/experiences`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': this.apiKey
      },
      body: JSON.stringify({ title, description })
    }).then(r => r.json());
  }

  async getExperience(experienceId: string) {
    return fetch(`${this.apiUrl}/api/v1/experiences/${experienceId}`, {
      headers: { 'X-API-Key': this.apiKey }
    }).then(r => r.json());
  }

  async recordInteraction(experienceId: string, elementId: string, action: any) {
    return fetch(`${this.apiUrl}/api/v1/experiences/${experienceId}/interactions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': this.apiKey
      },
      body: JSON.stringify({
        interactive_element_id: elementId,
        interaction_data: action
      })
    }).then(r => r.json());
  }
}

export default CineFlowClient;
