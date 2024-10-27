/*
 * BSD 3-Clause License
 * https://github.com/kratapps/component-library/blob/main/LICENSE
 */
@IsTest
private class FeatureFlagTest {
    @IsTest
    static void anonymousFlagIsEnabledByDefault() {
        FeatureFlag flag = new FeatureFlag();
        ProviderMock provider = new ProviderMock();
        flag.setProvider(provider);
        Assert.areEqual(FeatureFlagReason.APEX_ENABLED, flag.getReason(), 'Incorrect reason.');
        Assert.isTrue(flag.isEnabled(), 'Incorrect isEnabled.');
    }

    @IsTest
    static void namedFlagIsDisabledByDefault() {
        String featureName = 'test';
        FeatureFlag flag = new FeatureFlag(featureName);
        ProviderMock provider = new ProviderMock();
        flag.setProvider(provider);
        Assert.areEqual(FeatureFlagReason.FLAG_NOT_FOUND, flag.getReason(), 'Incorrect reason.');
        Assert.isFalse(flag.isEnabled(), 'Incorrect isEnabled.');
    }

    @IsTest
    static void namedFlagIsMocked() {
        String featureName = 'test';
        FeatureFlag flag = new FeatureFlag(featureName);
        ProviderMock provider = new ProviderMock();
        flag.setProvider(provider);
        flag.setMockValue(true);
        Assert.areEqual(FeatureFlagReason.MOCK_ENABLED, flag.getReason(), 'Incorrect reason.');
        Assert.isTrue(flag.isEnabled(), 'Incorrect isEnabled.');
        flag.clearMockValue();
        Assert.areEqual(FeatureFlagReason.FLAG_NOT_FOUND, flag.getReason(), 'Incorrect reason.');
        Assert.isFalse(flag.isEnabled(), 'Incorrect isEnabled.');
        flag.setMockValue(false);
        Assert.areEqual(FeatureFlagReason.MOCK_DISABLED, flag.getReason(), 'Incorrect reason.');
        Assert.isFalse(flag.isEnabled(), 'Incorrect isEnabled.');
    }

    @IsTest
    static void namedFlagHasApexOverride() {
        String featureName = 'test';
        FeatureFlag flag = new FeatureFlag(featureName);
        ProviderMock provider = new ProviderMock();
        flag.setProvider(provider);
        flag.setValue(true);
        Assert.areEqual(FeatureFlagReason.APEX_ENABLED, flag.getReason(), 'Incorrect reason.');
        Assert.isTrue(flag.isEnabled(), 'Incorrect isEnabled.');
        flag.clearValue();
        Assert.areEqual(FeatureFlagReason.FLAG_NOT_FOUND, flag.getReason(), 'Incorrect reason.');
        Assert.isFalse(flag.isEnabled(), 'Incorrect isEnabled.');
        flag.setValue(false);
        Assert.areEqual(FeatureFlagReason.APEX_DISABLED, flag.getReason(), 'Incorrect reason.');
        Assert.isFalse(flag.isEnabled(), 'Incorrect isEnabled.');
    }

    @IsTest
    static void namedFlagHasCustomPermission() {
        String featureName = 'test';
        FeatureFlag flag = new FeatureFlag(featureName);
        ProviderMock provider = new ProviderMock();
        flag.setProvider(provider);
        provider.customPermissionNames.add(featureName);
        provider.customPermissionNames.add(featureName + 'Disabled');
        Assert.areEqual(FeatureFlagReason.FLAG_NOT_FOUND, flag.getReason(), 'Incorrect reason.');
        Assert.isFalse(flag.isEnabled(), 'Incorrect isEnabled.');
        provider.assignedPermissions.add(featureName);
        Assert.areEqual(FeatureFlagReason.CUSTOM_PERMISSION_ENABLED, flag.getReason(), 'Incorrect reason.');
        Assert.isTrue(flag.isEnabled(), 'Incorrect isEnabled.');
        provider.assignedPermissions.add(featureName + 'Disabled');
        Assert.areEqual(FeatureFlagReason.CUSTOM_PERMISSION_DISABLED, flag.getReason(), 'Incorrect reason.');
        Assert.isFalse(flag.isEnabled(), 'Incorrect isEnabled.');
    }

    @IsTest
    static void namedFlagWithEnabledMetadata() {
        String featureName = 'test';
        FeatureFlag flag = new FeatureFlag(featureName);
        ProviderMock provider = new ProviderMock();
        flag.setProvider(provider);
        provider.features.put(featureName, new FeatureFlag__mdt(Is_Active__c = false));
        Assert.areEqual(FeatureFlagReason.CUSTOM_METADATA_TYPE_DISABLED, flag.getReason(), 'Incorrect reason.');
        Assert.isFalse(flag.isEnabled(), 'Incorrect isEnabled.');
    }

    @IsTest
    static void namedFlagWithDisabledMetadata() {
        String featureName = 'test';
        FeatureFlag flag = new FeatureFlag(featureName);
        ProviderMock provider = new ProviderMock();
        flag.setProvider(provider);
        provider.features.put(featureName, new FeatureFlag__mdt(Is_Active__c = true));
        Assert.areEqual(FeatureFlagReason.CUSTOM_METADATA_TYPE_ENABLED, flag.getReason(), 'Incorrect reason.');
        Assert.isTrue(flag.isEnabled(), 'Incorrect isEnabled.');
    }

    @IsTest
    static void namedFlagWithEnabledMetadataHasDisabledCustomPermission() {
        String featureName = 'test';
        FeatureFlag flag = new FeatureFlag(featureName);
        ProviderMock provider = new ProviderMock();
        flag.setProvider(provider);
        provider.features.put(featureName, new FeatureFlag__mdt(Is_Active__c = true));
        provider.customPermissionNames.add(featureName);
        provider.customPermissionNames.add(featureName + 'Disabled');
        provider.assignedPermissions.add(featureName + 'Disabled');
        Assert.areEqual(FeatureFlagReason.CUSTOM_PERMISSION_DISABLED, flag.getReason(), 'Incorrect reason.');
        Assert.isFalse(flag.isEnabled(), 'Incorrect isEnabled.');
    }

    @IsTest
    static void providerConsumesLimits() {
        FeatureFlagProvider provider = new FeatureFlagProvider();
        Assert.isNotNull(provider.getCustomPermissionNames(), 'Permissions not queried.');
        Assert.isNotNull(provider.getCustomPermissionNames(), 'Permissions not queried.');
        Assert.isNotNull(provider.getFeatureFlags(), 'Feature flag metadata not queried.');
        Assert.isNotNull(provider.getFeatureFlags(), 'Feature flag metadata not queried.');
        Assert.isFalse(provider.checkPermission('NON_EXISTENT_FEATURE'), 'Non existent permission was granted.');
        // 1 query expected for CustomPermission
        Assert.areEqual(1, Limits.getQueries(), 'Different number of queries is expected.');
    }

    private class ProviderMock extends FeatureFlagProvider {
        private final Set<String> assignedPermissions = new Set<String>();
        private final Set<String> customPermissionNames = new Set<String>();
        private final Map<String, FeatureFlag__mdt> features = new Map<String, FeatureFlag__mdt>();

        public override Boolean checkPermission(String featureName) {
            return assignedPermissions.contains(featureName);
        }

        public override Set<String> getCustomPermissionNames() {
            return customPermissionNames;
        }

        public override Map<String, FeatureFlag__mdt> getFeatureFlags() {
            return features;
        }
    }
}