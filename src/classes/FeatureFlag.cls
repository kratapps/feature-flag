/*
 * BSD 3-Clause License
 * https://github.com/kratapps/feature-flag/blob/main/LICENSE
 */

/**
 * @description Feature Flag.
 *
 * Docs: https://kratapps.com/component-library/feature-flag
 * Tests: FeatureFlagTest
 *
 * Inspired by salesforce-feature-flags project by Pablo Gonzalez
 * https://github.com/pgonzaleznetwork/salesforce-feature-flags
 *
 * @author kratapps.com
 */
public virtual class FeatureFlag {
    private static Map<String, Boolean> apexValues = new Map<String, Boolean>();
    private static Map<String, Boolean> mockValues = new Map<String, Boolean>();

    private final String name;
    private FeatureFlagProvider provider = new FeatureFlagProvider();

    public static void setValue(String featureName, Boolean enabled) {
        if (String.isBlank(featureName)) {
            throw new IllegalArgumentException('featureName cannot be blank: ' + featureName);
        }
        apexValues.put(featureName, enabled);
    }

    public static void clearValue(String featureName) {
        if (String.isBlank(featureName)) {
            throw new IllegalArgumentException('featureName cannot be blank: ' + featureName);
        }
        apexValues.remove(featureName);
    }

    @TestVisible
    private static void setMockValue(String featureName, Boolean enabled) {
        if (String.isBlank(featureName)) {
            throw new IllegalArgumentException('featureName cannot be blank: ' + featureName);
        }
        mockValues.put(featureName, enabled);
    }

    @TestVisible
    private static void clearMockValue(String featureName) {
        if (String.isBlank(featureName)) {
            throw new IllegalArgumentException('featureName cannot be blank: ' + featureName);
        }
        mockValues.remove(featureName);
    }

    @AuraEnabled(Cacheable=true)
    public static Boolean isEnabled(String name) {
        return new FeatureFlag(name).isEnabled();
    }

    public FeatureFlag() {
        this.name = Crypto.getRandomLong().toString();
        setValue(true);
    }

    public FeatureFlag(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public Boolean isEnabled() {
        return new Set<FeatureFlagReason>{
                FeatureFlagReason.MOCK_ENABLED,
                FeatureFlagReason.APEX_ENABLED,
                FeatureFlagReason.CUSTOM_PERMISSION_ENABLED,
                FeatureFlagReason.CUSTOM_METADATA_TYPE_ENABLED
            }
            .contains(getReason());
    }

    public FeatureFlagReason getReason() {
        // is mocked
        if (Test.isRunningTest() && mockValues.get(name) != null) {
            return mockValues.get(name) ? FeatureFlagReason.MOCK_ENABLED : FeatureFlagReason.MOCK_DISABLED;
        }
        // is overridden in apex
        if (apexValues.get(name) != null) {
            return apexValues.get(name) ? FeatureFlagReason.APEX_ENABLED : FeatureFlagReason.APEX_DISABLED;
        }
        return getProvidedReason();
    }

    private FeatureFlagReason getProvidedReason() {
        Map<String, FeatureFlag__mdt> metadata = provider.getFeatureFlags();
        Set<String> permissionNames = provider.getCustomPermissionNames();
        // feature flag has name
        if (permissionNames.contains(name + 'Disabled') && provider.checkPermission(name + 'Disabled')) {
            // has restrictive custom permission
            return FeatureFlagReason.CUSTOM_PERMISSION_DISABLED;
        } else if (permissionNames.contains(name) && provider.checkPermission(name)) {
            // has custom permission
            return FeatureFlagReason.CUSTOM_PERMISSION_ENABLED;
        } else if (metadata.containsKey(name)) {
            // enabled via custom metadata
            return metadata.get(name).Is_Active__c
                ? FeatureFlagReason.CUSTOM_METADATA_TYPE_ENABLED
                : FeatureFlagReason.CUSTOM_METADATA_TYPE_DISABLED;
        }
        return FeatureFlagReason.FLAG_NOT_FOUND;
    }

    public void setProvider(FeatureFlagProvider provider) {
        this.provider = provider;
    }

    public void setValue(Boolean enabled) {
        setValue(name, enabled);
    }

    public void clearValue() {
        clearValue(name);
    }

    @TestVisible
    private void setMockValue(Boolean enabled) {
        setMockValue(name, enabled);
    }

    @TestVisible
    private void clearMockValue() {
        clearMockValue(name);
    }
}