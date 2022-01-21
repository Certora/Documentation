(WIP)

In the last section, we presented the idea of ghosts for proving the invariant:

(function(){ var data = { "addon\_key":"orah-latex", "uniqueKey":"orah-latex\_\_orah-latex5985816629803891909", "key":"orah-latex", "moduleType":"dynamicContentMacros", "moduleLocation":"content", "cp":"/wiki", "general":"", "w":"", "h":"", "url":"https://content-formatting.connect.apps.adaptavist.com/macro/latex/latex.html", "contextJwt": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI2MGZjMjVkNzhiMWE5YjAwNmYxNmFiZDAiLCJxc2giOiJjb250ZXh0LXFzaCIsImlzcyI6ImYwN2NmMjQ2LTk5NTktMzcyZS1hZTM0LTNmNWZhOTY3Nzk3YSIsImNvbnRleHQiOnsibGljZW5zZSI6eyJhY3RpdmUiOnRydWV9LCJjb25mbHVlbmNlIjp7ImVkaXRvciI6eyJ2ZXJzaW9uIjoiXCJ2MlwiIn0sIm1hY3JvIjp7Im91dHB1dFR5cGUiOiJodG1sX2V4cG9ydCIsImhhc2giOiIxZmYyOGVhNS1kNzg2LTRiZTItODQyMC1iMDBhZDhjODRiZDMiLCJpZCI6IjFmZjI4ZWE1LWQ3ODYtNGJlMi04NDIwLWIwMGFkOGM4NGJkMyJ9LCJjb250ZW50Ijp7InR5cGUiOiJwYWdlIiwidmVyc2lvbiI6IjMiLCJpZCI6IjQxMTI0MjkxIn0sInNwYWNlIjp7ImtleSI6IkNQRCIsImlkIjoiMjkxNjUyNSJ9fX0sImV4cCI6MTY0Mjc3ODE0MSwiaWF0IjoxNjQyNzc3MjQxfQ.8CHPdWn3TpNpnyP9CpRgCSE1j97dp4F573hvZDewEHM", "structuredContext": "{\\"license\\":{\\"active\\":true},\\"confluence\\":{\\"editor\\":{\\"version\\":\\"\\\\\\"v2\\\\\\"\\"},\\"macro\\":{\\"outputType\\":\\"html\_export\\",\\"hash\\":\\"1ff28ea5-d786-4be2-8420-b00ad8c84bd3\\",\\"id\\":\\"1ff28ea5-d786-4be2-8420-b00ad8c84bd3\\"},\\"content\\":{\\"type\\":\\"page\\",\\"version\\":\\"3\\",\\"id\\":\\"41124291\\"},\\"space\\":{\\"key\\":\\"CPD\\",\\"id\\":\\"2916525\\"}}}", "contentClassifier":"content", "productCtx":"{\\"page.id\\":\\"41124291\\",\\"macro.hash\\":\\"1ff28ea5-d786-4be2-8420-b00ad8c84bd3\\",\\"space.key\\":\\"CPD\\",\\"user.id\\":\\"60fc25d78b1a9b006f16abd0\\",\\"page.type\\":\\"page\\",\\"content.version\\":\\"3\\",\\"page.title\\":\\"Verification with ghosts\\",\\"macro.localId\\":\\"\\",\\"macro.body\\":\\"$$\\\\n\\\\\\\\forall x. (map(x) \\\\\\\\neq 0 \\\\\\\\iff \\\\\\\\exists i. 0\\\\\\\\leq i \\\\\\\\leq keys.length \\\\\\\\land keys\[i\]=x)\\\\n$$\\",\\": = | RAW | = :\\":null,\\"space.id\\":\\"2916525\\",\\"macro.truncated\\":\\"false\\",\\"content.type\\":\\"page\\",\\"output.type\\":\\"html\_export\\",\\"page.version\\":\\"3\\",\\"user.key\\":\\"8a7f808a7ad469f9017ad8f4037a0390\\",\\"content.id\\":\\"41124291\\",\\"macro.id\\":\\"1ff28ea5-d786-4be2-8420-b00ad8c84bd3\\",\\"editor.version\\":\\"\\\\\\"v2\\\\\\"\\"}", "timeZone":"US/Eastern", "origin":"https://content-formatting.connect.apps.adaptavist.com", "hostOrigin":"https://certora.atlassian.net", "sandbox":"allow-downloads allow-forms allow-modals allow-popups allow-scripts allow-same-origin allow-top-navigation-by-user-activation allow-storage-access-by-user-activation", "apiMigrations": { "gdpr": true } } ; if(window.AP && window.AP.subCreate) { window.\_AP.appendConnectAddon(data); } else { require(\['ac/create'\], function(create){ create.appendConnectAddon(data); }); } }());

‌And we have already defined a ghost for the underlying map:

```java
ghost _map(uint) returns uint;
```

‌with the hooks:

```java
hook Sload uint v map[KEY uint k] STORAGE {
    require _map(k) == v;
}

hook Sstore map[KEY uint k] uint v STORAGE {
    havoc _map assuming _map@new(k) == v &&
        (forall uint k2. k2 != k => _map@new(k2) == _map@old(k2));
}
```

‌We continue with defining two additional ghosts: one capturing the length of the array, and the second for remembering the elements of the array:

```java
ghost array(uint) returns uint;ghost arrayLen() returns uint;
```

‌We also define the hooks. For `array`:

```java
hook Sload uint n keys[INDEX uint index] STORAGE {
    require array(index) == n;
}

hook Sstore keys[INDEX uint index] uint n STORAGE {
    havoc array assuming array@new(index) == n &&
        (forall uint i. i != index => array@new(i) == array@old(i));
}
```

‌For `arrayLen`:

```java
hook Sstore keys uint lenNew STORAGE {
    // the length of a solidity storage array is at the variable's slot
    havoc arrayLen assuming arrayLen@new() == lenNew;
}
```