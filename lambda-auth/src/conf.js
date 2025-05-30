
const conf = {
    ad: {
        serviceAccountsBase: 'ou=serviceaccounts,ou=ops,ou=nci,ou=nih,ou=ad,dc=nih,dc=gov',
        userAccountsBase: 'ou=Users,ou=NCI,ou=NIH,ou=AD,dc=nih,dc=gov',
    },
    auth: {}
};

function initConfiguration(configuration) {
    conf.ad.cert = configuration.ad_cert;
    conf.ad.host = configuration.ad_auth_host;
}

function initAuthConfiguration(configuration) {
    Object.assign(conf.auth, configuration);
}

module.exports = { conf, initConfiguration, initAuthConfiguration };
