import getpass
import time
import os
from tabulate import tabulate
import datetime
#size of console
os.system('mode con cols=200 lines=25')
#password function


import mysql.connector
mydb = mysql.connector.connect(host='localhost',user='root',passwd='admin')
cx = mydb.cursor()
if mydb.is_connected:
    print('Connection to database successful.')
    time.sleep(1)

# Open and read the file as a single buffer
fd = open('gate_sys.sql', 'r')
sqlFile = fd.read()
fd.close()

role = 0
id = 0

while True:
    os.system('CLS')
    user = str(input("Enter your username: (5 characters long) "))
    t = getpass.getpass(prompt='Please Enter your Password: ')
    try:
        query = 'SELECT auth_driver(%s, %s)'
        cx.execute(query, (user, t))
        result = cx.fetchall()
        authd = result[0][0]
    except mysql.connector.Error as e:
        print(f"Something went wrong. {e}")
        break
    try:
        query = 'SELECT auth_guard(%s, %s)'
        cx.execute(query, (user, t))
        result = cx.fetchall()
        authg = result[0][0]
    except mysql.connector.Error as e:
        print(f"Something went wrong. {e}")
        break
    try:
        query = 'SELECT auth_manager(%s, %s)'
        cx.execute(query, (user, t))
        result = cx.fetchall()
        authm = result[0][0]
    except mysql.connector.Error as e:
        print(f"Something went wrong. {e}")
        break
    if (authd == 1):
        role = "driver"
        id = user
        print(f"Login Successful. Welcome User {user}\n")
        break
    elif (authg == 1):
        role = "guard"
        id = user
        print(f"Login Successful. Welcome Guard {user} \n")
        break
    elif (authm == 1):
        role = "manager"
        id = user
        print(f"Login Successful. Welcome Manager {user} \n")
        break
    else:
        ch = str(input("Incorrect login. Would you like to reset your password? (y/n): "))
        if ch.lower() == 'y':
            id = str(input("Enter your id: "))
            if (id[0] == 'D'):
                aadhar = str(input("Enter your Aadhar No: "))
                new_pass = str(input("Enter your new password: "))
                query = 'SELECT reset_password_drivers(%s, %s, %s)'
                try:
                    cx.execute(query, (id, aadhar, new_pass))
                    result = cx.fetchall()
                    if (result[0][0] == 1):
                        print("Password Changed Successfully!")
                    else:
                        print("Please check your Aadhar details!")
                except mysql.connector.Error as e:
                    print(f"Something went wrong. {e}")
                    time.sleep(3)
            elif (id[0] == 'G'):
                aadhar = str(input("Enter your Aadhar No: "))
                new_pass = str(input("Enter your password: "))
                args = (id, aadhar, new_pass)
                try:
                    cx.callproc('reset_password_guard', args)
                    mydb.commit()
                    print("Password changed successfully!\n")
                    time.sleep(3)
                except mysql.connector.Error as e:
                    print(f"Something went wrong. {e}")
                    time.sleep(3)
            elif (id[0] == 'M'):
                aadhar = str(input("Enter your Aadhar No: "))
                new_pass = str(input("Enter your password: "))
                args = (id, aadhar, new_pass)
                try:
                    cx.callproc('reset_password_manager', args)
                    mydb.commit()
                    print("Password changed successfully!\n")
                    time.sleep(3)
                except mysql.connector.Error as e:
                    print(f"Something went wrong. {e}")
                    time.sleep(3)
        else:
            print("Going back to home screen...")
            time.sleep(3)

if (role == "driver"):
    while True:
        os.system('CLS')
        print("Welcome to the User menu.")
        print('01.Register Vehicle')
        print('02.Deregister Vehicle')
        print('03.Update Phone')
        print('04.Update Email')
        print('05.Update Address')
        print('06.Obtain Information')
        print('07.Obtain User Logs')
        print('8.Exit')
        ch = int(input('Enter your choice: '))
        if (ch == 1):
            os.system('CLS')
            vin_no = str(input("Enter the VIN no of the vehicle: "))
            model = str(input("Enter the model of the vehicle: "))
            new_type = str(input("Enter the type of the vehicle (Car/Bike/Scooter/SUV): "))
            color = str(input("Enter the color of the vehicle: "))
            args = (id, vin_no, model, new_type, color)
            try:
                cx.callproc('register_vehicle', args)
                mydb.commit()
                print("Vehicle Registered Successfully!\n")
                time.sleep(3)
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 2):
            os.system('CLS')
            vin_no = str(input("Enter the VIN no for deregistration: "))
            args = (id, vin_no)
            try:
                cx.callproc('deregister_vehicle', args)
                mydb.commit()
                print("Vehicle deregistered Successfully!\n")
                time.sleep(3)
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 3):
            os.system('CLS')
            phone = str(input("Enter your new phone number: "))
            args = (id, phone)
            try:
                cx.callproc('update_user_phone', args)
                mydb.commit()
                print("Phone number updated successfully!\n")
                time.sleep(3)
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 4):
            os.system('CLS')
            email = str(input("Enter your new email id: "))
            args = (id, email)
            try:
                cx.callproc('update_user_email', args)
                mydb.commit()
                print("Email updated successfully!\n")
                time.sleep(3)
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 5):
            os.system('CLS')
            house = int(input("Enter you new house number: "))
            street = str(input("Enter your new street: "))
            city = str(input("Enter your new city: "))
            pincode = int(input("Enter your new pincode: "))
            args = (id, house, street, city, pincode)
            try:
                cx.callproc('update_user_address', args)
                mydb.commit()
                print("Address updated successfully.\n")
                time.sleep(3)
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 6):
            os.system('CLS')
            args = (id,)
            try:
                cx.callproc('obtain_user_data', args)
                for result in cx.stored_results():
                    data = result.fetchall()
                print(tabulate(data, headers=['Driver ID','First Name','Last Name', 'Phone No', 'Email', 'Sex', 'House No', 'Street', 'City', 'Pincode', 'DOB', 'Vehicle Count' ], tablefmt='psql'))
                z = input('Press Enter To Continue')
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 7):
            os.system('CLS')
            args = (id,)
            try:
                cx.callproc('obtain_logs', args)
                for result in cx.stored_results():
                    data = result.fetchall()
                print(tabulate(data, headers=['VIN No', 'Status (0 = OUT, 1 = IN)','Log Time', 'Log Date' ], tablefmt = 'psql'))
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 8):
            os.system('CLS')
            print("Thank You for using the Gate Management System!")
            time.sleep(3)
            break
        else:
            os.system('CLS')
            print("Invalid Input!")
            time.sleep(2)
elif (role == "guard"):
    while True:
        os.system('CLS')
        print("Welcome to the Guard menu.")
        print('01.Record Entry Time')
        print('02.Record Exit Time')
        print('03.Obtain Logs')
        print('04.Search Vehicle No')
        print('05.Search Vehicle By Owner')
        print('06.Search Vehicle By District')
        print('07.Exit')
        ch = int(input('Enter your choice: '))
        if (ch == 1):
            os.system('CLS')
            vehicle_no = str(input("Enter vehicle no: "))
            args = (id, vehicle_no)
            try:
                cx.callproc('record_entry_time', args)
                mydb.commit()
                print("Entry logged succesfully!\n")
                time.sleep(3)
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 2):
            os.system('CLS')
            vehicle_no = str(input("Enter vehicle no: "))
            args = (id, vehicle_no)
            try:
                cx.callproc('record_exit_time', args)
                mydb.commit()
                print("Entry logged succesfully!\n")
                time.sleep(3)
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 3):
            os.system('CLS')
            query = 'SELECT * from log ORDER BY log_date DESC, log_time DESC'
            cx.execute(query)
            result = cx.fetchall()
            print(tabulate(result, headers=['VIN No', 'Status (0 = OUT, 1 = IN)', 'Log Time', 'Log Date', 'Logged By ID']))
            z = input("\nPress Enter to continue.")
        elif (ch == 4):
            os.system('CLS')
            vehicle_no = str(input("Enter vehicle no: "))
            args = (vehicle_no,)
            try:
                cx.callproc('search_vin_no', args)
                for result in cx.stored_results():
                    data = result.fetchall()
                print(tabulate(data, headers=['VIN No', 'Model', 'Type', 'Color', 'Owner ID']))
                z = input("\nPress enter to continue")
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 5):
            os.system('CLS')
            fname = str(input("Enter first name: "))
            lname = str(input("Enter last name: "))
            args = (fname, lname)
            try:
                cx.callproc('search_owner_name', args)
                for result in cx.stored_results():
                    data = result.fetchall()
                print(tabulate(data, headers=['VIN No', 'Model', 'Type', 'Color', 'Owner ID']))
                z = input("\nPress Enter to continue")
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 6):
            os.system('CLS')
            pin = int(input("Enter pincode of district: "))
            args = (pin,)
            try:
                cx.callproc('search_vehicle_by_pin', args)
                for result in cx.stored_results():
                    data = result.fetchall()
                print(tabulate(data, headers=['VIN No', 'Model', 'Type', 'Color', 'Owner ID']))
                z = input("\nPress Enter to continue")
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 7):
            os.system('CLS')
            print("Thank You for using the Gate Management System!")
            time.sleep(3)
            break
        else:
            os.system('CLS')
            print("Invalid Choice!")
            time.sleep(2)
elif (role == "manager"):
    while True:
        os.system('CLS')
        print("Welcome to the Manager menu.")
        print('01.Create User')
        print('02.Create Guard')
        print('03.Delete User')
        print('04.Delete Guard')
        print('05.Obtain Peak Hours')
        print('06.Obtain Registered Models')
        print('07.Obtain User Data')
        print('08.Obtain Guard Data')
        print('09.Obtain Vehicles In')
        print('10.Obtain Vehicles Out')
        print('11.Exit')
        ch = int(input('Enter your choice: '))
        if (ch == 1):
            os.system('CLS')
            new_id = str(input("Enter the ID of the new user: "))
            fname = str(input("Enter the first name of the user: "))
            lname = str(input("Enter the last name of the user: "))
            phone = str(input("Enter the phone number of the user: "))
            mail = str(input("Enter the email of the user: "))
            sex = str(input("Enter the sex of the user(M/F/Leave Blank if prefer not to specify)"))
            house = str(input("Enter the house number of the user: "))
            street = str(input("Enter the street of the user: "))
            city = str(input("Enter the city of the user: "))
            pin = int(input("Enter the pincode of the area the user lives in: "))
            dob = str(input("Enter the date of birth of the user(YYYY-MM-DD): "))
            aadhar = str(input("Enter the Aadhar Number of the User: "))
            args = (new_id, fname, lname, phone, mail, sex, house, street, city, pin, dob, aadhar, id)
            try:
                cx.callproc('create_user', args)
                mydb.commit()
                print(f"User {new_id} added successfully.\n")
                time.sleep(3)
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 2):
            os.system('CLS')
            new_id = str(input("Enter the ID of the new guard: "))
            fname = str(input("Enter the first name of the guard: "))
            lname = str(input("Enter the last name of the guard: "))
            phone = str(input("Enter the phone number of the guard: "))
            mail = str(input("Enter the email of the guard: "))
            sex = str(input("Enter the sex of the guard(M/F/Leave Blank if prefer not to specify)"))
            dob = str(input("Enter the date of birth of the guard(YYYY-MM-DD): "))
            aadhar = str(input("Enter the Aadhar Number of the guard: "))
            args = (new_id, fname, lname, phone, mail, dob, aadhar, id)
            try:
                cx.callproc('create_user', args)
                mydb.commit()
                print(f"Guard {new_id} added successfully.\n")
                time.sleep(3)
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 3):
            os.system('CLS')
            del_id = str(input("Enter the ID of the user to be deleted: "))
            args = (del_id,)
            try:
                cx.callproc('delete_user', args)
                mydb.commit()
                print(f"User {del_id} deleted successfully!")
                time.sleep(3)
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 4):
            os.system('CLS')
            del_id = str(input("Enter the ID of the guard to be deleted: "))
            args = (del_id,)
            try:
                cx.callproc('delete_guard', args)
                mydb.commit()
                print(f"Guard {del_id} deleted successfully!")
                time.sleep(3)
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 5):
            os.system('CLS')
            try:
                cx.callproc('obtain_peak_hour')
                for result in cx.stored_results():
                    data = result.fetchall()
                print(tabulate(data, headers=['Peak Hour(24 hour time)', 'Peak Vehicle Movement']))
                z = input("\nPress Enter to continue.")
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 6):
            os.system('CLS')
            try:
                cx.callproc('obtain_registered_models')
                for result in cx.stored_results():
                    data = result.fetchall()
                print(tabulate(data, headers=['Vehicle Type', 'Count']))
                z = input("\nPress Enter to continue.")
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 7):
            os.system('CLS')
            try:
                query = 'SELECT * from viewUserData'
                cx.execute(query)
                result = cx.fetchall()
                print(tabulate(result, headers=['Driver ID','First Name','Last Name', 'Phone No', 'Email', 'Sex', 'House No', 'Street', 'City', 'Pincode', 'DOB', 'Vehicle Count' ], tablefmt='psql'))
                z = input("\nPress Enter to continue.")
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 8):
            os.system('CLS')
            try:
                query = 'SELECT * from viewGuardData'
                cx.execute(query)
                result = cx.fetchall()
                print(tabulate(result, headers=['Guard ID','First Name','Last Name', 'Phone No', 'Email', 'Sex', 'DOB', 'Aadhar'], tablefmt='psql'))
                z = input("\nPress Enter to continue.")
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)  
        elif (ch == 9):
            os.system('CLS')
            try:
                cx.callproc('obtain_vehicles_in')
                for result in cx.stored_results():
                    data = result.fetchall()
                count = data[0][0]
                print(f"There are currently {count} cars in the lot.")
                z = input("\nPress Enter to continue.")
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 10):
            os.system('CLS')
            try:
                cx.callproc('obtain_vehicles_out')
                for result in cx.stored_results():
                    data = result.fetchall()
                count = data[0][0]
                print(f"There are currently {count} cars outside.")
                z = input("\nPress Enter to continue.")
            except mysql.connector.Error as e:
                print(f"Something went wrong. {e}\n")
                time.sleep(3)
        elif (ch == 11):
            os.system('CLS')
            print("Thank You for Using the Gate Management System!")
            time.sleep(3)
            break
        else:
            os.system('CLS')
            print("Invalid Input!")
            time.sleep(2)