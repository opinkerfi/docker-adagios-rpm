############################################################
# Dockerfile to build a Naemon/Adagios server
# Based on appcontainers/nagios
############################################################

FROM centos/systemd
MAINTAINER "Gardar Thorsteinsson" <gardart@gmail.com>

ENV ADAGIOS_HOST adagios.local
ENV ADAGIOS_USER thrukadmin
ENV ADAGIOS_PASS thrukadmin

# First install the opensource.is and consol labs repositories
RUN rpm -ihv http://opensource.is/repo/ok-release.rpm
RUN rpm -Uvh https://labs.consol.de/repo/stable/rhel7/x86_64/labs-consol-stable.rhel7.noarch.rpm
RUN yum update -y ok-release

# Redhat/Centos users need to install the epel repositories (fedora users skip this step)
RUN yum install -y epel-release

RUN yum clean all && yum -y update

# Install naemon, adagios and other needed packages
RUN yum --enablerepo=ok-testing install -y naemon naemon-livestatus git adagios okconfig acl pnp4nagios python-setuptools postfix python-pip

# Now all the packages have been installed, and we need to do a little bit of
# configuration before we start doing awesome monitoring

# Lets make sure adagios can write to naemon configuration files, and that
# it is a valid git repo so we have audit trail
WORKDIR /etc/naemon
RUN git init /etc/naemon
RUN git config user.name "admin"
RUN git config user.email "admin@adagios.local"
RUN git add .
RUN git commit -a -m "Initial commit"

# Fix permissions for naemon and pnp4nagios
RUN chown -R naemon:naemon /etc/naemon /etc/adagios /var/lib/adagios /var/lib/pnp4nagios /var/log/pnp4nagios /var/spool/pnp4nagios /etc/pnp4nagios/process_perfdata.cfg /var/log/okconfig
# ACL group permissions need g+rwx
RUN chmod g+rwx -R /etc/naemon /etc/adagios /var/lib/adagios /var/lib/pnp4nagios /var/log/pnp4nagios /var/spool/pnp4nagios /etc/pnp4nagios/process_perfdata.cfg /var/log/okconfig
RUN setfacl -R -m group:naemon:rwx -m d:group:naemon:rwx /etc/naemon/ /etc/adagios /var/lib/adagios /var/lib/pnp4nagios  /var/log/pnp4nagios /var/spool/pnp4nagios /etc/pnp4nagios/process_perfdata.cfg /var/log/okconfig

# Make sure nagios doesn't interfere
RUN mkdir /etc/nagios/disabled
RUN mv /etc/nagios/{nagios,cgi}.cfg /etc/nagios/disabled/

# Make objects created by adagios go to /etc/naemon/adagios
RUN mkdir -p /etc/naemon/adagios
RUN pynag config --append cfg_dir=/etc/naemon/adagios

# Make adagios naemon aware
RUN sed 's|/etc/nagios/passwd|/etc/thruk/htpasswd|g' -i /etc/httpd/conf.d/adagios.conf
RUN sed 's|user=nagios|user=naemon|g' -i /etc/httpd/conf.d/adagios.conf
RUN sed 's|group=nagios|group=naemon|g' -i /etc/httpd/conf.d/adagios.conf

RUN sed 's|/etc/nagios/nagios.cfg|/etc/naemon/naemon.cfg|g' -i /etc/adagios/adagios.conf
RUN sed 's|nagios_url = "/nagios|nagios_url = "/naemon|g' -i /etc/adagios/adagios.conf
RUN sed 's|/etc/nagios/adagios/|/etc/naemon/adagios/|g' -i /etc/adagios/adagios.conf
RUN sed 's|/etc/init.d/nagios|/etc/init.d/naemon|g' -i /etc/adagios/adagios.conf
RUN sed 's|nagios_service = "nagios"|nagios_service = "naemon"|g' -i /etc/adagios/adagios.conf
RUN sed 's|livestatus_path = None|livestatus_path = "/var/cache/naemon/live"|g' -i /etc/adagios/adagios.conf
RUN sed 's|/usr/sbin/nagios|/usr/bin/naemon|g' -i /etc/adagios/adagios.conf

# Make okconfig naemon aware
RUN sed 's|/etc/nagios/nagios.cfg|/etc/naemon/naemon.cfg|g' -i /etc/okconfig.conf
RUN sed 's|/etc/nagios/okconfig/|/etc/naemon/okconfig/|g' -i /etc/okconfig.conf
RUN sed 's|/etc/nagios/okconfig/examples|/etc/naemon/okconfig/examples|g' -i /etc/okconfig.conf

RUN okconfig init
RUN okconfig verify

# Add naemon to apache group so it has permissions to pnp4nagios's session files
RUN usermod -G apache naemon

# Allow Adagios to control the service
RUN sed 's|nagios|naemon|g' -i /etc/sudoers.d/adagios
RUN sed 's|/usr/sbin/naemon|/usr/bin/naemon|g' -i /etc/sudoers.d/adagios

# Make naemon use nagios plugins, more people are doing it like that.
RUN sed -i 's|/usr/lib64/naemon/plugins|/usr/lib64/nagios/plugins|g' /etc/naemon/resource.cfg

# Configure pnp4nagios
RUN sed -i 's|/etc/nagios/passwd|/etc/thruk/htpasswd|g' /etc/httpd/conf.d/pnp4nagios.conf
RUN sed -i 's|user = nagios|user = naemon|g' /etc/pnp4nagios/npcd.cfg
RUN sed -i 's|group = nagios|group = naemon|g' /etc/pnp4nagios/npcd.cfg

# Enable Naemon performance data
RUN pynag config --set "process_performance_data=1"

# service performance data
RUN pynag config --set 'service_perfdata_file=/var/lib/naemon/service-perfdata'
RUN pynag config --set 'service_perfdata_file_template=DATATYPE::SERVICEPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tSERVICEDESC::$SERVICEDESC$\tSERVICEPERFDATA::$SERVICEPERFDATA$\tSERVICECHECKCOMMAND::$SERVICECHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$\tSERVICESTATE::$SERVICESTATE$\tSERVICESTATETYPE::$SERVICESTATETYPE$'
RUN pynag config --set 'service_perfdata_file_mode=a'
RUN pynag config --set 'service_perfdata_file_processing_interval=15'
RUN pynag config --set 'service_perfdata_file_processing_command=process-service-perfdata-file'

# host performance data
RUN pynag config --set 'host_perfdata_file=/var/lib/naemon/host-perfdata'
RUN pynag config --set 'host_perfdata_file_template=DATATYPE::HOSTPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tHOSTPERFDATA::$HOSTPERFDATA$\tHOSTCHECKCOMMAND::$HOSTCHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$'
RUN pynag config --set 'host_perfdata_file_mode=a'
RUN pynag config --set 'host_perfdata_file_processing_interval=15'
RUN pynag config --set 'host_perfdata_file_processing_command=process-host-perfdata-file'

RUN pynag add command command_name=process-service-perfdata-file command_line='/bin/mv /var/lib/naemon/service-perfdata /var/spool/pnp4nagios/service-perfdata.$TIMET$'
RUN pynag add command command_name=process-host-perfdata-file command_line='/bin/mv /var/lib/naemon/host-perfdata /var/spool/pnp4nagios/host-perfdata.$TIMET$'

RUN pynag config --append cfg_dir=/etc/naemon/commands/

RUN mv /etc/httpd/conf.d/thruk_cookie_auth_vhost.conf /etc/httpd/conf.d/thruk_cookie_auth_vhost.conf.disabled

RUN htpasswd -b /etc/thruk/htpasswd "$ADAGIOS_USER" "$ADAGIOS_PASS" 
RUN rm -f /etc/nagios/passwd
RUN ln -s /etc/thruk/htpasswd /etc/nagios/passwd

# Redirect root URL to /adagios
RUN echo "RedirectMatch ^/$ /adagios" > /etc/httpd/conf.d/redirect.conf

# Fix permissions for naemon and pnp4nagios
RUN chown -R naemon:naemon /etc/naemon /etc/adagios /var/lib/adagios /var/lib/pnp4nagios /var/log/pnp4nagios /var/spool/pnp4nagios /etc/pnp4nagios/process_perfdata.cfg /var/log/okconfig
# ACL group permissions need g+rwx
RUN chmod g+rwx -R /etc/naemon /etc/adagios /var/lib/adagios /var/lib/pnp4nagios /var/log/pnp4nagios /var/spool/pnp4nagios /etc/pnp4nagios/process_perfdata.cfg /var/log/okconfig
RUN setfacl -R -m group:naemon:rwx -m d:group:naemon:rwx /etc/naemon/ /etc/adagios /var/lib/adagios /var/lib/pnp4nagios  /var/log/pnp4nagios /var/spool/pnp4nagios /etc/pnp4nagios/process_perfdata.cfg /var/log/okconfig

# Enable services
RUN systemctl enable httpd
RUN systemctl enable naemon
RUN systemctl enable npcd

# Remove yum cache
RUN rm -rf /var/cache/yum

WORKDIR /etc/naemon

EXPOSE 80

VOLUME ["/etc/naemon", "/var/log/naemon"]
CMD ["/usr/sbin/init"]
