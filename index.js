const express = require('express');
const cors = require('cors');
var mysql = require('mysql');
const bodyParser = require('body-parser');


var db = mysql.createConnection({
    host:"localhost",
    user:"root",
    password:"admin",
    database:"gate"
});

const app = express()

app.use(bodyParser.urlencoded({extended: true}));
app.use(cors());
app.use(express.json());

app.post('/gate/driver_login', (req, res) => {
    const id = req.body.id;
    const pass = req.body.pass;

    const auth_query = `SELECT auth_driver(${id}, ${pass});`;
    
    db.query(auth_query, function (error, results) {
        if (error) res.send(error);
        else {
            var auth = Object.values(results[0])[0];
            if (auth == 1) {
                res.send("Login Successful!");
            } else {
                res.status(400).send({
                    message: "Can't login! Check credentials"
                });
            }
        }
    })
})

app.post('/gate/guards_login', (req, res) => {
    const id = req.body.id;
    const pass = req.body.pass;

    const auth_query = `SELECT auth_guard(${id}, ${pass});`;
    
    db.query(auth_query, function (error, results) {
        if (error) res.send(error);
        else {
            var auth = Object.values(results[0])[0];
            if (auth == 1) {
                res.send("Login Successful!");
            } else {
                res.status(400).send({
                    message: "Can't login! Check credentials!"
                });
            }
        }
    })
})

app.post('/gate/manager_login', (req, res) => {
    const id = req.body.id;
    const pass = req.body.pass;

    const auth_query = `SELECT auth_manager(${id}, ${pass});`;
    
    db.query(auth_query, function (error, results) {
        if (error) res.send(error);
        else {
            var auth = Object.values(results[0])[0];
            if (auth == 1) {
                res.send("Login Successful!");
            } else {
                res.status(400).send({
                    message: "Can't login! Check credentials"
                });
            }
        }
    })
})

app.post('/gate/driver/reset', (req, res) => {
    const id = req.body.id;
    const aadhar = req.body.aadhar;
    const new_pass = req.body.new_pass;

    const query = `SELECT reset_password_drivers(${id}, ${aadhar}, ${new_pass});`;

    db.query(query, function (error, results) {
        if (error) res.send(error);
        else {
            var auth = Object.values(results[0])[0];
            if (auth == 1) {
                res.status(200).send({
                    message: "Password change successful!"
                })
            } else {
                res.status(400).send({
                    message: "Unable to change password. Please check security question/id"
                })
            }
        }
    })
})

app.post('/gate/manager/reset', (req, res) => {
    const id = req.body.id;
    const aadhar = req.body.aadhar;
    const new_pass = req.body.new_pass;

    const query = `CALL reset_password_manager(${id}, ${aadhar}, ${new_pass});`;

    db.query(query, function (error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Password change successful"
        });
    })
})

app.post('/gate/guard/reset', (req, res) => {
    const id = req.body.id;
    const aadhar = req.body.aadhar;
    const new_pass = req.body.new_pass;

    const query = `CALL reset_password_guard(${id}, ${aadhar}, ${new_pass});`;

    db.query(query, function (error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Password change successful"
        });
    })
})

app.post('/gate/driver/register', (req, res) => {
    const id = req.body.id;
    const vin = req.body.vin;
    const model = req.body.model;
    const type = req.body.type;
    const color = req.body.color;

    const query = `CALL register_vehicle(${id}, ${vin}, ${model}, ${type}, ${color});`;

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Vehicle registered successfully!"
        })
    })
})

app.post('/gate/search_vin', (req, res) => {
    const vin = req.body.vin;

    const query = `CALL search_vin_no(${vin})`;

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send(results[0]);
    })
})

app.post('/gate/driver/deregister', (req, res) => {
    const id = req.body.id;
    const vin = req.body.vin;

    const query = `CALL deregister_vehicle(${id}, ${vin});`;

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Vehicle deregistered successfully!"
        })
    })
})

app.post('/gate/guard/search_vin_owner', (req, res) => {
    const fname = req.body.fname;
    const lname = req.body.lname;

    const query = `CALL search_owner_name(${fname}, ${lname});`;

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send(results[0]);
    })
})

app.post('/gate/guard/search_vin_pin', (req, res) => {
    const pin = req.body.pin;

    const query = `CALL search_vehicle_by_pin(${pin});`;

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send(results[0]);
    })
})

app.post('/gate/guard/record_entry', (req, res) => {
    const id = req.body.id;
    const vin = req.body.vin;

    const query = `CALL record_entry_time(${id}, ${vin});`;

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Time logged successsfully!"
        });
    })
})

app.post('/gate/guard/record_exit', (req, res) => {
    const id = req.body.id;
    const vin = req.body.vin;

    const query = `CALL record_exit_time(${id}, ${vin});`;

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Time logged successsfully!"
        });
    })
})

app.post('/gate/guard/obtain_logs', (req, res) => {
    const id = req.body.id;

    const query = `CALL obtain_logs(${id});`;

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send(results[0]);
    })
})

app.get('/gate/manager/view_users', (req, res) => {
    const query =  `SELECT * FROM viewUserData;`;

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send(results[0]);
    })
})

app.get('/gate/manager/view_guards', (req, res) => {
    const query = `SELECT * FROM viewGuardData;`;

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send(results[0]);
    })
})

app.get('/gate/manager/obtain_peak_hour', (req, res) => {
    const query = 'CALL obtain_peak_hour();'

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else {
            const count = Object.values(Object.values(results[0])[0])[1];
            const time = parseInt(Object.values(Object.values(results[0])[0])[0]);
            if (count == 1) {
                res.status(200).send({
                    message: "Not enough data for peak analytics!"
                })
            } else {
                res.status(200).send({
                    'count' : count,
                    'time ': time,
                })
            }
        }
    })
})

app.get('/gate/manager/obtain_reg_models', (req, res) => {
    const query = `CALL obtain_registered_models();`

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.send(results[0]);
    })
})

app.get('/gate/manager/obtain_vehicles_in', (req, res) => {
    const query = `CALL obtain_vehicles_in();`

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else {
            const count = Object.values(results[0][0])[0];
            res.status(200).send({
                'count': count
            })
        }
    })
})

app.get('/gate/manager/obtain_vehicles_out', (req, res) => {
    const query = `CALL obtain_vehicles_out();`

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else {
            const count = Object.values(results[0][0])[0];
            res.status(200).send({
                'count': count
            })
        }
    })
})

app.post('/gate/user/update_phone', (req, res) => {
    const id = req.body.id;
    const phone = req.body.phone;

    const query = `CALL update_user_phone(${id}, ${phone});`

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Phone updation successful!"
        });
    })
})

app.post('/gate/user/update_email', (req, res) => {
    const id = req.body.id;
    const email = req.body.email;

    const query = `CALL update_user_email(${id}, ${email});`

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Email updation successful!"
        })
    })
})

app.post('/gate/user/update_address', (req, res) => {
    const id = req.body.id;
    const house = req.body.house;
    const street = req.body.street;
    const city = req.body.city;
    const pincode = req.body.pincode;

    const query = `CALL update_user_address(${id}, ${house}, ${street}, ${city}, ${pincode});`

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Address updation successful!"
        })
    })
})

app.post('/gate/manager/delete_user', (req, res) => {
    const id = req.body.id;

    const query = `CALL delete_user(${id});`

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Deletion Successful!"
        })
    })
})

app.post('/gate/manager/delete_guard', (req, res) => {
    const id = req.body.id;

    const query = `CALL delete_guard(${id});`

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Deletion Successful!"
        })
    })
})

app.post('/gate/manager/create_user', (req, res) => {
    const id = req.body.id;
    const house = req.body.house;
    const street = req.body.street;
    const city = req.body.city;
    const pincode = req.body.pincode;
    const email = req.body.email;
    const phone = req.email.phone;
    const sex = req.email.sex;
    const fname = req.body.fname;
    const lname = req.body.lname;
    const date = req.body.date;
    const man_id = req.body.man_id

    query = `CALL create_user(${id}, ${fname} ${lname}, ${phone} ${email}, ${sex}, ${house}, ${street}, ${city}, ${pincode}, ${date}, ${aadhar}, ${man_id});`;

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Creation Successful!"
        })
    })
})

app.post('/gate/manager/create_guard', (req, res) => {
    const id = req.body.id;
    const email = req.body.email;
    const phone = req.email.phone;
    const sex = req.email.sex;
    const fname = req.body.fname;
    const lname = req.body.lname;
    const date = req.body.date;
    const man_id = req.body.man_id

    query = `CALL create_guard(${id}, ${fname} ${lname}, ${phone} ${email}, ${sex}, ${date}, ${aadhar}, ${man_id});`;

    db.query(query, function(error, results) {
        if (error) res.send(error);
        else res.status(200).send({
            message: "Creation Successful!"
        })
    })
})

// add users, insert sample queries, , add guard, analytics

app.listen(3000, () => {
    console.log('Server is up on port 3000.')
    })