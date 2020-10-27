Vhd to Managed disk migration - Across subscriptions - Azure - Function
=======================================================================

            

This function can be used to create managed disks from an Azure Virtual Machine or a collection of Virtual Machines that is backed by legacy Vhd disks/blobs.


The Vhd disks are retained after creation, and can be removed manually.


The function has also been updated to perform cross subscription migrations.


Managed disks will retain configuration based on the Vhd blobs which is used by the Vm details passed into the function.


For more help see the help content and examples within the function. Verbose output is provided by using the verbose parameter.

 

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
