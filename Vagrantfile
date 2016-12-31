# -*- coding: utf-8 -*-
# vim: set ai et ts=2 sts=2 sw=2 syntax=ruby:

# vrapper/Vagrantfile
#
# More simplistic wrapper around Vagrant.

require 'pp'
require 'vagrant/ui'
require 'yaml'

UI = Vagrant::UI::Colored.new

def get_callbacks
  Hash.new
end

begin
  require_relative 'callback.rb'
rescue LoadError
end

callbacks = get_callbacks()

debug_mode = ENV['VRAP_DEBUG'] || false
test_mode = ENV['VRAP_TEST'] || false
desc_file = ENV['DESCRIBE_FILE'] || 'machines.yml'

p "REGISTERED CALLBACKS" unless not debug_mode
PP.pp(callbacks) unless not debug_mode

desc = YAML::load_file(desc_file)

vagrant_cfg = desc[:config] || {}
groups = desc[:groups] || {}
machines = desc[:machines] || []

def is_settable(obj, key)
  return obj.respond_to? "#{key}="
end

def is_member(obj, key)
  return obj.respond_to? "#{key}"
end

def is_function(obj, key)
  return is_member(obj, key) && !is_settable(obj, key)
end

def set_property(obj, key, value)
  obj.send("#{key}=", value)
end

def resolve_group_bases(groups)
  res_order = {}
  final = {}
  groups.each do |name, data|
    # Perform hash merges for groups -- allows group inheritance.
    #
    # This has a problem of resolution order. Obviously groups
    # without any `:from` should be "resolved" / defined first.
    if not (data || {}).include? :from then
      res_order[name] = nil
      final[name] = data
      next
    end

    case data[:from]
    when String
      res_order[name] = [data[:from]]
    when Array
      res_order[name] = data[:from]
    end

    data.delete :from
  end

  res_order.each do |group, inherit|
    group_data = groups[group]
    (inherit || []).each do |base|
      if final.include? base
        # Merge the final group into this group's data
        (final[base] || {}).each do |k, v|
          if group_data[k] != nil then
            if group_data[k].is_a? v.class then
              case v
              when Hash
                group_data[k].merge! v.clone
              when Array
                group_data[k] = v.clone.concat group_data[k]
              else
                UI.warn "I don't know how to merge #{v.class} and #{group_data[k].class}"
                next
              end
            else
              next
            end
          else
            group_data[k] = v.clone
          end
        end
      end
    end
    final[group] = group_data
  end

  return final
end

groups = resolve_group_bases(groups)
p "RESOLVED GROUPS INHERITANCE" unless not debug_mode
PP.pp(groups) unless not debug_mode

machines_define = []
machines.each do |machine|
  # Create the metadata hash for this machine.
  # This is done by merging each entry from the group into the corresponding
  # entry on the machine dictionary. Note that both types must match for this
  # to actually work!
  machine[:groups].each do |group_name|
    if !groups.include? group_name then
      UI.error " [!] Unknown group '#{group_name}' inherited by machine '#{machine[:name]}'"
      next
    end

    group = groups[group_name] || {}
    group.each do |k, v|
      if machine[k] != nil then
        if machine[k].is_a? v.class then
          case v
          when Hash
            machine[k].merge! v
          when Array
            machine[k].concat v
          else
            UI.warn "I don't know how to merge #{v.class} and #{machine[k].class}"
            next
          end
        else
          next
        end
      else
        machine[k] = v.clone
      end
    end
  end

  # Check ignore flag here so it can be propagated from groups
  if machine[:ignore] then
    UI.info "Skipping machine `#{machine[:name]}`"
    next
  end

  # Add the newly merged machine back in to the machines list
  machine.delete :groups
  machines_define.push machine
end

# Debug print :)
p "APPLIED GROUPS TO MACHINES" unless not debug_mode
PP.pp(machines_define) unless not debug_mode

if test_mode then
  UI.success "vrapper is in test mode -- exiting!"
  exit 0
end

Vagrant.configure("2") do |config|

  vagrant_cfg.each do |section, values|
    target = config.send(section)
    (values || {}).each do |k, v|
      if is_function target, k then
        target.send(k, v)
      else
        set_property target, k, v
      end
    end
  end

  machines_define.each do |machine|
    machine_opts = (machine[:options] || {})
    config.vm.define machine[:name], **machine_opts do |m|
      machine.delete :name
      machine.delete :options

      # Set the attributes on the VM config object.
      # These are the main settings for each VM, such as
      #  hostname, box, etc.
      (machine[:vm] || {}).each do |key, value|
        set_property m.vm, key, value
      end
      machine.delete :vm

      # Set up the networking for the machine.
      # A network should *at least* have a `network_type` key.
      (machine[:networks] || []).each do |network|
        net_type = network[:network_type]
        net_opts = network.select { |k, v| k != :network_type }
        m.vm.network net_type, **net_opts
      end
      machine.delete :networks

      # Set provider options. Some may not work if the set requires a function call.
      # Properties are the only option types currently supported.
      (machine[:providers] || []).each do |provider|
        if provider[:engine] then
          m.vm.provider provider[:engine] do |prov|
            (provider[:options] || {}).each do |key, value|
              set_property prov, key, value
            end
          end
        end
      end
      machine.delete :providers

      (machine[:provisioners] || []).each do |prov|
        prov[:run] = "once" unless prov[:run] != nil
        if prov[:engine] then
          if prov[:name] then
            # This is a named prov so it takes a slightly different syntax.
            m.vm.provision prov[:name], type: prov[:engine], run: prov[:run] do |prov_cfg|
              (prov[:options] || {}).each do |key, value|
                set_property prov_cfg, key, value
              end
            end
          else
            # Unnamed provisioner
            m.vm.provision prov[:engine], run: prov[:run] do |prov_cfg|
              (prov[:options] || {}).each do |key, value|
                set_property prov_cfg, key, value
              end
            end
          end
        end
      end
      machine.delete :provisioners

      # Apply synced_folders setting
      (machine[:synced_folders] || []).each do |folder|
        folder_src = folder[:src]
        folder_dst = folder[:dst]
        folder_opts = (folder[:options] || {})
        m.vm.synced_folder folder_src, folder_dst, **folder_opts
      end
      machine.delete :synced_folders

      # Debug print :)
      PP.pp(m.vm) unless not debug_mode

      # Here we should iterate through the rest of the metadata hash and
      # perform sets for the rest of the config
      (machine || {}).each do |cfg, values|
        target = m.vm.send(cfg)
        (values || {}).each do |k, v|
          if is_function target, k then
            target.send(k, v)
          else
            set_property target, k, v
          end
        end
      end

      # Machine callback
      callbacks[:machine].call(m)
    end
  end

  # Config callback
  callbacks[:config].call(config)
end
