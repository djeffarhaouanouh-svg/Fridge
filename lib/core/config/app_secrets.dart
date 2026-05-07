class AppSecrets {
  static const googleVisionApiKey = String.fromEnvironment(
    'GOOGLE_VISION_API_KEY',
    defaultValue: '',
  );
  static const anthropicApiKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
    defaultValue: '',
  );
}

const kAnthropicKey = AppSecrets.anthropicApiKey;
const kSpoonacularKey =
    String.fromEnvironment('SPOONACULAR_API_KEY', defaultValue: '');
const kGoogleCseKey =
    String.fromEnvironment('GOOGLE_CSE_API_KEY', defaultValue: '');
const kPexelsKey = String.fromEnvironment('PEXELS_API_KEY', defaultValue: '');
const kNeonPassword = String.fromEnvironment('NEON_PASSWORD', defaultValue: '');
