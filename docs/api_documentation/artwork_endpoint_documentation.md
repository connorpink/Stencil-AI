# Artwork Route Documentation

## Fetch
`GET {server location}/artwork/fetch/:{artworkId: string}`

returns an artwork from the database

### Request
**Access Token:** required

fetches an artwork from the database with the provided id.  
Make sure the current authenticated user is the owner of the artwork.  
Return the artwork to the client assuming ownership is confirmed

#### Query Parameters
none

### Response

=== "200"
    returns an artwork object

    #### Body
    ```json
    {
        "id": "string",
        "title": "string",
        "prompt": "string",
        "stencilList": [
            {
                "prompt": "string",
                "preferredImageIndex": "number",
                "imageList": [
                    {
                        "path": "string",
                        "url": "string",
                        "size": "number", // optional
                        "orig_name": "string", // optional
                        "mime_type": "string", // optional
                        "is_stream": "boolean",
                        "meta": "any"
                    }
                ],
                "position": ["number"], // optional
                "rotation": "number", // optional
                "scale": "number", // optional
            }
        ],
        "strokeList": [
            {
                "pointList": [["number"]],
                "color": "number",
                "brushSize": "number",
            }
        ],
        "updatedAt": "Date",
    }
    ```
=== "400"
    The request query parameters do not match what is expected in the documentation

=== "401"
    valid jwt access token was not provided with the request

## FetchAll
`GET {server location}/artwork/fetchAll`

returns a list of all artworks associated with the current user

### Request
**Access Token:** required

fetches all artworks from the database owned by the current user.
return artworks to the user

#### Query Parameters
none

### Response

=== "200"
    returns an artwork object array

    #### Body
    ```json
    [{
        "id": "string",
        "title": "string",
        "prompt": "string",
        "stencilList": [
            {
                "prompt": "string",
                "preferredImageIndex": "number",
                "imageList": [
                    {
                        "path": "string",
                        "url": "string",
                        "size": "number", // optional
                        "orig_name": "string", // optional
                        "mime_type": "string", // optional
                        "is_stream": "boolean",
                        "meta": "any"
                    }
                ],
                "position": ["number"], // optional
                "rotation": "number", // optional
                "scale": "number", // optional
            }
        ],
        "strokeList": [
            {
                "pointList": [["number"]],
                "color": "number",
                "brushSize": "number",
            }
        ],
        "updatedAt": "Date",
    }]
    ```
=== "400"
    The request query parameters do not match what is expected in the documentation

=== "401"
    valid jwt access token was not provided with the request

## Create
`POST {server location}/artwork/create`

creates a new artwork for the client to draw on

### Request
**Access Token:** required

creates a new artwork object
saves the artwork object inside the database
returns the artwork object to the client

#### Request Body
none

### Response

=== "201"
    returns an artwork object

    #### Body
    ```json
    {
        "id": "string",
        "title": "string",
        "prompt": "string",
        "stencilList": [
            {
                "prompt": "string",
                "preferredImageIndex": "number",
                "imageList": [
                    {
                        "path": "string",
                        "url": "string",
                        "size": "number", // optional
                        "orig_name": "string", // optional
                        "mime_type": "string", // optional
                        "is_stream": "boolean",
                        "meta": "any"
                    }
                ],
                "position": ["number"], // optional
                "rotation": "number", // optional
                "scale": "number", // optional
            }
        ],
        "strokeList": [
            {
                "pointList": [["number"]],
                "color": "number",
                "brushSize": "number",
            }
        ],
        "updatedAt": "Date",
    }
    ```
=== "400"
    The request query parameters do not match what is expected in the documentation

=== "401"
    valid jwt access token was not provided with the request

## Save
`POST {server location}/artwork/save`

saves the artwork project inside the database

### Request
**Access Token:** required

fetches the artwork object with the matching id
confirm that the current user is the owner of the provided artwork
overwrite the the artwork inside the database to match the current one

#### Request Body
```json
{
    "id": "string",
    "title": "string",
    "prompt": "string",
    "stencilList": [
        {
            "prompt": "string",
            "preferredImageIndex": "number",
            "imageList": [
                {
                    "path": "string",
                    "url": "string",
                    "size": "number", // optional
                    "orig_name": "string", // optional
                    "mime_type": "string", // optional
                    "is_stream": "boolean",
                    "meta": "any"
                }
            ],
            "position": ["number"], // optional
            "rotation": "number", // optional
            "scale": "number", // optional
        }
    ],
    "strokeList": [
        {
            "pointList": [["number"]],
            "color": "number",
            "brushSize": "number",
        }
    ],
    "updatedAt": "Date",
}
```

### Response

=== "201"
    the artwork has been saved

    #### Body
    none

=== "400"
    The request query parameters do not match what is expected in the documentation

=== "401"
    valid jwt access token was not provided with the request

## Delete
`POST {server location}/artwork/delete`

deletes an artwork from the database

### Request
**Access Token:** required

fetches the artwork object with the given id
confirm that the current user is the owner of the fetched artwork
remove the artwork from the database

#### Request Body
```json
{
"id": "string",
}
```

### Response

=== "201"
    the artwork has been deleted

    #### Body
    none

=== "400"
    The request query parameters do not match what is expected in the documentation

=== "401"
    valid jwt access token was not provided with the request