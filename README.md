# Puppet-Subscription_manager

This module provides Custom Puppet Provider to handle registration and
consumption of RedHat subscriptions using subscription-manager. This module was
derived from [puppet-rhnreg_ks module](https://github.com/strider/puppet-rhnreg_ks) by Gaël Chamoulaud.

Due to various terminology differences between RHN Satellite, the upstream
Katello project and the further upstream component projects of Candlepin, The
Foreman, Puppet and Dogtag that the names of properties and resources may be
confusing.

## License

Apache License, Version 2.0. Read the LICENSE file for details of the licensing.

## Requirements
* puppet-boolean [on GitHub](https://github.com/adrienthebo/puppet-boolean)

## Authors
* Gaël Chamoulaud (gchamoul at redhat dot com)
* James Laska (jlaska at redhat dot com)
* JD Powell (waveclaw at hotmail dot com)

## Classes and Defines

This module provides the standard install-configure-service pattern. It also wraps
the provided native resources with a convenience class to enable simple or complex
deployment.  A simple facter fact about the registered identity is provided.

## Examples

Setup to and register one CentOS 6 client to a Katello server using a public
repositry to obtain the agent.

```puppet
# Place this code in a .pp file some where on your Puppet's modulepath such
# as a file named subscription_manager.pp in a module named repo.  
# The autoloader will be triggered by the rhsm module to search for this class.
class repo::subscription_manager {
  yumrepo { 'dgoodwin-subscription-manager':
  ensure              => 'present',
  baseurl             => 'https://copr-be.cloud.fedoraproject.org/results/dgoodwin/subscription-manager/epel-6-$basearch/',
  descr               => 'Copr repo for subscription-manager owned by dgoodwin',
  enabled             => '1',
  gpgcheck            => '1',
  gpgkey              =>  'https://copr-be.cloud.fedoraproject.org/results/dgoodwin/subscription-manager/pubkey.gpg',
    skip_if_unavailable => 'True',
  }
}

# Place this this in either a raw .pp manifest, a profile-like module or
# classify the node to require subscription_manager with these parameters in
# your ENC.
class { 'subscription_manager':
    repo            => 'repo::subscription_manager',
    server_hostname => 'my_katello.example.com',
    activationkeys  => '1-2-3-example.com-key',
    force           => true,
    org             => 'My_Example_Org',
    server_prefix   => '/rhsm',
    rhsm_baseurl    => 'https://my_katello.example.com/pulp/repos',
  }
}
```

Register a RedHat Enterprise 7 or CentOS 7 node to the RedHat Network with
Satellite 6.

```puppet
Class { 'subscription_manager':
   org           => 'My_Company_Org_in_RHN',
   username      => 'some_rhn_special_user',
   password      => 'password123',
   autosubscribe => true,
   servicelevel  => 'STANDARD',
}
```
Putting the explicit password in the code is a *bad* idea. Using hiera-gpg or
hiera-eyaml back-ends is strongly encouraged for this example.

## Types and Providers

The module adds the following new types:

* `rhsm_register` for managing RedHat Subscriptions
* `rhsm_config`   for configurating RedHat Subscriptions
* `rhsm_repo`     for managing RedHat Subscriptions to Repositories
* `rhsm_override` for managing the Subscrption yumrepo override cache
* `rhsm_pool`     for managing RedHat Entitlement Pools (Satellite Subscription Collections)

### rhsm_register

#### Parameters

##### Mandatory

- **server_hostname**: Specify a registration server hostname such as subscription.rhn.redhat.com.
- **org**: provide an organization to join (defaults to the Default_Organization
)

On of either the activation key or a username and password combination is needed
to register.  Both cannot be provided and will cause an error.

- **activationkeys**: The activation key to use when registering the system (cannot be used with username and password)
- **password**: The password to use when registering the system
- **username**: The username to use when registering the system

##### Optional

- **pool**: A specific license pool to attach the system to. Can include a default view using the formant pool-name/view-name.
- **environment**: which environment to join at registration time
- **autosubscribe**: Enable automatic subscription to repositories based on default Pool settings. Must be false when using an activation key unless specifiying a service leve.
- **servicelevel**: provide automatic attachement to a service level in Satellite. Not applicable to katello installations.
- **force**: Should the registration be forced. Use this option with caution, setting it true will cause the system to be unregistered before running 'subscription-manager register'. Default value `false`.

### rhsm_register Examples

Register clients to RedHat Subscription Management using an activation key:

```puppet
rhsm_register { 'satelite.example.com':
  server_hostname => 'my-satelite.example.com',
  activationkeys => '1-myactivationkey',
}
```

Register clients to RedHat Subscription management using a username and password:

```puppet
rhsm_register { 'subscription.rhn.example.com':
  username        => 'myusername',
  password        => 'mypassword',
  autosubscribe   => true,
  force           => true,
}
```

Register clients to RedHat Subscription management and attach to a specific license pool:

```puppet
rhsm_register { 'subscription.rhn.example.com':
  username  => 'myusername',
  password  => 'mypassword',
  pool		  => 'mypoolid',
}
```

### rhsm_config

##### rhsm_config options

See the documentation at [RedHat Support](https://access.redhat.com/documentation/en-US/Red_Hat_Subscription_Management/1/html/RHSM/rhsm-config.html#tab.rhsm.conf-parameters) for details on the /etc/rhsm/rhsm.conf file.

The most important settings are given bellow

- **server_hostname**: Same as the title or name of the resource
- **server_insecure**: If HTTP is used or HTTPS with an untrusted certificate
- **server_prefix**: The subscription path.  Usually /subscription for RHN and /rhsm for a Katello installation.
- **rhsm_baseurl**: The Content base URL in case the registration server has no content. An example would be https://cdn.redhat.com or https://katello.example.com/pulp/repos

rhsmcerd is not the same as Katello's goferd.

##### rhsm_config Examples

```puppet
rhsm_config { 'katello.example.com':
    server_hostname             => 'katello.example.com',
    server_insecure             => false,
    server_port                 => 443,
    server_prefix               => '/rhsm',
    server_ssl_verify_depth     => 3,
    rhsm_baseurl                => 'https://katello.example.com/pulp/repos',
    rhsm_ca_cert_dir            => '/etc/rhsm/ca/',
    rhsm_consumercertdir        => '/etc/pki/consumer',
    rhsm_entitlementcertdir     => '/etc/pki/entitlement',
    rhsm_full_refresh_on_yum    => true,
    rhsm_manage_repos           => true,
    rhsm_pluginconfdir          => '/etc/rhsm/pluginconf_d',
    rhsm_plugindir              => '/usr/share/rhsm-plugins',
    rhsm_productcertdir         => '/etc/pki/product',
    rhsm_repo_ca_cert           => '/etc/rhsm/ca/',
    rhsm_report_package_profile => 1,
    rhsmcertd_autoattachinterval => 1440,
}
```

### rhsm_repo

#### rhsm_repo Parameters

If absolutely necessary the individual yum repositories can be filtered.

- **ensure**: Valid values are `present`, `absent`. Default value is `present`.
- **name**: The name of the repository registration to filter.

#### rhsm_repo Examples

Example of a repository from an override

Example of a repository from the Server

```puppet
rhsm_repo { 'rhel-6-server-java-rpms':
  ensure        => present, # equal to the enabled property
  url           => 'https://katello.example.com/pulp/repos/abc-corp/production/reg-key-1/content/dist/rhel/server/6/6Server/$basearch/java-repo/os',
  content_label => 'rhel-6-java-rpms',
  id            => 'rhel-6-java-rpms',
  name          => 'RedHat Enterprise Linux 6 Server - Java (RPMs)',
  repo_type     => channel,
}
```

### rhsm_override

## rhsm_override Example

This is returned by the Puppet resource command but it not managable in a
meaningful way through the type.

```puppet
rhsm_repo { 'rhel-server6-epel':
  ensure        => present, # equal to the enabled property
  updated       => 2015-07-17T14:26:35.064+0000,
  created       => 2015-07-17T14:26:35.064+0000,
  content_label => 'rhel-server6-epel'
  repo_type     => override,
}
```

### rhsm_pool

Subscriptions to use RHN are sold as either individual entitlements or a pools of
entitlements.  A given server registered to a Satellite 6 or katello system will
consume at least 1 entitlement from a Pool just.

This subscription to the Pool is what enables the set of repositories to be made
available on the server for further subscription.

While this type is mostly useful for exporting the registration information in detail
it can also be used to force switch registrations for selected clients.

### rhsm_pool Parameters
- **name**: Unique Textual description of the Pool
- **ensure**: Is this pool absent or present?
- **provides**: Textual information about the Pool, usually same as the name.
- **sku**: Stockkeeping Unit, usually for inventory tracking
- **account**: Account number for this Pool of Subscriptions
- **contract**: Contract details, if known
- **serial**: Any serial number that is associated with the pool
- **id**: ID Hash of the Pool
- **active**: Is this subscription in use at the moment?
- **quantity_used**: How many is used?  Often licenses are sold by CPU or core so
is it possible for a single server to consume several subscriptions.
- **service_type**: type of service, usually relevant to official RedHat Channels
- **service_level**: level of service such as STANDARD, PREMIUM or SELF-SUPPORT
- **status_details**: Status detail string
- **subscription_type**: Subscription - type
- **starts**: Earliest date and time the subscription is valid for
- **ends**: When does this subscription expire
- **system_type**: Is this a phyiscal, container or virtual system?

### rhsm_pool Example

```puppet
rhsm_pool { '1a2b3c4d5e6f1234567890abcdef12345':
  name              => 'Extra Packages for Enterprise Linux',
  ensure            => present,
  provides          => 'EPEL',
  sku               => 1234536789012,
  contract          => 'Fancy Widgets, LTD',
  account           => '1234-12-3456-0001',
  serial            => 1234567890123456789,
  id                => 1a2b3c4d5e6f1234567890abcdef12345,
  active            => true,
  quantity_used     => 1,
  service_level     => 'STANDARD',
  service_type      => 'EOL',
  status_details    => 'expired',
  subscription_type => 'permanent',
  starts            => 06/01/2015,
  ends              => 05/24/2045,
  system_type       => physical,
}
```

## Installing

For released version the module can be installed with the Puppet module tool from the Puppet Forge.

For pre-release code the GitHub repository can be cloned.

In your puppet modules directory:

    git clone https://github.com/jlaska/puppet-subscription_manager.git

Ensure the module is present in your puppetmaster's own environment (it doesn't
have to use it) and that the master has pluginsync enabled.  Run the agent on
the puppetmaster to cause the custom types to be synced to its local libdir
(`puppet master --configprint libdir`) and then restart the puppetmaster so it
loads them.

## Issues

Please file any issues or suggestions on [on GitHub](https://github.com/jlaska/puppet-subscription_manager/issues)
