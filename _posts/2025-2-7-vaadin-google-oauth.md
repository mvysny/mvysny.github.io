---
layout: post
title: Google OAuth/Google SSO with Vaadin (No Spring)
---

There are [blogposts describing how to integrate Google SSO with Vaadin](https://vaadin.com/blog/oauth-2-and-google-sign-in-for-a-vaadin-application);
there is also a [commercial SSO library](https://vaadin.com/docs/latest/tools/sso) which
does the same, but both of those approaches require Spring. This blogpost documents
Google SSO when your Vaadin app isn't using Spring.

We'll create a Vaadin component which calls Google APIs to allow your user to log in.
We'll also create a Google OAuth screen and configure it so that everything works locally,
with a server running at `http://localhost:8080`. It's actually surprisingly easy.

## Preparation

It's good to read the documentation on Google Identity, namely the following tutorials:

* Obtain the Google ID token via [the Sign In With Google button](https://developers.google.com/identity/gsi/web/guides/display-button) -
  we'll use the JavaScript button rendering.
* [Verify the Google ID token server-side](https://developers.google.com/identity/gsi/web/guides/verify-google-id-token)

Follow the [Setup Tutorial](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid) and create
a `OAuth 2.0 Client ID` at console.cloud.google.com:

* For Authorized JavaScript origins, use `http://localhost:8080`
* For authorized redirect URIs, use `http://localhost:8080` - I think we won't be using this since
  we'll use JavaScript callbacks instead.

## The Button

We'll create a Vaadin GoogleSignInButton class which imports Google Identity client and calls
necessary javascript functions, to log in the user and obtain the Google ID token. Create a Java class named `GoogleSignInButton`:
```java
@Tag("google-signin-button")
@JsModule("./src/google-signin-button.js")
@JavaScript(value = "https://accounts.google.com/gsi/client")
public class GoogleSignInButton extends Div {
  // the "Client ID" from Google OAuth 2.0 credential, looks like
  // 2398471023-asoifywerhewjkdlaj023842asdkl.apps.googleusercontent.com
  public GoogleSignInButton(String clientId) {
    getElement().setProperty("clientId", Objects.requireNonNull(clientId));
  }
  @ClientCallable
  private void onSignIn(String credential) {
    System.out.println(credential);
  }
}
```
Note the `initialize()` javascript call, the `callback` parameter: this javascript function gets
called when the Google user logs in; it receives a credential string which contains
all the important information.

Let's implement the `handleCredentialResponse()` function in a custom element: let's
create a javascript file in `src/main/frontend/src/google-signin-button.js`:
```javascript
class GoogleSigninButton extends HTMLElement {
  connectedCallback() {
    google.accounts.id.initialize({client_id: this.clientId, callback: this.handleCredentialResponse.bind(this)});
    google.accounts.id.renderButton(this, {theme:'outline', size:'large'});
    google.accounts.id.prompt();
  }
  handleCredentialResponse(response) {
    this.$server.onSignIn(response.credential);
  }
}
window.customElements.define('google-signin-button', GoogleSigninButton);
```
All done. You can now place the button into your app and click it. It should run the Google login procedure,
then it should receive a credential string, send it to the server by calling `onSignIn()` Java
function, then print it to the console. Once that happens, we're good to go to step 2.

## Verifying Credential

We need to parse the credential string, verify that it's correct, check the client id,
parse the e-mail out of it, and then log in the user with that e-mail. That's documented
in [Verify the Google ID token on your server side](https://developers.google.com/identity/gsi/web/guides/verify-google-id-token).

The simplest way is to use the [Google API Client Library](https://developers.google.com/api-client-library/java),
even though it pulls in shitload of dependencies. There's a bit of documentation here: [API Requests](https://developers.google.com/api-client-library/java/google-api-java-client/requests);
the [Maven Coordinates are here](https://developers.google.com/api-client-library/java/google-api-java-client/setup).

In short, add this to your project's dependencies:
```gradle
dependencies {
  implementation("com.google.api-client:google-api-client:2.7.2")
}
```
> Note: check the newest version at [Maven Central: google-api-client](https://repo1.maven.org/maven2/com/google/api-client/google-api-client/)

Then, modify the `GoogleSignInButton` Java class:
```java
@ClientCallable
private void onSignIn(String credential) {
    try {
        HttpTransport transport = GoogleNetHttpTransport.newTrustedTransport();
        JsonFactory jsonFactory = GsonFactory.getDefaultInstance();
        GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(transport, jsonFactory)
                .setAudience(Collections.singletonList(clientId))
                .build();
        final GoogleIdToken idToken = verifier.verify(credential);
        if (idToken == null) {
            throw new RuntimeException("Failed to verify credential");
        }
        GoogleIdToken.Payload payload = idToken.getPayload();
        // Print user identifier
        String userId = payload.getSubject();
        System.out.println("User ID: " + userId);
        // Get profile information from payload
        System.out.println(payload.getEmail());
        boolean emailVerified = Boolean.valueOf(payload.getEmailVerified());
        System.out.println(emailVerified);
        System.out.println((String) payload.get("name"));
        System.out.println((String) payload.get("picture"));
    } catch (Exception ex) {
      ex.printStackTrace();
      Notification.show("Failure while logging in via Google");
    }
}
```

Now, since you have the user's e-mail, you can store the user's e-mail into Vaadin
Session, thus logging in the user.
