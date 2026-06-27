.pragma library

var radiusAmount = 0.5
var radiusSmall = 8
var radiusMedium = 16
var radiusLarge = 24
var radiusExtraLarge = 32

var spacingSmall = 8
var spacingMedium = 16
var spacingLarge = 24

var paddingSmall = 8
var paddingMedium = 16
var paddingLarge = 24

var fontFamily = "Rubik"
var m3Expressive = [0.05, 0.7, 0.5, 1.0]

function levenshtein(a, b) {
    if (a.length === 0) return b.length;
    if (b.length === 0) return a.length;
    var matrix = [];
    for (var i = 0; i <= b.length; i++) matrix[i] = [i];
    for (var j = 0; j <= a.length; j++) matrix[0][j] = j;
    for (var i = 1; i <= b.length; i++) {
        for (var j = 1; j <= a.length; j++) {
            if (b.charAt(i - 1) === a.charAt(j - 1)) {
                matrix[i][j] = matrix[i - 1][j - 1];
            } else {
                matrix[i][j] = Math.min(
                    matrix[i - 1][j - 1] + 1,
                    Math.min(matrix[i][j - 1] + 1, matrix[i - 1][j] + 1)
                );
            }
        }
    }
    return matrix[b.length][a.length];
}

function fuzzyMatch(pattern, str) {
    pattern = pattern.toLowerCase();
    str = str.toLowerCase();
    if (pattern === "") return true;
    
    if (str.indexOf(pattern) !== -1) return true;
    
    var patternIdx = 0;
    for (var i = 0; i < str.length && patternIdx < pattern.length; i++) {
        if (str[i] === pattern[patternIdx]) patternIdx++;
    }
    if (patternIdx === pattern.length) return true;
    
    var allowedTypos = Math.min(2, Math.floor(pattern.length / 3));
    if (pattern.length < 3) return false;

    var minDistance = pattern.length;
    for (var i = 0; i <= str.length - pattern.length; i++) {
        var sub = str.substr(i, pattern.length);
        var dist = levenshtein(pattern, sub);
        if (dist < minDistance) minDistance = dist;
    }
    
    if (Math.abs(str.length - pattern.length) <= allowedTypos) {
        var distWhole = levenshtein(pattern, str);
        if (distWhole < minDistance) minDistance = distWhole;
    }
    
    return minDistance <= allowedTypos;
}

var notificationHistory = [];
var historyUpdated = 0;

function pushNotification(modelData) {
    console.log("pushNotification called! modelData:", modelData);
    if (!modelData) {
        console.log("ERROR: modelData is null or undefined");
        return;
    }
    
    // Fallback to id if seqId is undefined
    var uniqueId = modelData.seqId !== undefined ? modelData.seqId : (modelData.id !== undefined ? modelData.id : Math.random());
    console.log("Notification uniqueId:", uniqueId);

    for (var i = 0; i < notificationHistory.length; i++) {
        if (notificationHistory[i].seqId === uniqueId) {
            console.log("Duplicate notification prevented:", uniqueId);
            return;
        }
    }
    
    var actionsArray = [];
    if (modelData.actions) {
        for (var j = 0; j < modelData.actions.length; j++) {
            actionsArray.push({
                identifier: modelData.actions[j].identifier,
                text: modelData.actions[j].text
            });
        }
    }
    
    var n = {
        seqId: uniqueId,
        appName: modelData.appName,
        appIcon: modelData.appIcon,
        summary: modelData.summary,
        body: modelData.body,
        image: modelData.image,
        urgency: modelData.urgency,
        actions: actionsArray,
        expireTimeout: modelData.expireTimeout,
        defaultTimeout: modelData.defaultTimeout,
        invokeAction: function(id) {
            try { modelData.invokeAction(id); } catch(e) {}
        },
        dismiss: function() {
            try { modelData.dismiss(); } catch(e) {}
            removeNotification(this.seqId);
        }
    };
    
    notificationHistory.unshift(n);
    historyUpdated++;
    console.log("Notification pushed successfully! History size:", notificationHistory.length);
}

function removeNotification(seqId) {
    var initialLen = notificationHistory.length;
    notificationHistory = notificationHistory.filter(function(n) { return n.seqId !== seqId; });
    if (notificationHistory.length !== initialLen) {
        historyUpdated++;
    }
}

function clearNotifications() {
    notificationHistory = [];
    historyUpdated++;
}