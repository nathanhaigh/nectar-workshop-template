#!/usr/bin/perl
#####
# Usage nx_template2session_file.pl <template.nxs> <remote_ip> <remote_username> <remote_password> > <session_file.nxs>
#####
use warnings;
use strict;
use XML::Twig;
use Getopt::Long;
use File::Basename;		# fordirname()

my $template_file;
my $host_ip;
my $username;
my $password;
my $output_file;

GetOptions (
  'template=s' => \$template_file,
  'host=s'     => \$host_ip,
  'username=s' => \$username,
  'password=s' => \$password,
  'output=s'   => \$output_file
) or die("Error in command line arguments\n");
die "output filename ($output_file) cannot contain illegal characters: =,_\n" if $output_file =~ /[=,_]/;

my $dir_containing_this_script = dirname(__FILE__);
my $scrambled_password = `perl $dir_containing_this_script/nx_password_scrambler.pl $password`;

my $twig = XML::Twig->new(
  pretty_print => 'indented',
  keep_encoding => 1,
);
$twig->parsefile($template_file);
my $root = $twig->root;
my @groups = $root->children;
foreach my $group (@groups) {
  if ($group->{'att'}->{'name'} eq 'General') {
    my @options = $group->children;
    foreach my $option (@options) {
      if ($option->{'att'}->{'key'} eq 'Server host') {
        $option->set_att('value' => $host_ip);
      }
    }
  } elsif($group->{'att'}->{'name'} eq 'Login') {
    my @options = $group->children;
    foreach my $option (@options) {
      if ($option->{'att'}->{'key'} eq 'Auth') {
        $option->set_att('value' => $scrambled_password);
      } elsif ($option->{'att'}->{'key'} eq 'User') {
        $option->set_att('value' => $username);
      }
    }
  }
}
$twig->print_to_file($output_file);

