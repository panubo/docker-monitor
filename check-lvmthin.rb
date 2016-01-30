#!/usr/bin/env ruby
#
#  check-lvmthin
#
# DESCRPTION:
#  Uses lvs to get lvm thin pool data and metadata usage
#
# OUTPUT:
#  plain text
#
# PLATFORMS:
#  Linux
#
# DEPENDENCIES:
#  gem: sensu-plugin
#  pkg: lvm2
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#  Copyright 2016 Panubo <admin@panubo.com>
#  Released un the MIT license
#  Based off check-disks-usage.rb from https://github.com/sensu-plugins/sensu-plugins-disk-checks
#

require 'sensu-plugin/check/cli'

#
# Check LVM Thin
#
class CheckLVMThin < Sensu::Plugin::Check::CLI
  option :warn,
         short: '-w PERCENT',
         description: 'Warn if PERCENT or more of pool full',
         proc: proc(&:to_i),
         default: 85

  option :crit,
         short: '-c PERCENT',
         description: 'Critical if PERCENT or more of pool full',
         proc: proc(&:to_i),
         default: 95

  # Setup variables
  #
  def initialize
    super
    @crit_pool = []
    @warn_pool = []
  end

  # Get thin pool info
  #
  def thin_pools
    `sudo lvs --noheadings --separator : -o lv_attr,lv_name,data_percent,metadata_percent`.lines.each do |line|
      next unless line.strip =~ /^t/
      pool = {}
      pool[:attr], pool[:name], pool[:data_percent], pool[:metadata_percent] = line.strip.split(":")
      check_pool(pool)
    end
    unknown 'An error occured getting LVM info' unless $?.success?
  end

  # Check pool percents against thresholds
  #
  def check_pool(pool)
    crit = config[:crit]
    warn = config[:warn]

    if pool[:data_percent].to_f >= crit
      @crit_pool << "#{pool[:name]} #{pool[:data_percent]}% data usage"
    elsif pool[:data_percent].to_f >= warn
      @warn_pool << "#{pool[:name]} #{pool[:data_percent]}% data usage"
    end

    if pool[:metadata_percent].to_f >= crit
      @crit_pool << "#{pool[:name]} #{pool[:metadata_percent]}% metadata usage"
    elsif pool[:metadata_percent].to_f >= warn
      @warn_pool << "#{pool[:name]} #{pool[:metadata_percent]}% metadata usage"
    end
  end

  # Generate output
  #
  def usage_summary
    (@crit_pool + @warn_pool).join(', ')
  end

  # Main function
  #
  def run
    thin_pools
    critical usage_summary unless @crit_pool.empty?
    warning usage_summary unless @warn_pool.empty?
    ok "All pools usage under #{config[:warn]}%"
  end
end
