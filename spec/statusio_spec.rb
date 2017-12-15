require_relative '../lib/statusio'
require 'rspec'
require 'httparty'

describe StatusioClient do
	let (:api_id) { '' }
	let (:api_key) { '' }
	let (:statuspage_id) { '568d8a3e3cada8c2490000dd' }
	let (:api_url) { 'https://api.status.io/v2/' }
	let (:api_headers) {
		{
			'x-api-id' => '',
			'x-api-key' => '',
			'Content-Type' => 'application/json'
		}
	}

	let (:statusioclient) { StatusioClient.new api_key, api_id }
	let (:mock_components) {
		[{
			 '_id' => '568d8a3e3cada8c2490000ed',
			 'hook_key' => 'xkhzsma0z',
			 'containers' => [{
				                  '_id' => '568d8a3e3cada8c2490000ec',
				                  'name' => 'Primary Data Center',
			                  }],
			 'name' => 'Website',
		 }]
	}

	it 'should success' do
		api_key.should eq ''
		statusioclient.should be_an_instance_of StatusioClient
	end

	#   COMPONENT
	describe 'Testing components methods' do
		describe '#component_list' do
			let (:response) { return statusioclient.component_list statuspage_id }

			it 'should not never an error return, the message should be ok' do
				response.should_not be nil
				response['status']['error'].should eq 'no'
				response['status']['message'].should eq 'OK'

				response['result'].length.should eq mock_components.length
				response['result'].each_with_index do |component, key|
					component['containers'].length.should eq mock_components[key]['containers'].length
				end
			end

			it 'should be equal with the actual result that get with httparty' do
				actual_response = HTTParty.get(api_url + 'component/list/' + statuspage_id, :headers => api_headers)
				actual_response.code.should eq 200

				response.should eq JSON.parse(actual_response.body)
			end
		end

		# Test component_status_update
		describe '#component_status_update' do
			let (:components) { [mock_components[0]] }
			let (:containers) { [components[0]['containers'][0]] }
			let (:component_status_update_response) {
				statusioclient.component_status_update statuspage_id,
				                                       [components[0]['_id']],
				                                       [containers[0]['_id']],
				                                       '#Test updating component',
				                                       StatusioClient::STATUS_OPERATIONAL
			}

			it 'should update single component and return with "result" equal true with the message' do

				component_status_update_response['status']['error'].should eq 'no'
				component_status_update_response['status']['message'].should eq 'OK'
				component_status_update_response['result'].should eq true

				# TODO: Fix server-side: The result always return true even if @component_id and @container_id are wrong
			end
		end
	end

	#   INCIDENT
	describe 'Test incident methods' do
		let (:components) { [mock_components[0]] }
		let (:containers) { [components[0]['containers'][0]] }
		let (:payload) { {
			'statuspage_id' => statuspage_id,
			'components' => [components[0]['_id']],
			'containers' => [containers[0]['_id']],
			'incident_name' => 'Database errors',
			'incident_details' => 'Investigating database connection issue',
			'notify_email' => 0,
			'notify_sms' => 1,
			'notify_webhook' => 0,
			'social' => 0,
			'irc' => 0,
			'hipchat' => 0,
			'slack' => 0,
			'current_status' => StatusioClient::STATUS_PARTIAL_SERVICE_DISRUPTION,
			'current_state' => StatusioClient::STATE_INVESTIGATING,
			'all_infrastructure_affected' => '0'
		} }

		let (:notifications) {
			notifications = 0
			notifications += StatusioClient::NOTIFY_EMAIL if payload['notify_email'] != 0
			notifications += StatusioClient::NOTIFY_SMS if payload['notify_sms'] != 0
			notifications += StatusioClient::NOTIFY_WEBHOOK if payload['notify_webhook'] != 0

			return notifications
		}

		# Test incident_list
		describe '#incident_list' do
			let (:response) { statusioclient.incident_list statuspage_id }

			it 'should never return an error' do
				response.should_not be nil
				response['status']['error'].should eq 'no'
				response['status']['message'].should eq 'OK'

				response['result']['active_incidents'].should be_an_instance_of Array
				response['result']['resolved_incidents'].should be_an_instance_of Array
			end

			it 'should be equal with the actual result that get with httparty' do
				actual_response = HTTParty.get(api_url + 'incident/list/' + statuspage_id, :headers => api_headers)
				actual_response.code.should eq 200

				response.should eq JSON.parse(actual_response.body)
			end
		end

		# Test incident_create
		describe '#incident_create' do
			let (:response) {
				statusioclient.incident_create statuspage_id,
				                               payload['incident_name'],
				                               payload['incident_details'],
				                               payload['components'],
				                               payload['containers'],
				                               payload['current_status'],
				                               payload['current_state'],
				                               notifications,
				                               payload['all_infrastructure_affected']
			}

			it 'should not be nil' do
				response.should_not eq nil
			end

			it 'should return successfully' do
				response['status']['error'].should eq 'no'
				response['status']['message'].should eq 'OK'
			end

			it 'should return with incident_id' do
				response['result'].should_not eq ''
				response['result'].length.should eq 24
			end
		end

		# Test incident_delete
		describe '#incident_delete' do
			let (:incident_list_response) { statusioclient.incident_list statuspage_id }
			let (:incidents) {
				_incidents = {}
				_incidents['active'] = incident_list_response['result']['active_incidents']
				_incidents['resolved'] = incident_list_response['result']['resolved_incidents']
				return _incidents
			}

			it 'should delete all the incidents and return true' do
				incidents.each_value do |igroup|
					if igroup.class == Array and igroup.length != 0
						igroup.each_index do |k|
							@incident_id = igroup[k]['_id']
							response = statusioclient.incident_delete statuspage_id, @incident_id

							response['status']['error'].should eq 'no'
							response['status']['message'].should eq 'Successfully deleted incident'
							response['result'].should eq true
						end
					end
				end
			end
		end

		# Test incident_message
		describe '#incident_message' do
			let (:create_incident_response) {
				statusioclient.incident_create statuspage_id,
				                               payload['incident_name'],
				                               payload['incident_details'],
				                               payload['components'],
				                               payload['containers'],
				                               payload['current_status'],
				                               payload['current_state'],
				                               notifications,
				                               payload['all_infrastructure_affected']
			}

			let (:incident_id) { create_incident_response['result'] }
			let (:incident_list_response) { statusioclient.incident_list statuspage_id }

			# get default message_ids
			let (:message_id) { incident_list_response['result']['active_incidents'][0]['messages'][0]['_id'] }

			after do
				statusioclient.incident_delete statuspage_id, @incident_id
			end
		end

		# Test incident_update
		describe '#incident_update' do
			let (:create_incident_response) {
				statusioclient.incident_create statuspage_id,
				                               payload['incident_name'],
				                               payload['incident_details'],
				                               payload['components'],
				                               payload['containers'],
				                               payload['current_status'],
				                               payload['current_state'],
				                               notifications,
				                               payload['all_infrastructure_affected']
			}

			let (:incident_id) { create_incident_response['result'] }

			it 'should receive parameters and update the incident without any error returned' do
				incident_details = 'Incident fixed'
				current_status = StatusioClient::STATUS_OPERATIONAL
				current_state = StatusioClient::STATE_MONITORING
				response = statusioclient.incident_update statuspage_id, incident_id, incident_details, current_status, current_state, StatusioClient::NOTIFY_SMS

				response['status']['error'].should eq 'no'
				response['status']['message'].should eq 'OK'
				response['result'].should eq true
			end

			after do
				statusioclient.incident_delete statuspage_id, incident_id
			end
		end

		# Test incident_resolve
		describe '#incident_resolve' do
			let (:create_incident_response) {
				statusioclient.incident_create statuspage_id,
				                               payload['incident_name'],
				                               payload['incident_details'],
				                               payload['components'],
				                               payload['containers'],
				                               payload['current_status'],
				                               payload['current_state'],
				                               notifications,
				                               payload['all_infrastructure_affected']
			}

			let (:incident_id) { create_incident_response['result'] }

			it 'should receive parameters and resolve the incident without any error returned' do
				incident_details = 'Incident resolved'
				current_status = StatusioClient::STATUS_OPERATIONAL
				current_state = StatusioClient::STATE_MONITORING
				response = statusioclient.incident_resolve statuspage_id, incident_id, incident_details, current_status, current_state, StatusioClient::NOTIFY_SMS

				response['status']['error'].should eq 'no'
				response['status']['message'].should eq 'OK'
				response['result'].should eq true
			end

			after do
				statusioclient.incident_delete statuspage_id, incident_id
			end
		end
	end

	# MAINTENANCE
	describe 'Test maintenance methods' do
		let (:components) { [mock_components[0]] }
		let (:containers) { [components[0]['containers'][0]] }

		let (:start_datetime) { Time.now + 60*60*24 }
		let (:end_datetime) { Time.now + 60*60*24 + 60*30 }

		let (:payload) { {
			'maintenance_name' => 'Power source maintenance',
			'maintenance_details' => 'Power source maintenance for all the datacenters',
			'infrastructure_affected' => [components[0]['_id']+'-'+containers[0]['_id']],
			'date_planned_start' => start_datetime.strftime('%m/%d/%Y'),
			'time_planned_start' => start_datetime.strftime('%H:%M'),
			'date_planned_end' => end_datetime.strftime('%m/%d/%Y'),
			'time_planned_end' => end_datetime.strftime('%H:%M'),
			'automation' => '0',
			'all_infrastructure_affected' => '0',
			'maintenance_notify_now' => '0',
			'maintenance_notify_1_hr' => '0',
			'maintenance_notify_24_hr' => '0',
			'maintenance_notify_72_hr' => '0'
		} }


		# Test maintenance_list
		describe '#maintenance_list' do
			let (:response) { statusioclient.maintenance_list statuspage_id }

			it 'should never return an error' do
				response.should_not be nil
				response['status']['error'].should eq 'no'
				response['status']['message'].should eq 'OK'

				response['result']['active_maintenances'].should be_an_instance_of Array
				response['result']['upcoming_maintenances'].should be_an_instance_of Array
				response['result']['resolved_maintenances'].should be_an_instance_of Array
			end

			it 'should be equal with the actual result that get with httparty' do
				actual_response = HTTParty.get(api_url + 'maintenance/list/' + statuspage_id, :headers => api_headers)
				actual_response.code.should eq 200

				response.should eq JSON.parse(actual_response.body)
			end
		end

		# Test maintenance_schedule
		describe '#maintenance_schedule' do
			let (:schedule_maintenance_response) {
				statusioclient.maintenance_schedule statuspage_id,
				                                    payload['maintenance_name'],
				                                    payload['maintenance_details'],
				                                    payload['infrastructure_affected'],
				                                    payload['date_planned_start'],
				                                    payload['time_planned_start'],
				                                    payload['date_planned_end'],
				                                    payload['time_planned_end'],
				                                    payload['automation'],
				                                    payload['all_infrastructure_affected'],
				                                    payload['maintenance_notify_now'],
				                                    payload['maintenance_notify_1_hr'],
				                                    payload['maintenance_notify_24_hr'],
				                                    payload['maintenance_notify_72_hr']
			}

			it 'should receive @data as parameter and should return an incident_id' do
				schedule_maintenance_response['status']['error'].should eq 'no'
				schedule_maintenance_response['status']['message'].should eq 'OK'
				schedule_maintenance_response['result'].should_not eq ''
				schedule_maintenance_response['result'].length.should eq 24
			end
		end

		# Test maintenance_delete
		describe '#maintenance_delete' do
			let (:maintenance_list_response) { statusioclient.maintenance_list statuspage_id }
			let (:maintenances) {
				_maintenances = {}
				_maintenances['active'] = maintenance_list_response['result']['active_maintenances']
				_maintenances['upcoming'] = maintenance_list_response['result']['upcoming_maintenances']
				_maintenances['resolved'] = maintenance_list_response['result']['resolved_maintenances']

				return _maintenances
			}

			it 'should delete all the maintenances and return true' do
				maintenances.each_value do |mgroup|
					if mgroup.class == Array and mgroup.length != 0
						mgroup.each_index do |k|
							maintenance_id = mgroup[k]['_id']

							response = statusioclient.maintenance_delete statuspage_id, maintenance_id

							response['status']['error'].should eq 'no'
							response['status']['message'].should eq 'Successfully deleted maintenance'
							response['result'].should eq true
						end
					end
				end
			end
		end

		# Test maintenance_start
		describe '#maintenance_start' do
			let (:schedule_maintenance_response) {
				statusioclient.maintenance_schedule statuspage_id,
				                                    payload['maintenance_name'],
				                                    payload['maintenance_details'],
				                                    payload['infrastructure_affected'],
				                                    payload['date_planned_start'],
				                                    payload['time_planned_start'],
				                                    payload['date_planned_end'],
				                                    payload['time_planned_end'],
				                                    payload['automation'],
				                                    payload['all_infrastructure_affected'],
				                                    payload['maintenance_notify_now'],
				                                    payload['maintenance_notify_1_hr'],
				                                    payload['maintenance_notify_24_hr'],
				                                    payload['maintenance_notify_72_hr']
			}

			let (:maintenance_id) { schedule_maintenance_response['result'] }

			it 'should receive @maintenance_id and return no error' do
				response = statusioclient.maintenance_start statuspage_id,
				                                            maintenance_id,
				                                            payload['maintenance_name'] + ' : started ' + Time.now.strftime('%d/%m/%Y %H:%M'),
				                                            StatusioClient::NOTIFY_EMAIL

				response['status']['error'].should eq 'no'
				response['status']['message'].should eq 'OK'
				response['result'].should eq true
			end

			after do
				statusioclient.maintenance_delete statuspage_id, maintenance_id
			end
		end

		# Test maintenance_finish
		describe '#maintenance_finish' do
			let (:schedule_maintenance_response) {
				statusioclient.maintenance_schedule statuspage_id,
				                                    payload['maintenance_name'],
				                                    payload['maintenance_details'],
				                                    payload['infrastructure_affected'],
				                                    payload['date_planned_start'],
				                                    payload['time_planned_start'],
				                                    payload['date_planned_end'],
				                                    payload['time_planned_end'],
				                                    payload['automation'],
				                                    payload['all_infrastructure_affected'],
				                                    payload['maintenance_notify_now'],
				                                    payload['maintenance_notify_1_hr'],
				                                    payload['maintenance_notify_24_hr'],
				                                    payload['maintenance_notify_72_hr']
			}

			let (:maintenance_id) { schedule_maintenance_response['result'] }
			let (:start_maintenance_response) {
				statusioclient.maintenance_start statuspage_id,
				                                 maintenance_id,
				                                 payload['maintenance_name'] + ' : started ' + Time.now.strftime('%d/%m/%Y %H:%M'),
				                                 StatusioClient::NOTIFY_EMAIL
			}

			it 'should receive parameters and return no error' do
				response = statusioclient.maintenance_finish statuspage_id,
				                                             maintenance_id,
				                                             'Maintenance finished ' + Time.now.strftime('%d/%m/%Y %H:%M'),
				                                             StatusioClient::NOTIFY_EMAIL

				response['status']['error'].should eq 'no'
				response['status']['message'].should eq 'OK'
				response['result'].should eq true
			end

			after do
				statusioclient.maintenance_delete statuspage_id, maintenance_id
			end
		end

		# Test maintenance_message
		describe '#maintenance_message' do
			let (:message_id) {
				maintenance_schedule_response = statusioclient.maintenance_schedule statuspage_id,
				                                                                    payload['maintenance_name'],
				                                                                    payload['maintenance_details'],
				                                                                    payload['infrastructure_affected'],
				                                                                    payload['date_planned_start'],
				                                                                    payload['time_planned_start'],
				                                                                    payload['date_planned_end'],
				                                                                    payload['time_planned_end'],
				                                                                    payload['automation'],
				                                                                    payload['all_infrastructure_affected'],
				                                                                    payload['maintenance_notify_now'],
				                                                                    payload['maintenance_notify_1_hr'],
				                                                                    payload['maintenance_notify_24_hr'],
				                                                                    payload['maintenance_notify_72_hr']

				maintenance_id = maintenance_schedule_response['result']

				maintenance_list_response = statusioclient.maintenance_list statuspage_id
				upcoming_maintenances = maintenance_list_response['result']['upcoming_maintenances']

				m_id = 0
				upcoming_maintenances.each do |i|
					if i['_id'] == maintenance_id
						m_id = i['messages'][0]['_id']
					end
				end

				return m_id
			}

			let (:maintenance_message_response) { statusioclient.maintenance_message statuspage_id, message_id }


			after do
				statusioclient.maintenance_delete statuspage_id, maintenance_id
			end
		end

		# Test maintenance_update
		describe '#maintenance_update' do
			let (:maintenance_id) {
				maintenance_schedule_response = statusioclient.maintenance_schedule statuspage_id,
				                                                                    payload['maintenance_name'],
				                                                                    payload['maintenance_details'],
				                                                                    payload['infrastructure_affected'],
				                                                                    payload['date_planned_start'],
				                                                                    payload['time_planned_start'],
				                                                                    payload['date_planned_end'],
				                                                                    payload['time_planned_end'],
				                                                                    payload['automation'],
				                                                                    payload['all_infrastructure_affected'],
				                                                                    payload['maintenance_notify_now'],
				                                                                    payload['maintenance_notify_1_hr'],
				                                                                    payload['maintenance_notify_24_hr'],
				                                                                    payload['maintenance_notify_72_hr']

				return maintenance_schedule_response['result']
			}

			let (:maintenance_update_response) {
				statusioclient.maintenance_update statuspage_id,
				                                  maintenance_id,
				                                  'This maintenance details should be updated.',
				                                  StatusioClient::NOTIFY_EMAIL
			}

			it 'should receive parameters and update the maintenance without any error returned' do
				maintenance_update_response['status']['error'].should eq 'no'
				maintenance_update_response['status']['message'].should eq 'OK'
				maintenance_update_response['result'].should eq true
			end

			after do
				statusioclient.maintenance_delete statuspage_id, maintenance_id
			end
		end
	end

	# SUBSCRIBER
	describe 'Test subscriber methods' do
		let (:email_to_register) { 'test1@example.com' }
		let (:another_email) { 'test2@example.com' }
		let (:payload) { {
			'method' => 'email',
			'address' => email_to_register,
			'granular' => mock_components[0]['_id'] + '_' + mock_components[0]['containers'][0]['_id']
		} }

		# Test subscriber_list
		describe '#subscriber_list' do
			let (:subscriber_list_response) { statusioclient.subscriber_list statuspage_id }

			it 'should return list of subscriber with no error' do
				subscriber_list_response['status']['error'].should eq 'no'
				subscriber_list_response['status']['message'].should eq 'OK'
			end

			it 'should have the same result with actual get with httparty' do
				actual_response = HTTParty.get api_url + 'subscriber/list/' + statuspage_id, :headers => api_headers
				subscriber_list_response.should eq JSON.parse(actual_response.body)
			end
		end

		let (:subscribers) {
			subscribers = {}
			count = 0
			subscriber_list_response = statusioclient.subscriber_list statuspage_id
			subscriber_list_response['result'].each_key do |subg_key|
				subscriber_list_response['result'][subg_key].each do |s|
					subscribers[count] = s['_id']
					count = count + 1
				end
			end

			return subscribers
		}

		describe '#subscriber_remove' do
			it 'should delete all subscriber' do
				subscribers.each_key do |key|
					subscriber_remove_response = statusioclient.subscriber_remove statuspage_id, subscribers[key]

					subscriber_remove_response['status']['error'].should eq 'no'
					subscriber_remove_response['status']['message'].should eq 'Successfully deleted subscriber'
				end
			end
		end

		# Test subscriber_add
		describe '#subscriber_add' do
			let (:subscriber_add_response) {
				statusioclient.subscriber_add statuspage_id,
				                              payload['method'],
				                              payload['address'],
				                              0,
				                              payload['granular']
			}

			it 'should create subscriber and return no error' do
				subscriber_add_response['status']['error'].should eq 'no'
				subscriber_add_response['status']['message'].should eq 'OK'
				subscriber_add_response['result'].should eq true
				subscriber_add_response['subscriber_id'].length.should eq 24
			end

			after do
				statusioclient.subscriber_remove statuspage_id, subscriber_add_response['subscriber_id']
			end
		end

		# Test subscriber_update
		describe '#subscriber_subscriber_update' do
			let (:subscriber_id) {
				subscriber_add_response = statusioclient.subscriber_add statuspage_id,
				                                                        payload['method'],
				                                                        payload['address'],
				                                                        0,
				                                                        payload['granular']
				return subscriber_add_response['subscriber_id']
			}
			#let (:subscriber_update_with_same_email_response) {statusioclient.subscriber_update statuspage_id, subscriber_id, email, payload['granular']}
			let (:subscriber_update_response) { statusioclient.subscriber_update statuspage_id, subscriber_id, another_email, payload['granular'] }

			it 'should return successful' do
				subscriber_update_response['status']['error'].should eq 'no'
				subscriber_update_response['status']['message'].should eq 'Successfully updated subscriber'
				subscriber_update_response['result']['_id'].should eq subscriber_id
			end

			after do
				statusioclient.subscriber_remove statuspage_id, subscriber_id
			end
		end

=begin
	describe 'afdsfsd' do
		before :each do
			response = statusioclient.subscriber_list statuspage_id
			@subscribers = {}
		end

		it 'should update the subscriber with new information and return no error' do
			new_email = 'test1@example.com'

			response = statusioclient.subscriber_update statuspage_id, @@subscriber_id, new_email, @data['granular']
			response['status']['error'].should eq 'no'
		end

		it 'should delete the created subscriber and return no error' do
			response = statusioclient.subscriber_remove statuspage_id, @@subscriber_id

			response['status']['error'].should eq 'no'
			response['status']['message'].should eq 'Successfully deleted subscriber'
			response['result'].should eq true
		end
	end
=end
	end

	# STATUS
	describe 'Test status method' do
		describe '#status_summary' do
			let (:response) { return statusioclient.status_summary statuspage_id }

			it 'should not never an error return, the message should be ok' do
				response.should_not be nil
				response['status']['error'].should eq 'no'
				response['status']['message'].should eq 'Get public api status successfully'
			end
		end
	end

	# METRICS
	describe 'Test metric method' do
		# my created metric id
		let (:metric_id) { '568d8ab5efe35d412f0006f8' }

		# another data from api example
		let (:day_avg) { '22.58' }
		let (:day_start) { '1395981878000' }
		let (:day_dates) { %q['2014-03-28T05:43:00+00:00', '2014-03-28T06:43:00+00:00', '2014-03-28T07:43:00+00:00', '2014-03-28T08:43:00+00:00', '2014-03-28T09:43:00+00:00', '2014-03-28T10:43:00+00:00', '2014-03-28T11:43:00+00:00', '2014-03-28T12:43:00+00:00', '2014-03-28T13:43:00+00:00', '2014-03-28T14:43:00+00:00', '2014-03-28T15:43:00+00:00', '2014-03-28T16:43:00+00:00', '2014-03-28T17:43:00+00:00', '2014-03-28T18:43:00+00:00', '2014-03-28T19:43:00+00:00', '2014-03-28T20:43:00+00:00', '2014-03-28T21:43:00+00:00', '2014-03-28T22:43:00+00:00', '2014-03-28T23:43:00+00:00', '2014-03-29T00:43:00+00:00', '2014-03-29T01:43:00+00:00', '2014-03-29T02:43:00+00:00', '2014-03-29T03:43:00+00:00'] }
		let (:day_values) { %q['20.70', '20.00', '19.20', '19.80', '19.90', '20.10', '21.40', '23.00', '27.40', '28.70', '27.50', '29.30', '28.50', '27.20', '28.60', '28.70', '25.90', '23.40', '22.40', '21.40', '19.80', '19.50', '20.00'] }
		let (:week_avg) { '20.07' }
		let (:week_start) { '1395463478000' }
		let (:week_dates) { %q['2014-03-22T04:43:00+00:00', '2014-03-23T04:43:00+00:00', '2014-03-24T04:43:00+00:00', '2014-03-25T04:43:00+00:00', '2014-03-26T04:43:00+00:00', '2014-03-27T04:43:00+00:00', '2014-03-28T04:43:00+00:00'] }
		let (:week_values) { %q['23.10', '22.10', '22.20', '22.30', '22.10', '18.70', '17.00'] }
		let (:month_avg) { '10.63' }
		let (:month_start) { '1393476280000' }
		let (:month_dates) { %q['2014-02-28T04:43:00+00:00', '2014-03-01T04:43:00+00:00', '2014-03-02T04:43:00+00:00', '2014-03-03T04:43:00+00:00', '2014-03-04T04:43:00+00:00', '2014-03-05T04:43:00+00:00', '2014-03-06T04:43:00+00:00', '2014-03-07T04:43:00+00:00', '2014-03-08T04:43:00+00:00', '2014-03-09T04:43:00+00:00', '2014-03-10T04:43:00+00:00', '2014-03-11T04:43:00+00:00', '2014-03-12T04:43:00+00:00', '2014-03-13T04:43:00+00:00', '2014-03-14T04:43:00+00:00', '2014-03-15T04:43:00+00:00', '2014-03-16T04:43:00+00:00', '2014-03-17T04:43:00+00:00', '2014-03-18T04:43:00+00:00', '2014-03-19T04:43:00+00:00', '2014-03-20T04:43:00+00:00', '2014-03-21T04:43:00+00:00', '2014-03-22T04:43:00+00:00', '2014-03-23T04:43:00+00:00', '2014-03-24T04:43:00+00:00', '2014-03-25T04:43:00+00:00', '2014-03-26T04:43:00+00:00', '2014-03-27T04:43:00+00:00', '2014-03-28T04:43:00+00:00'] }
		let (:month_values) { %q['0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '18.50', '18.60', '18.40', '16.60', '16.80', '17.90', '19.90', '21.30', '22.80', '20.00', '17.30', '19.10', '21.50', '22.40', '22.50', '22.00', '21.80'] }


		describe '#metric_update' do
			let (:metric_update_response) {
				statusioclient.metric_update statuspage_id,
				                             metric_id,
				                             day_avg,
				                             day_start,
				                             day_dates,
				                             day_values,
				                             week_avg,
				                             week_start,
				                             week_dates,
				                             week_values,
				                             month_avg,
				                             month_start,
				                             month_dates,
				                             month_values
			}

			it 'should return successfully' do
				metric_update_response['status']['error'].should eq 'no'
				metric_update_response['status']['message'].should eq 'Updated metric successfully'
				metric_update_response['result'].should eq true
			end
		end
	end
end