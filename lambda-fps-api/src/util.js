
function convertParametersToJson(data, prefix) {
    const result = {};
    data.Parameters.forEach((p) => {
        let paths = p.Name.slice(prefix.length).split('/');
        let tempResult = result;
        for (let i = 0; i < paths.length - 1; i++) {
            if (typeof tempResult[paths[i]] === 'undefined') {
                tempResult[paths[i]] = {};
            }
            tempResult = tempResult[paths[i]];
        }
        tempResult[paths[paths.length - 1]] = p.Value;
    });
    console.debug('Parameters:', result);
    return result;
}

module.exports = { convertParametersToJson };