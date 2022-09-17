require "google/apis/calendar_v3"
require "google/api_client/client_secrets.rb"
class EventsController < ApplicationController
before_action :authenticate_user!
before_action :is_authorized? , only: [:destroy]
before_action :is_authenticate?, only: [:new]
before_action :is_ok?, except: [:create]
before_action :is_a_member?, only:[:show]

  include Search

 CALENDAR_ID = 'primary'
    def index
      @group=Group.find(params[:group_id])
      @events=@group.events
        #@event_list =  get_all_events(current_user)
        #@events = current_user.events
        #@try = organize_for_us(Event.first.group , '2022-08-25' , '2022-08-26' , '08:00:00' , '17:00:00' , 1)
        # <% @event_list.items.each do |event|%>
         # <li><%= event.summary%> </li>
          #<%end %>
      

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # parametri dell'altra versione dell'algoritmo
        # @event_list =  get_all_events_in_range(current_user, DateTime.strptime("28/08/2022 23:59:00 +0200", "%d/%m/%Y %H:%M:%S %Z").rfc3339, DateTime.strptime("25/08/2022 00:00:00 +0200", "%d/%m/%Y %H:%M:%S %Z").rfc3339)
        # @events = current_user.events
        # @try = organize_for_us(Event.first.group , '2022-08-25' , '2022-08-28' , '08:00:00' , '17:00:00' , 1)
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    end
    def event_calendar; end

    def new
      @group=Group.find(params[:group_id])
      @event=Event.new
      d=DateTime.now
      @dataI= d
      @dataF= DateTime.new(d.year,d.month,d.day,d.hour+1,d.second)
    end

    def create
      #authorize! :create, @event, :message => "BEWARE: you are not authorized to create new events."
      @event = Event.new(event_params)
      @group=Group.find(event_params[:group_id])
      client = get_google_calendar_client current_user
      eevent = params[:event]
      event = get_event eevent
      if @event.mode == "Online"
        client.insert_event('primary', event, conference_data_version: 1)
      else
        client.insert_event('primary', event)
      end
      flash[:notice] = 'Event was successfully added.'
      respond_to do |format|
        if @event.save!
          if position_params[:street]!="" && position_params[:city]!="" && position_params[:province]!="" && position_params[:country]!=""
            @position= Position.new(position_params)
            @position.event_id=@event.id
            @position.save
          end
          @event.get_array_members.each do |member|
            notify_recipent(@group,@event,member)
          end
          format.html { redirect_to group_event_path(@group,@event), notice: "Event was successfully created." }
          format.json { render :show, status: :ok, location: @event }
        else
          format.html { redirect_to  groups_path, notice: "Event was not successfully updated."}
          format.json { render :index , status: :unprocessable_entity }
        end
      end   
    end

    def is_authorized
      @group=Group.find(params[:group_id])
      if @group.list_accepted.where(user_id: current_user.id).empty?
        redirect_to root_path, notice: "Not Authorized on this Group"
      end
    end


    def show
        @group=Group.find(params[:group_id])
        @event=Event.find(params[:id])
        mark_notification_as_read
        @location= @event.position
    end

    def get_event event
      
        attendees = event[:members].map{ |t| {email: t.strip} }        
        eevent = Google::Apis::CalendarV3::Event.new(
          summary: event[:title],
          location: '800 Howard St., San Francisco, CA 94103',
          description: event[:description],
          start: {
            date_time: Time.new(event['start_date(1i)'],event['start_date(2i)'],event['start_date(3i)'],event['start_date(4i)'],event['start_date(5i)']).to_datetime.rfc3339,
            time_zone: "Europe/Rome"
          },
          end: {
            date_time: Time.new(event['end_date(1i)'],event['end_date(2i)'],event['end_date(3i)'],event['end_date(4i)'],event['end_date(5i)']).to_datetime.rfc3339,
            time_zone: "Europe/Rome"
          },
          conference_data: Google::Apis::CalendarV3::ConferenceData.new(
            create_request: Google::Apis::CalendarV3::CreateConferenceRequest.new(
              request_id: "sample123",
              conference_solution_key: Google::Apis::CalendarV3::ConferenceSolutionKey.new(
                type: "hangoutsMeet"
              )
            )
          ),
          attendees: attendees,
          reminders: {
            use_default: false,
            overrides: [
              Google::Apis::CalendarV3::EventReminder.new(reminder_method:"popup", minutes: 10),
              Google::Apis::CalendarV3::EventReminder.new(reminder_method:"email", minutes: 20)
            ]
          },
          notification_settings: {
            notifications: [
                            {type: 'event_creation', method: 'email'},
                            {type: 'event_change', method: 'email'},
                            {type: 'event_cancellation', method: 'email'},
                            {type: 'event_response', method: 'email'}
                           ]
          }, 'primary': true
        )
      end

      def destroy
        @event=Event.find(params[:id])
        @group=Group.find(params[:group_id])
        respond_to do |format|
        if @event.destroy
            format.html { redirect_to group_url(@group), notice: "Event succesfully destroy." }
            format.json { render :show, status: :ok, location: @group }
        else
            format.html { redirect_to root_path, notice: "Event was not successfully destroy."}
            format.json { render :edit , status: :unprocessable_entity }
        end
      end
        
      end

      def is_authorized?
        @group=Group.find(params[:group_id])
        @event=Event.find(params[:id])
        if @event.user_id != current_user.id
          redirect_to root_path, notice: "Not Authorized on this Event "
        end
      end

      def is_a_member?
        @event=Event.find(params[:id])
        members=@event.get_array_members
        if !members.include?(current_user) && @event.user != current_user

          redirect_to group_url(Group.find(params[:group_id])), notice: "Not Authorized on this Event"
        end

      end


      def is_authenticate?
        if !User.last.access_token?
          redirect_to group_url(Group.find(params[:group_id])), notice: "Not Authenticate"
        end
      end

       def is_ok?
     
        @group=Group.find(params[:group_id])
         if @group.list_accepted.where(user_id: current_user.id).empty?
           redirect_to root_path, notice: "Not Authorized ok"
         end
        end

        def parameterize_date
          @event=Event.new
          d=params[:day].to_i
          m=params[:month].to_i
          oraI=params[:data_inizio].to_datetime
          oraF=params[:data_fine].to_datetime
          @dataI= DateTime.new(DateTime.now.year,m,d,oraI.hour,oraI.minute,oraI.sec)
          @dataF= DateTime.new(DateTime.now.year,m,d,oraF.hour,oraF.minute,oraF.sec)
          render "new"
        end



    private
    def event_params
      params.require(:event).permit(:title, :description, :user_id, :mode, :type_of_hours, :group_id,:start_date, :end_date, members: [])

    end

    def position_params
      params.require(:position).permit!
    end

    def notify_recipent(group,event,user)
      EventNotification.with(user: user,event: event, group: group).deliver_later(user)
    end

    def mark_notification_as_read
      @event=Event.find(params[:id])
      if current_user
        notifications_to_mark_as_read= @event.notifications_as_event.where(recipient: current_user)
        notifications_to_mark_as_read.update_all(read_at: Time.zone.now)
      end
    end

end