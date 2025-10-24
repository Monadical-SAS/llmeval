#!/bin/bash

# Create input directory
mkdir -p input
cd input

# Create contacts.csv with header
cat > contacts.csv << 'EOF'
name,email,phone,company
Alice Johnson,alice.j@techcorp.com,555-0101,TechCorp
Bob Martinez,bob.m@example.com,555-0102,Example Inc
Carol White,carol.white@startup.io,555-0103,Startup IO
David Chen,david.chen@bigco.com,555-0104,BigCo
Emma Wilson,emma.w@smallbiz.net,555-0105,SmallBiz
Frank Brown,frank.b@agency.com,555-0106,Agency Co
Grace Lee,grace.lee@consulting.com,555-0107,Consulting
Henry Davis,henry.d@finance.com,555-0108,Finance Corp
Iris Taylor,iris.taylor@media.com,555-0109,Media Co
Jack Anderson,jack.a@retail.com,555-0110,Retail Corp
Karen Thomas,karen.t@healthcare.com,555-0111,HealthCare
Larry Moore,larry.m@education.org,555-0112,Education
Monica Jackson,monica.j@nonprofit.org,555-0113,NonProfit
Nathan Harris,nathan.h@logistics.com,555-0114,Logistics
Olivia Martin,olivia.m@travel.com,555-0115,Travel Agency
Paul Garcia,paul.g@restaurant.com,555-0116,Restaurant
Quinn Rodriguez,quinn.r@hotel.com,555-0117,Hotel Group
Rachel Lewis,rachel.l@bookstore.com,555-0118,Bookstore
Steve Walker,steve.w@gym.com,555-0119,Gym Corp
Tina Hall,tina.h@salon.com,555-0120,Salon
Uma Allen,uma.allen@law.com,555-0121,Law Firm
Victor Young,victor.y@architecture.com,555-0122,Architecture
Wendy King,wendy.k@design.com,555-0123,Design Studio
Xavier Wright,xavier.w@photography.com,555-0124,Photography
Yara Lopez,yara.l@music.com,555-0125,Music Studio
Zack Hill,zack.h@sports.com,555-0126,Sports Co
Anna Scott,anna.s@fashion.com,555-0127,Fashion Brand
Brian Green,brian.g@jewelry.com,555-0128,Jewelry Store
Chloe Adams,chloe.a@bakery.com,555-0129,Bakery
Derek Baker,derek.b@coffee.com,555-0130,Coffee Shop
Ella Nelson,ella.n@tea.com,555-0131,Tea House
Felix Carter,felix.c@wine.com,555-0132,Wine Bar
Gina Mitchell,gina.m@brewery.com,555-0133,Brewery
Hugo Perez,hugo.p@distillery.com,555-0134,Distillery
Isla Roberts,isla.r@vineyard.com,555-0135,Vineyard
John Smith,john.smith@example.com,555-1234,Acme Corp
J. Smith,jsmith@example.com,555-1234,Acme Corp
John Smith,john.smith@example.com,(555) 1234,Acme Corp
Sarah Johnson,sarah.j@company.com,555-2345,Company Ltd
Sarah Johnson,SARAH.J@COMPANY.COM,555-2345,Company Ltd
Michael Brown,mike.b@business.com,555-3456,Business Inc
M. Brown,mike.b@business.com,555-3456,Business Inc
Jennifer Davis,jennifer.d@firm.com,555-4567,Firm LLC
Jennifer Davis,jen.d@otherfirm.com,555-4567,Other Firm
Robert Wilson,robert.w@corp.com,555-5678,Corp Group
Robert Wilson,robert.w@corp.com,555 5678,Corp Group
Lisa Anderson,lisa.a@services.com,555-6789,Services Co
Lisa Anderson,lisa.anderson@services.com,555-6789,Services Co
Thomas Clark,thomas.c@tech.com,555-7890,Tech Inc
T. Clark,thomas.c@tech.com,555-7890,Tech Inc
EOF

echo "Created contacts.csv with 50 contacts (35 unique + 15 duplicates)"
