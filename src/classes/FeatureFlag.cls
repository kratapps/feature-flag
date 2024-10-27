/*
 * BSD 3-Clause License
 * https://github.com/kratapps/feature-flag/blob/main/LICENSE
 */

/**
 * @description Feature Flag.
 *
 * Docs: <a href="https://kratapps.com/component-library/feature-flag"></a>
 *
 * Tests: FeatureFlagTest
 *
 * Inspired by salesforce-feature-flags project by Pablo Gonzalez
 * <a href="https://github.com/pgonzaleznetwork/salesforce-feature-flags"></a>
 *
 * @author kratapps.com
 */
@SuppressWarnings('PMD.cyclomaticcomplexity')
public virtual class FeatureFlag {
    private static Map<String, Boolean> apexFlags = new Map<String, Boolean>();
    private static Map<String, Boolean> mockFlags = new Map<String, Boolean>();

    private final String name;
    private FeatureFlagProvider provider = new FeatureFlagProvider();

    public static void enable(String featureName) {
        if (String.isBlank(featureName)) {
            throw new IllegalArgumentException('featureName cannot be blank: ' + featureName);
        }
        apexFlags.put(featureName, true);
    }

    public static void disable(String featureName) {
        if (String.isBlank(featureName)) {
            throw new IllegalArgumentException('featureName cannot be blank: ' + featureName);
        }
        apexFlags.put(featureName, false);
    }

    public static void reset(String featureName) {
        if (String.isBlank(featureName)) {
            throw new IllegalArgumentException('featureName cannot be blank: ' + featureName);
        }
        apexFlags.remove(featureName);
    }

    @TestVisible
    private static void enableMock(String featureName) {
        if (String.isBlank(featureName)) {
            throw new IllegalArgumentException('featureName cannot be blank: ' + featureName);
        }
        mockFlags.put(featureName, true);
    }

    @TestVisible
    private static void disableMock(String featureName) {
        if (String.isBlank(featureName)) {
            throw new IllegalArgumentException('featureName cannot be blank: ' + featureName);
        }
        mockFlags.put(featureName, false);
    }

    @TestVisible
    private static void clearMock(String featureName) {
        if (String.isBlank(featureName)) {
            throw new IllegalArgumentException('featureName cannot be blank: ' + featureName);
        }
        mockFlags.remove(featureName);
    }

    @AuraEnabled(Cacheable=true)
    public static Boolean isEnabled(String name) {
        return new FeatureFlag(name).isEnabled();
    }

    public FeatureFlag() {
        this.name = 'AnonymousFlag_' + Crypto.getRandomLong().toString();
        enable();
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
        if (Test.isRunningTest() && mockFlags.get(name) != null) {
            return mockFlags.get(name) ? FeatureFlagReason.MOCK_ENABLED : FeatureFlagReason.MOCK_DISABLED;
        }
        // is overridden in apex
        if (apexFlags.get(name) != null) {
            return apexFlags.get(name) ? FeatureFlagReason.APEX_ENABLED : FeatureFlagReason.APEX_DISABLED;
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

    public void enable() {
        enable(name);
    }

    public void disable() {
        disable(name);
    }

    public void reset() {
        reset(name);
    }

    @TestVisible
    private void enableMock() {
        enableMock(name);
    }

    @TestVisible
    private void disableMock() {
        disableMock(name);
    }

    @TestVisible
    private void clearMock() {
        clearMock(name);
    }
}