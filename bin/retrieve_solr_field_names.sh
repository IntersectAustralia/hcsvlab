if [ -z "$1" ]
then
    echo ""
    echo "USAGE:"
    echo "        retrieve_solr_field_names <solr_server_name>:<port>"
    echo ""
    exit 1
fi

echo "| SOLR FIELD NAME | FACETED | "
# Retrieve Faceted fields
curl -sS http://$1/solr/admin/luke?numTerms=0 | egrep -o  [a-zA-Z_]+_facet | sed 's/^/| /g' | sed 's/_facet/_facet | YES | /g';

# Retrieve NON Faceted fields
curl -sS http://$1/solr/admin/luke?numTerms=0 | egrep -o  [a-zA-Z_]+_tesim | sed 's/^/| /g' | sed 's/_tesim/_tesim | NO | /g';

