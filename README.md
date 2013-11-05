# Myfdb Utilities

## User Installation for uploading

* [Download and install OSX Command Line Tools](https://developer.apple.com/downloads/) (requires an Apple account)
* In Terminal run the following command

        bash < <(curl -s https://raw.github.com/myfdb/myfdb_utilities/uploader_setup)

## Developer Installation

    git clone git@github.com:MyFDB/myfdb_utilities.git
    cd myfdb_utilities
    gem build myfdb_utilities.gemspec
    gem install myfdb_utilities-0.0.9.gem

## Settings

Run `myfdb init`

You will be asked for your api_key, api_secret, host (www.myfdb.com if you're installing for use uploading to the live site), protocol (http or https), and whether you want a cron task created. The api_key and api_secret can be found in the main MyFDB repository in `app/controllers/upload/application_controller.rb`.

The cron task will allow you to drop a folder in the main directory and have the upload happen automatically in the background. If you choose to install the cron task, you're done. To upload images, just place a folder of images in `~/MyFDB_Uploads`.

If you do NOT choose to install the cron task, you can upload the images in `~/MyFDB_Uploads` by running `myfdb upload_images`.

Images are automatically deleted once they have been successfully uploaded. (The folders themselves are not deleted, however. Nor are images that failed to upload deleted.)

Each folder is uploaded as a separate, newly created issue. If you want to upload to an already existing issue, use the existing issue folder or create a new one (name won't matter) and then within that folder create a *file* called `issue_id` (no file extension) containing the issue's id number.

Once the images are uploaded, you can find them on the site by going into the admin menu (the arrow next to your name at the top right of the screen) and clicking on "Title pending issues". The new issues are marked *unpublished* and won't show up live on the site until you officially *publish* them.

To organize the images in a new, unpublished issue: In the "Title pending issues" admin screen, click on *edit* and fill in info on the issue. Hit the button at the bottom, and it will publish the issue and take you to a page where you can select images and create that set as a cover, campaign, or editorial.
