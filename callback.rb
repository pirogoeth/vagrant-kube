# -*- coding: utf-8 -*-
# vim: set ai et ts=2 sts=2 sw=2 syntax=ruby:

# callback.rb
#
# callbacks for vrapper

require 'log4r'
require 'vagrant'

def call_machine(machine)
  return
end

def call_config(config)
  # custom ip_resolver for hostmanager
  # Proc accepts (m, r)
  # mach [Machine] machine object
  # resv [Machine] resolving machine object
  config.hostmanager.ip_resolver = Proc.new do |mach, resv|
    ip = nil
    mach.config.vm.networks.each do |network|
      key, opts = network[0], network[1]
      ip = opts[:ip] if key == :public_network
      break if ip
    end
    begin
      ip || (mach.ssh_info ? mach.ssh_info[:host] : nil)
    rescue
      nil
    end
  end
end

# map callback functions to a intuitive key
def get_callbacks
  {
    :config => Proc.new { |c| call_config(c) },
    :machine => Proc.new { |m| call_machine(m) },
  }
end

