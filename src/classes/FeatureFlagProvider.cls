/*
 * BSD 3-Clause License
 * https://github.com/kratapps/feature-flag/blob/main/LICENSE
 */

/**
 * @description Feature Flag Provider.
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
public virtual with sharing class FeatureFlagProvider {
    private Set<String> customPermissionNames;
    private Map<String, FeatureFlag__mdt> features;

    public virtual Boolean checkPermission(String featureName) {
        return FeatureManagement.checkPermission(featureName);
    }

    @SuppressWarnings('PMD.apexcrudviolation')
    public virtual Set<String> getCustomPermissionNames() {
        if (customPermissionNames == null) {
            customPermissionNames = new Set<String>();
            List<CustomPermission> perms = [SELECT Id, DeveloperName FROM CustomPermission];
            for (CustomPermission perm : perms) {
                customPermissionNames.add(perm.DeveloperName);
            }
        }
        return customPermissionNames;
    }

    public virtual Map<String, FeatureFlag__mdt> getFeatureFlags() {
        if (features == null) {
            features = FeatureFlag__mdt.getAll();
        }
        return features;
    }
}