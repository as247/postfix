#!/bin/bash
if [ -z "$MAIL_DOMAIN" ]; then
    echo "MAIL_DOMAIN is not set. Please set the MAIL_DOMAIN environment variable."
    exit 1
fi
# Define the input and output files
input_file="/etc/opendkim/keys/$MAIL_DOMAIN.txt"
output_file="/dns/$MAIL_DOMAIN.txt"
if [ ! -f "$input_file" ]; then
    echo "Input file not found: $input_file"
    exit 1
fi

mkdir -p "/dns/"

## input file sample
#mail._domainkey	IN	TXT	( "v=DKIM1; h=sha256; k=rsa; "
#	  "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5UMPRNqkiyH12MH05IP15/+Q0IJGvj9g/agbrIo6D1GPQ1hTTkhGwrKgapReC+yzst650MbD/vBDnMk+upTCl5O5pdobQtGdp+CKZe+7nJ7QsyTmHH6tjZOb7kTB8sYEd8d+oQNnEoiD5LdEK67pOc4TmjEo2TcfmgP7iS+FQzktN9nvYy9+Ox6krO7YoafyGBzDF9v+7L05eg"
#	  "VpMH7jzPX0i7OE1OfSrMk7BK8MJJ1wHW8VCompZxfZ2YNBBL7IMm13PfvVud5Jx6A9CfckrE7RIL12+pIlrqnCBzQYVQC2aR+L3qnSp/BMrdml3d+UPW7YXsX3xWbXcTDEbYdKoQIDAQAB" )  ; ----- DKIM key mail for tinyinstaller.top


# Extract the DNS name from the input file
dns_name=$(awk '/IN[ \t]+TXT/ {print $1}' $input_file)
txt_value=""
#Extract txt value loop each line from input file and get string between double quotes then append to txt_value
while IFS= read -r line
do
    txt_value+=$(echo $line | sed -n 's/.*"\(.*\)".*/\1/p')
done < $input_file

# Remove leading and trailing double quotes
txt_value=$(echo $txt_value | sed 's/^"\(.*\)"$/\1/')

# Output the DNS name and value to the output file
echo -e "${dns_name}\t1\tIN\tTXT\t${txt_value}" > $output_file

# display original key
# Display the DNS name and value
echo -e "\e[32mSet DNS setting to:\e[0m"
cat $output_file

echo "You also can check dns record in .$output_file"