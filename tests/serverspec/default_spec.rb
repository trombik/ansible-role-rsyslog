require "spec_helper"
require "serverspec"

service = "rsyslog"
config  = "/etc/rsyslog.conf"
ports   = [514]
conf_d_dirs = ["/etc/rsyslog.d"]

describe file(config) do
  it { should exist }
  it { should be_file }
  it { should be_mode 644 }
  its(:content) { should match Regexp.escape("Managed by ansible") }
end

conf_d_dirs.each do |d|
  describe file d do
    it { should exist }
    it { should be_directory }
    it { should be_mode 755 }
  end
end

describe file "/etc/rsyslog.d/foo.conf" do
  it { should exist }
  it { should be_file }
  it { should be_mode 775 }
  its(:content) { should match(/Managed by ansible/) }
end

case os[:family]
when "ubuntu"
  describe file "/etc/default/rsyslog" do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    its(:content) { should match(/Managed by ansible/) }
  end
when "redhat"
  describe file "/etc/sysconfig/rsyslog" do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    its(:content) { should match(/Managed by ansible/) }
  end
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
