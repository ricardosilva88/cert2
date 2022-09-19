*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             html_tables.py
Library             RPA.PDF
Library             Screenshot
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.Dialogs
Library            RPA.Robocorp.Vault

Task Teardown       Close All Browsers

*** Variables ***
#${FILE_URL}      https://robotsparebinindustries.com/orders.csv

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${FILE_URL}=    Get file path from vault
    Log To Console    ${FILE_URL} 
    Open the robot order website
    ${orders}=    Get orders    ${FILE_URL}
    FOR    ${row}    IN    @{orders}
        Log To Console    -------------------- 
        Close the annoying modal   
        Fill the form    ${row}       
        Wait Until Keyword Succeeds    5x    500ms    Preview the robot
        Wait Until Keyword Succeeds    5x    500ms    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        Log To Console    ${pdf}     
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Log To Console    ${screenshot} 
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Log To Console    -------------------- 
        Go to order another robot
     END
     Create a ZIP file of the receipts



*** Keywords ***
#Get file path dialog
#    Add text input    search    label=Search query
#    ${response}=    Run dialog
#    RETURN    ${response.search}

Get file path from vault
    ${secret}=    Get Secret    settings
    RETURN    ${secret}[url]

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order  

Close the annoying modal
    Click Button When Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Get orders
    [Arguments]    ${FILE_URL}
    Download    ${FILE_URL}    overwrite=True
    ${table}=    Read table from CSV    orders.csv
    RETURN    ${table}

Fill the form
    [Arguments]    ${row}
    Log To Console    ${row}
    ${partsTable}=    Wait Until Keyword Succeeds    5x    500ms    Read Parts IDs
    ## --- Not necessary, just for practice and debug
    ${headName}=    Get Part Name    ${partsTable}    ${row}[Head]
    ${bodyName}=    Get Part Name    ${partsTable}    ${row}[Body]
    ${legsName}=    Get Part Name    ${partsTable}    ${row}[Legs]
    ## ----
    Log To Console    ${headName}
    Log To Console    ${bodyName}
    Log To Console    ${legsName}
    Wait Until Element Is Visible    xpath://*[@id="head"]
    Select From List By Value    xpath://*[@id="head"]    ${row}[Head]
    Click Button    xpath://*[@id="id-body-${${row}[Body]}"]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    xpath://*[@id="address"]   ${row}[Address]
    
    
Read Parts IDs
    ${html_table}=    Get ID parts HTML table
    ${table}=    Read Table From Html    ${html_table}
    RETURN    ${table}

Get ID parts HTML table
    Click Button When Visible    xpath://*[@id="root"]/div/div[1]/div/div[2]/div[1]/button
    ${html_table}=    Get Element Attribute    id:model-info    outerHTML
    RETURN    ${html_table}

Get Part Name
    [Arguments]    ${partsTable}    ${partId}
    FOR    ${row}    IN    @{partsTable}
        IF    ${row.get(1)} == ${partId}
            RETURN    ${row.get(0)}
        END
    END

Preview the robot
    Click Button When Visible    preview

Submit the order
    Click Button   order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_results_html}=    Get Element Attribute    id:receipt    outerHTML
    ${receipt_path}    Set Variable    ${OUTPUT_DIR}${/}files${/}receipt_${order_number}.pdf
    Html To Pdf    ${receipt_results_html}    ${receipt_path}
    RETURN    ${receipt_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${screen_path}    Set Variable    ${OUTPUT_DIR}${/}files${/}screen_${order_number}.jpg
    Take Screenshot    ${screen_path}
    RETURN    ${screen_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}:align=center
    Add Files To PDF    ${files}    ${pdf}

Go to order another robot
    Click Button   order-another

Create a ZIP file of the receipts
    Archive Folder With Zip  ${OUTPUT_DIR}${/}files     ${OUTPUT_DIR}${/}robotout.zip
    Remove Directory    ${OUTPUT_DIR}${/}files    True
    
