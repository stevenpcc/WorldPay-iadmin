# = WorldPay iadmin Library
#  
#  WorldPay offer an api to do some remote administration tasks relating to FuturePay. The iadmin
#  api is not available by default. You must contact WorldPay and ask them to activate it for you. A
#  new installation id and password will be provided access the api. The api allows you to cancel a
#  FuturePay agreement, change the start date, debit an agreement, or change the amount. See the WorldPay
#  docs for a list of error responses you can expect.
#
#  WorldPay API Docs: http://www.rbsworldpay.com/support/kb/bg/recurringpayments/rpfp8000.html
#
# == Requirements
#
# * Ruby 1.8.2 with openssl (Should work with previous versions. I've just not tested it)
# * Valid WorldPay account.
# * Fakeweb gem for running tests
#
# = Example Usage:
#  
#  # Create a new WorldpayIadmin instance
#  @installation_id = "12345"
#  @password = "mypass"
#  @iadmin = WorldpayIadmin.new(@installation_id, @password)
#
#  @futurepay_id = "98765"  
#
#  # Cancel a FuturePay agreement
#  if @iadmin.cancel_agreement(@futurepay_id)
#    puts "Agreement Cancelled"
#  else
#    puts "Agreement Cancellation Failed\n"
#    puts @iadmin.response
#  end
#
#  # Modify a start date
#  if @iadmin.modify_start_date(@futurepay_id, Time.now)
#    puts "Start Date Changed"
#  else
#    puts "Start Date Change Failed\n"
#    puts @iadmin.response
#  end
#
#  # Debit an agreement
#  if @iadmin.debit(@futurepay_id, 9.99)
#    puts "Debit Successful"
#  else
#    puts "Debit Failed\n"
#    puts @iadmin.response
#  end
#
#  # Change an amount
#  if @iadmin.change_amount(@futurepay_id, 9.99)
#    puts "Change Amount Successful"
#  else
#    puts "DChange Amount Failed\n"
#    puts @iadmin.response
#  end
#
# = Test Mode:
#
#  @test_mode = true 
#  @iadmin = WorldpayIadmin.new(@installation_id, @password, @test_mode)
#  
#  or 
#  
#  @iadmin = WorldpayIadmin.new(@installation_id, @password)
#  @iadmin.test_mode = true

class WorldpayIadmin
    
  require 'net/http'
  require 'net/https'
  require 'uri'
  
  attr_accessor :worldpay_id, :password, :test_mode, :production_url, :test_url
  
  def initialize(worldpay_id, password, test_mode=false)
    @worldpay_id = worldpay_id
    @password = password
    @test_mode = test_mode
    @production_url = "https://secure-test.wp3.rbsworldpay.com/wcc/iadmin"
    @test_url = "https://secure.wp3.rbsworldpay.com/wcc/iadmin"
  end
  
  # Returns the url that the command will be sent to
  def iadmin_url
    @test_mode ? @test_url : @production_url
  end
  
  # Cancels an existing FuturePay agreement
  def cancel_agreement(futurepay_id)
    run_command({:futurePayId => futurepay_id, "op-cancelFP" => "" })
  end
  
  # Change or specify a FuturePay agreement's start date
  def modify_start_date(futurepay_id, start_date)
    run_command({:futurePayId => futurepay_id, :startDate => start_date.strftime("%Y-%m-%d"), "op-startDateRFP" => "" })
  end
  
  # Change the amount/price of subsequent debits for option 1 or 2 agreements, providing that there is at least
  # 8 days before 00:00 GMT on the day the payment is due.
  def change_amount(futurepay_id, amount)
    run_command({:futurePayId => futurepay_id, :amount => amount, "op-adjustRFP" => "" })
  end
  
  # Debit from an agreement
  def debit(futurepay_id, amount)
    run_command({:futurePayId => futurepay_id, :amount => amount, "op-paymentLFP" => "" })
  end
  
  # Returns the raw response string received from WorldPay
  def response
    @response
  end
  
  protected
  
  # Returns <code>true</code> if the passed response string indicated the action was sucessful
  def check_response(response)
    response =~ /^Y,/ ? true : false
  end
  
  # Returns <code>true</code> if able to connect to WorldPay the action was carried out
  def run_command(command_params)
    params = {:instId => @worldpay_id, :authPW => @password}
    params.merge!(command_params)
    params.merge!({ :testMode => "100" }) if @test_mode
    
    url = URI.parse(iadmin_url)
    
    req = Net::HTTP::Post.new(url.path)
    req.set_form_data(params)
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
                                  
    response = http.request(req)
    
    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
      @response = response.body.strip
      return check_response(@response)
    else
      @response = "Connection Error"
      return false
    end
    
  end

end