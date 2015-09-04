#!/usr/bin/ruby -S rspec
require 'spec_helper'

#rhsm_register { 'example.com':
#  server_insecure => false,
#  username        => 'registered_user',
#  password        => 'password123',
#  server_hostname => 'example.com',
#  server_prefix   => 'https',
#  rhsm_baseurl    => '/repos',
#  rhsm_cacert     => '/path/to/ca.pem',
#  username        => 'doej',
#  password        => 'password123',
#  activationkeys  => '1-my-activation-key',
#  pool            => 'my_awesome_subscription',
#  environment     => 'lab',
#  autosubscribe   => true,
#  force           => true,
#  org             => 'the cool organization',
# }

described_class = Puppet::Type.type(:rhsm_register)

describe described_class, 'type' do

  it "should be ensurable" do
    expect(described_class.attrtype(:ensure)).to eq(:property)
  end

  [ :username, :password, :server_prefix, :org,
    :rhsm_cacert, :username, :password, :activationkeys,
    :pool, :environment ].each { |params|
      context "for #{params}" do
        it "should be of type paramter" do
          expect(described_class.attrtype(params)).to eq(:param)
        end
        it "should be of class Paramter" do
          expect(described_class.attrclass(params).ancestors).
            to include(Puppet::Parameter)
        end
        it "should have documentation" do
          expect(described_class.attrclass(params).doc.strip).
            not_to be_empty
        end
      end
      }


  context "for server_hostname" do
    namevar = :server_hostname
    it "should be a parameter" do
      expect(described_class.attrtype(namevar)).to eq(:param)
    end
    it "should have documentation" do
      expect(described_class.attrclass(namevar).doc.strip).
        not_to be_empty
    end
    it "should be the namevar" do
      expect(described_class.key_attributes).to eq([namevar])
    end
    it "should return a name equal to this parameter" do
      @resource = described_class.new(
        namevar => 'foo')
      expect(@resource[namevar]).to eq('foo')
      expect(@resource[:name]).to eq('foo')
    end
    it 'should reject invalid values' do
      expect{ described_class.new(
       namevar => '@#$%foooooo^!)')}.to raise_error(
        Puppet::ResourceError, /.*/)
    end
  end

  [ :server_insecure, :autosubscribe, :force ].each { |boolean_parameter|
    context "for #{boolean_parameter}" do
      it "should be a parameter" do
        expect(described_class.attrtype(boolean_parameter)).to eq(:param)
      end
      it "should have boolean class" do
        expect(described_class.attrclass(boolean_parameter).ancestors).
          to include(Puppet::Parameter::Boolean)
      end
      it "should have documentation" do
        expect(described_class.attrclass(boolean_parameter).doc.strip).
          not_to be_empty
      end
      it 'should accept boolean values' do
        @resource = described_class.new(
         :server_hostname => 'foo', boolean_parameter => true)
        expect(@resource[boolean_parameter]).to eq(true)
        @resource = described_class.new(
         :server_hostname => 'bar', boolean_parameter => false)
        expect(@resource[boolean_parameter]).to eq(false)
      end
      it 'should reject non-boolean values' do
        expect{ described_class.new(
         :server_hostname => 'foo', boolean_parameter => 'bad date')}.to raise_error(
          Puppet::ResourceError, /.*/)
      end
    end
  }

  context "for rhsm_basueurl" do
    it "should have an rhsm_baseurl parameter" do
      expect(described_class.attrtype(:rhsm_baseurl)).to eq(:param)
    end
     it 'should accept url path values' do
       @resource = described_class.new(
        :server_hostname => 'foo', :rhsm_baseurl => 'http://foo:123/')
       expect(@resource[:rhsm_baseurl]).to eq('http://foo:123/')
       @resource = described_class.new(
        :server_hostname => 'bar', :rhsm_baseurl => 'https://a.b.c')
       expect(@resource[:rhsm_baseurl]).to eq('https://a.b.c')
     end
     it 'should reject path values' do
         expect{ described_class.new(
          :server_hostname => 'foo', :rhsm_baseurl => '$%,,_,..!#^@(((,,,...')}.to raise_error(
           Puppet::ResourceError, /.*/)
     end
  end

  it 'should support enabled' do
    @resource = described_class.new(
      :server_hostname => 'foo', :ensure => :absent)
    expect(@resource[:ensure]).to eq(:absent)
  end
end
