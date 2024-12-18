
const conf = {
    fred: {}
}

function initConfiguration(configuration) {
    Object.assign(conf.fred, configuration);
}

module.exports = {conf, initConfiguration};