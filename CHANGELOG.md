## Change Log

### v0.2.9 (2020/2/17)
- Fixed the ordering of the message_subject argument for the incident/maintenance methods which was breaking backwards compatibility

### v0.2.8 (2020/2/14)
- Fix silent parameter type

### v0.2.7 (2020/2/10)
- Adding message_subject to all incident and maintenance methods

### v0.2.6 (2019/3/26)
- Force rest-client gem to be version 1.8.0

### v0.2.5 (2018/11/28)
- Changed variables to proper type (int->str)

### v0.2.4 (2018/2/9)
- Support retrieving single incident/maintenance events. New incident/maintenance methods to fetch list of IDs
- Change /component/status/update to use a single component

### v0.2.3 (2017/12/20)
- Updated incident/create to handle infrastructure_affected combo

### v0.2.2 (2017/12/14)
- Updated maintenance/schedule to handle infrastructure_affected combos

### v0.1.0 (2016/1/19)
- Initial release
