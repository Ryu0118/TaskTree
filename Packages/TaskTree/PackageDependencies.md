```mermaid
graph TD;
    AppFeature-->TaskTreeFeature;
    TodoClient-->SwiftDataModel;
    TodoClient-->SwiftDataUtils;
    TaskTreeFeature-->TodoClient;
    TaskTreeFeature-->Utils;
    TaskTreeFeature-->SettingFeature;
    SettingFeature-->Generated;
    TaskTreeTests-->AppFeature;
```