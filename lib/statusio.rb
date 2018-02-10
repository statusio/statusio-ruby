require 'rubygems' if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'ruby' && RUBY_VERSION < '1.9'
require 'statusio/rb/version'
require 'rest-client'
require 'uri'
require 'json'

class StatusioClient

  class Error < StandardError; end

  STATUS_OPERATIONAL = 100
  STATUS_DEGRADED_PERFORMANCE = 300
  STATUS_PARTIAL_SERVICE_DISRUPTION = 400
  STATUS_SERVICE_DISRUPTION = 500
  STATUS_SECURITY_EVENT = 600

  STATE_INVESTIGATING = 100
  STATE_IDENTIFIED = 200
  STATE_MONITORING = 300

  NOTIFY_EMAIL = 1
  NOTIFY_SMS = 2
  NOTIFY_WEBHOOK = 4
  NOTIFY_SOCIAL = 8
  NOTIFY_IRC = 16
  NOTIFY_HIPCHAT = 32
  NOTIFY_SLACK = 64

  def initialize(api_key, api_id)
    @api_key = api_key
    @api_id = api_id

    @url = 'https://api.status.io/v2/'

    @headers = {
      'x-api-id' => @api_id,
      'x-api-key' => @api_key,
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  private

  def get_notify(notifications)
    notify = {
      'notify_email' => '0',
      'notify_sms' => '0',
      'notify_webhook' => '0',
      'social' => '0',
      'irc' => '0',
      'hipchat' => '0',
      'slack' => '0'
    }

    if notifications & NOTIFY_EMAIL == NOTIFY_EMAIL
      notify['notify_email'] = '1'
    end

    if notifications & NOTIFY_SMS == NOTIFY_SMS
      notify['notify_sms'] = '1'
    end

    if notifications & NOTIFY_WEBHOOK == NOTIFY_WEBHOOK
      notify['notify_webhook'] = '1'
    end

    if notifications & NOTIFY_SOCIAL == NOTIFY_SOCIAL
      notify['social'] = '1'
    end

    if notifications & NOTIFY_IRC == NOTIFY_IRC
      notify['irc'] = '1'
    end

    if notifications & NOTIFY_HIPCHAT == NOTIFY_HIPCHAT
      notify['hipchat'] = '1'
    end

    if notifications & NOTIFY_SLACK == NOTIFY_SLACK
      notify['slack'] = '1'
    end

    return notify
  end

  def request(params)
    response = RestClient::Request.execute(params.merge(:headers => @headers))
    body = JSON.parse(response.body)
    
    if body['status'] && body['status']['error'] == 'yes'
      raise StatusioClient::Error, body['status']['message']
    elsif response.code == 200
      return body
    else
      raise Net::HTTPError, response.inspect
    end
  end

  public

  ##
  # List all components.
  #
  # @param statuspage_id(string) Status page ID
  # @return object

  def component_list(statuspage_id)
    request :method  => :get,
            :url     => @url + 'component/list/' + statuspage_id
  end

  ##
  # Update the status of a component on the fly without creating an incident or maintenance.
  #
  # @param statuspage_id(string) string Status page ID
  # @param component(string) ID of affected component
  # @param container(string) ID of affected container
  # @param details(string) A brief message describing this update
  # @param current_status(int) Any numeric status code.
  # @return object

  def component_status_update(statuspage_id, component, container, details, current_status)
    request :method  => :post,
            :url     => @url + 'component/status/update',
            :payload => {
              'statuspage_id'  => statuspage_id,
              'component'     => component,
              'container'     => container,
              'details'        => details,
              'current_status' => current_status
            }
  end

  # INCIDENT

  ##
  # List all active and resolved incidents.
  #
  # @param statuspage_id(string) Status page ID
  # @return object

  def incident_list(statuspage_id)
    request :method  => :get,
            :url     => @url + 'incident/list/' + statuspage_id
  end

  ##
  # List all active and resolved incidents by ID.
  #
  # @param statuspage_id(string) Status page ID
  # @return object

  def incident_list_by_id(statuspage_id)
    request :method  => :get,
            :url     => @url + 'incidents/' + statuspage_id
  end

  ##
  # Display incident message.
  #
  # @param  statuspage_id(string) Status page ID
  # @param message_id(string) Message ID
  # @return object

  def incident_message(statuspage_id, message_id)
    request :method  => :get,
            :url     => @url + 'incident/message/' + statuspage_id + '/' + message_id
  end

  ##
  # Get single incident.
  #
  # @param  statuspage_id(string) Status page ID
  # @param incident_id(string) Incident ID
  # @return object

  def incident_single(statuspage_id, incident_id)
    request :method  => :get,
            :url     => @url + 'incident/' + statuspage_id + '/' + incident_id
  end

  ##
  # Create a new incident.
  #
  # @param statuspage_id(string) Status page ID
  # @param incident_name(string) A descriptive title for the incident
  # @param incident_details(string) Message describing this incident
  # @param infrastructure_affected(array) ID of each affected component and container combo
  # @param current_status(int) The status of the components and containers affected by this incident (StatusioClient::STATUS_#).
  # @param current_state(int) The state of this incident (StatusioClient::STATE_#).
  # @param notifications(int) Bitmasked notifications (StatusioClient::NOTIFY_#). To use multiple just add them up (ie StatusioClient::NOTIFY_SMS + StatusioClient::NOTIFY_SLACK).
  # @param all_infrastructure_affected(int) Affect all components and containers (default = 0)
  # @return object

  def incident_create(statuspage_id, incident_name, incident_details, infrastructure_affected, current_status, current_state, notifications = 0, all_infrastructure_affected = 0)
    data = get_notify(notifications)
    data['statuspage_id'] = statuspage_id
    data['incident_name'] = incident_name
    data['incident_details'] = incident_details
    data['infrastructure_affected'] = infrastructure_affected
    data['current_status'] = current_status
    data['current_state'] = current_state
    data['all_infrastructure_affected'] = all_infrastructure_affected

    request :method  => :post,
    	      :url     => @url + 'incident/create',
    	      :payload => data
  end

  ##
  # Update an existing incident
  #
  # @param statuspage_id(string) Status page ID
  # @param incident_id(string) Incident ID
  # @param incident_details(string) Message describing this incident
  # @param current_status(int) The status of the components and containers affected by this incident (StatusioClient::STATUS_#).
  # @param current_state(int) The state of this incident (StatusioClient::STATE_#).
  # @param notifications(int) Bitmasked notifications (StatusioClient::NOTIFY_#). To use multiple just add them up (ie StatusioClient::NOTIFY_SMS + StatusioClient::NOTIFY_SLACK).
  # @return object

  def incident_update(statuspage_id, incident_id, incident_details, current_status, current_state, notifications = 0)
    data = get_notify(notifications)
    data['statuspage_id'] = statuspage_id
    data['incident_id'] = incident_id
    data['incident_details'] = incident_details
    data['current_status'] = current_status
    data['current_state'] = current_state

    request :method  => :post,
            :url     => @url + 'incident/update',
            :payload => data
  end

  ##
  # Resolve an existing incident. The incident will be shown in the history instead of on the main page.
  #
  # @param statuspage_id(string) Status page ID
  # @param incident_id(string) Incident ID
  # @param incident_details(string) Message describing this incident
  # @param current_status(int) The status of the components and containers affected by this incident (StatusioClient::STATUS_#).
  # @param current_state(int) The state of this incident (StatusioClient::STATE_#).
  # @param notifications(int) Bitmasked notifications (StatusioClient::NOTIFY_#). To use multiple just add them up (ie StatusioClient::NOTIFY_SMS + StatusioClient::NOTIFY_SLACK).
  # @return object

  def incident_resolve(statuspage_id, incident_id, incident_details, current_status, current_state, notifications = 0)
    data = get_notify(notifications)
    data['statuspage_id'] = statuspage_id
    data['incident_id'] = incident_id
    data['incident_details'] = incident_details
    data['current_status'] = current_status
    data['current_state'] =current_state

    request :method  => :post,
            :url     => @url + 'incident/resolve',
            :payload => data
  end

  ##
  # Delete an existing incident. The incident will be deleted forever and cannot be recovered.
  #
  # @param statuspage_id(string) Status page ID
  # @param incident_id(string) Incident ID
  # @return object

  def incident_delete(statuspage_id, incident_id)
    data = {}
    data['statuspage_id'] = statuspage_id
    data['incident_id'] = incident_id

    request :method  => :post,
            :url     => @url + 'incident/delete',
            :payload => data
  end

  # MAINTENANCE

  ##
  # List all active, resolved and upcoming maintenances
  #
  # @param statuspage_id(string) Status page ID
  # @return object
  #/

  def maintenance_list(statuspage_id)
    request :method => :get,
            :url    => @url + 'maintenance/list/' + statuspage_id
  end

  ##
  # List all active, resolved and upcoming maintenances by ID
  #
  # @param statuspage_id(string) Status page ID
  # @return object
  #/

  def maintenance_list_by_id(statuspage_id)
    request :method => :get,
            :url    => @url + 'maintenances/' + statuspage_id
  end

  ##
  # Display maintenance message
  #
  # @param statuspage_id(string) Status page ID
  # @param message_id(string) Message ID
  # @return object

  def maintenance_message(statuspage_id, message_id)
    request :method  => :get,
            :url     => @url + 'maintenance/message/' + statuspage_id + '/' + message_id
  end

  ##
  # Get single maintenance
  #
  # @param statuspage_id(string) Status page ID
  # @param maintenance_id(string) Maintenance ID
  # @return object

  def maintenance_single(statuspage_id, maintenance_id)
    request :method  => :get,
            :url     => @url + 'maintenance/' + statuspage_id + '/' + maintenance_id
  end

  ##
  # Schedule a new maintenance
  #
  # @param statuspage_id(string) Status page ID
  # @param maintenance_name(string) A descriptive title for this maintenance
  # @param maintenance_details(string) Message describing this maintenance
  # @param infrastructure_affected(array) ID of each affected component and container combo
  # @param date_planned_start(string) Date maintenance is expected to start
  # @param time_planned_start(string) Time maintenance is expected to start
  # @param date_planned_end(string) Date maintenance is expected to end
  # @param time_planned_end(string) Time maintenance is expected to end
  # @param automation(int) Automatically start and end the maintenance (default = 0)
  # @param all_infrastructure_affected(int) Affect all components and containers (default = 0)
  # @param maintenance_notify_now(int) Notify subscribers now (1 = Send notification)
  # @param maintenance_notify_1_hr(int) Notify subscribers 1 hour before scheduled maintenance start time (1 = Send notification)
  # @param maintenance_notify_24_hr(int) Notify subscribers 24 hours before scheduled maintenance start time (1 = Send notification)
  # @param maintenance_notify_72_hr(int) Notify subscribers 72 hours before scheduled maintenance start time (1 = Send notification)
  # @return object

  def maintenance_schedule(statuspage_id, maintenance_name, maintenance_details, infrastructure_affected,
                           date_planned_start, time_planned_start, date_planned_end, time_planned_end,
                           automation = 0, all_infrastructure_affected = 0,
                           maintenance_notify_now = 0, maintenance_notify_1_hr = 0,
                           maintenance_notify_24_hr = 0, maintenance_notify_72_hr = 0)
    data = {}
    data['statuspage_id'] = statuspage_id
    data['maintenance_name'] = maintenance_name
    data['maintenance_details'] = maintenance_details
    data['infrastructure_affected'] = infrastructure_affected
    data['all_infrastructure_affected'] = all_infrastructure_affected
    data['date_planned_start'] = date_planned_start
    data['time_planned_start'] = time_planned_start
    data['date_planned_end'] = date_planned_end
    data['time_planned_end'] = time_planned_end
    data['automation'] = automation
    data['maintenance_notify_now'] = maintenance_notify_now
    data['maintenance_notify_1_hr'] = maintenance_notify_1_hr
    data['maintenance_notify_24_hr'] = maintenance_notify_24_hr
    data['maintenance_notify_72_hr'] = maintenance_notify_72_hr

    request :method  => :post,
            :url     => @url + 'maintenance/schedule',
            :payload => data
  end

  ##
  # Begin a scheduled maintenance now
  #
  # @param statuspage_id(string) Status page ID
  # @param maintenance_id(string) Maintenance ID
  # @param maintenance_details(string) Message describing this maintenance update
  # @param notifications(int) Bitmasked notifications (StatusioClient::NOTIFY_#). To use multiple just add them up (ie StatusioClient::NOTIFY_SMS + StatusioClient::NOTIFY_SLACK).
  # @return object

  def maintenance_start(statuspage_id, maintenance_id, maintenance_details, notifications = 0)
    data = get_notify(notifications)
    data['statuspage_id'] = statuspage_id
    data['maintenance_id'] = maintenance_id
    data['maintenance_details'] = maintenance_details

    request :method  => :post,
            :url     => @url + 'maintenance/start',
            :payload => data
  end

  ##
  # Update an active maintenance
  #
  # @param statuspage_id(string) Status page ID
  # @param maintenance_id(string) Maintenance ID
  # @param maintenance_details(string) Message describing this maintenance
  # @param notifications(int) Bitmasked notifications (StatusioClient::NOTIFY_#). To use multiple just add them up (ie StatusioClient::NOTIFY_SMS + StatusioClient::NOTIFY_SLACK).
  # @return object

  def maintenance_update(statuspage_id, maintenance_id, maintenance_details, notifications = 0)
    data = get_notify(notifications)
    data['statuspage_id'] = statuspage_id
    data['maintenance_id'] = maintenance_id
    data['maintenance_details'] = maintenance_details

    request :method  => :post,
            :url     => @url + 'maintenance/update',
            :payload => data
  end

  ##
  # Close an active maintenance. The maintenance will be moved to the history.
  #
  # @param statuspage_id(string) Status page ID
  # @param maintenance_id(string) Maintenance ID
  # @param maintenance_details(string) Message describing this maintenance
  # @param notifications(int) Bitmasked notifications (StatusioClient::NOTIFY_#). To use multiple just add them up (ie StatusioClient::NOTIFY_SMS + StatusioClient::NOTIFY_SLACK).
  # @return object

  def maintenance_finish(statuspage_id, maintenance_id, maintenance_details, notifications = 0)
    data = get_notify(notifications)
    data['statuspage_id'] = statuspage_id
    data['maintenance_id'] = maintenance_id
    data['maintenance_details'] = maintenance_details

    request :method  => :post,
            :url     => @url + 'maintenance/finish',
            :payload => data
  end

  ##
  # Delete an existing maintenance. The maintenance will be deleted forever and cannot be recovered.
  #
  # @param statuspage_id(string) Status page ID
  # @param maintenance_id(string) Maintenance ID
  # @return object
  #/
  def maintenance_delete(statuspage_id, maintenance_id)
    data = {}
    data['statuspage_id'] = statuspage_id
    data['maintenance_id'] = maintenance_id

    request :method  => :post,
            :url     => @url + 'maintenance/delete',
            :payload => data
  end

  # METRIC

  ##
  # Update custom metric data
  #
  # @param statuspage_id(string) Status page ID
  # @param metric_id(string) Metric ID
  # @param day_avg(float) Average value for past 24 hours
  # @param day_start(int) UNIX timestamp for start of metric timeframe
  # @param day_dates(array) An array of timestamps for the past 24 hours (2014-03-28T05:43:00+00:00)
  # @param day_values(array) An array of values matching the timestamps (Must be 24 values)
  # @param week_avg(float) Average value for past 7 days
  # @param week_start(int) UNIX timestamp for start of metric timeframe
  # @param week_dates(array) An array of timestamps for the past 7 days (2014-03-28T05:43:00+00:00)
  # @param week_values(array) An array of values matching the timestamps (Must be 7 values)
  # @param month_avg(float) Average value for past 30 days
  # @param month_start(int) UNIX timestamp for start of metric timeframe
  # @param month_dates(array) An array of timestamps for the past 30 days (2014-03-28T05:43:00+00:00)
  # @param month_values(array) An array of values matching the timestamps (Must be 30 values)
  # @return object

  def metric_update(statuspage_id, metric_id, day_avg, day_start, day_dates, day_values,
                    week_avg, week_start, week_dates, week_values,
                    month_avg, month_start, month_dates, month_values)
    data = {}
    data['statuspage_id'] = statuspage_id
    data['metric_id'] = metric_id
    data['day_avg'] = day_avg
    data['day_start'] = day_start
    data['day_dates'] = day_dates
    data['day_values'] = day_values
    data['week_avg'] = week_avg
    data['week_start'] = week_start
    data['week_dates'] = week_dates
    data['week_values'] =week_values
    data['month_avg'] = month_avg
    data['month_start'] = month_start
    data['month_dates'] = month_dates
    data['month_values'] = month_values

    request :method  => :post,
            :url     => @url + 'metric/update',
            :payload => data
  end

  # STATUS

  ##
  # Show the summary status for all components and containers
  #
  # @param statuspage_id(string) Status page ID
  # @return object

  def status_summary(statuspage_id)
      request :method => :get,
              :url    => @url + 'status/summary/' + statuspage_id
  end

  # SUBSCRIBER

  ##
  # List all subscribers
  #
  # @param statuspage_id(string) Status page ID
  # @return object

  def subscriber_list(statuspage_id)
    request :method => :get,
            :url => @url + 'subscriber/list/' + statuspage_id
  end

  ##
  # Add a new subscriber
  #
  # @param statuspage_id(string) Status page ID
  # @param method(string) Communication method of subscriber. Valid methods are `email`, `sms` or `webhook`
  # @param address(string) Subscriber address (SMS number must include country code ie. +1)
  # @param silent(int) Supress the welcome message (1 = Do not send notification)
  # @param granular(string) List of component_container combos
  # @return object

  def subscriber_add(statuspage_id, method, address, silent = 1, granular = '')
    data = {}
    data['statuspage_id'] = statuspage_id
    data['method'] = method
    data['address'] = address
    data['silent'] = silent
    data['granular'] = granular

    request :method  => :post,
            :url     => @url + 'subscriber/add',
            :payload => data
  end

  ##
  # Update existing subscriber
  #
  # @param statuspage_id(string) Status page ID
  # @param subscriber_id(string) Subscriber ID
  # @param address(string) Subscriber address (SMS number must include country code ie. +1)
  # @param granular(string) List of component_container combos
  # @return object

  def subscriber_update(statuspage_id, subscriber_id, address, granular = '')
    data = {}
    data['statuspage_id'] = statuspage_id
    data['subscriber_id'] = subscriber_id
    data['address'] = address
    data['granular'] = granular

    request :method  => :patch,
            :url     => @url + 'subscriber/update',
            :payload => data
  end

  ##
  # Delete subscriber
  #
  # @param statuspage_id(string) Status page ID
  # @param subscriber_id(string) Subscriber ID
  # @return object

  def subscriber_remove(statuspage_id, subscriber_id)
  	request :method  => :delete,
            :url     => @url + 'subscriber/remove/' + statuspage_id + '/' + subscriber_id
  end
end
