# Auth Route Documentation

## Status
`GET {server location}/auth/status`

Returns a json object representing the user currently signed into the account

### Request
**Access Token:** required

#### Query Parameters
none

### Responses
=== "200"
    Returns a user object

    #### Body
    ```json
    {
        "id": "integer", // required
        "username": "string", // required
        "email": "string"
    }
    ```



=== "401"
    Client did not provided a valid JWT access token in the header

## Register
`POST {server location}/auth/register`

Creates a new account based on data provided in the body
Provides a access token and refresh token for accessing other API's

### Request
**Access Token:** not applicable

#### Request Body
```json
{
    "username": "String", // required
    "email": "String", // required
    "password": "String", //required
```

### Response
=== "201"
    account has been created.  
    returns an access token, refresh token, and user object.

    #### Body
    ```json
    {
        "accessToken": "string",
        "refreshToken": "string",
        "user": {
            "id": "integer",
            "username": "string",
            "email": "string", // optional
        },
    }
    ```

=== "400"
    The request body does not match what is expected in the documentation

=== "401"
    username or email have already been used for another account, error message should specify which one


## Login
`POST {server location}/auth/login`

Creates a new account based on data provided in the body

### Request
**Access Token:** not applicable

Uses a username and password to authenticate the user
Provides a access token and refresh token for accessing other API's

#### Request Body
```json
{
    "username": "string", // required
    "password": "string", // required
}
```

### Response
=== "200"
    returns an access token, refresh token, and user object.

    #### body
    ```json
    {
        "accessToken": "string",
        "refreshToken": "string",
        "user": {
            "id": "integer",
            "username": "string",
            "email": "string", // optional
        },
    }
    ```

=== "400"
    The request body does not match what is expected in the documentation

=== "401"
    username or email provided is incorrect, error message should specify which one

## Delete Account
`POST {server location}/auth/deleteAccount`

Deletes the current users account

### Request
**Access Token:** required

#### Request Body
none

### Response
=== "201"
    The current users account has been deleted

    #### Body
    none



=== "401"
    Client did not provided a valid JWT access token in the header

