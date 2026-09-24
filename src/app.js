(function () {
    "use strict";

    // Приложение выводит в консоль сведения о сборке, подставленные на этапе Build.
    var info = {
        version: document.getElementById("version").textContent,
        build:   document.getElementById("build").textContent,
        date:    document.getElementById("date").textContent,
        env:     document.getElementById("env").textContent
    };

    console.log("DevOps CI Demo", info);
})();
