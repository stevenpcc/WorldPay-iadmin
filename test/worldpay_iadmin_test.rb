$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'test/unit'
require 'worldpay_iadmin'
require 'net/http'
require 'net/https'
require 'uri'
require 'fakeweb'

class WorldpayIadminTest < Test::Unit::TestCase
  
  def create_worldpay_iadmin(response)
    @worldpay_iadmin = WorldpayIadmin.new("123434", "password")
    FakeWeb.register_uri(:any, @worldpay_iadmin.iadmin_url, :body => response)
    @worldpay_iadmin
  end
  
  def test_initialize
    @worldpay_iadmin = WorldpayIadmin.new("123434", "password", true)
    
    assert_equal "123434", @worldpay_iadmin.worldpay_id
    assert_equal "password", @worldpay_iadmin.password
    assert_equal true, @worldpay_iadmin.test_mode
  end
  
  def test_cancel_agreement
    assert create_worldpay_iadmin("Y,Start date set OK").cancel_agreement("232323")
  end
  
  def test_cancel_agreement_fail 
    assert !create_worldpay_iadmin("E,Problem cancelling agreement").cancel_agreement("232323")
  end
  
  def test_modify_start_date
    assert create_worldpay_iadmin("Y,Start date set OK").modify_start_date("232323", Time.now)
  end
  
  def test_modify_start_date_fail 
    assert !create_worldpay_iadmin("E,Agreement already has start date").modify_start_date("232323", Time.now)
  end

  def test_change_amount
    assert create_worldpay_iadmin("Y,Amount updated").change_amount("232323", 9.99)
  end
  
  def test_change_amount_fail 
    assert !create_worldpay_iadmin("E,Amount is fixed").change_amount("232323", 9.99)
  end
  
  def test_debit
    assert create_worldpay_iadmin("Y,transId,A,rawAuthMessage,Payment successful").debit("232323", 9.99)
  end
  
  def test_debit_fail
    assert !create_worldpay_iadmin("E,Agreement already finished").debit("232323", 9.99)
  end

end