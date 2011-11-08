<%@ page import="com.google.appengine.api.users.User" %>
<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
<%@ page import="com.leanengine.server.*" %>
<%@ page import="com.leanengine.server.appengine.DatastoreUtils" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.leanengine.server.auth.*" %>
<%@ page import="com.leanengine.server.appengine.AccountUtils" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String nextUrl = request.getParameter("next") == null ? "": request.getParameter("next");

    // type parameters tells us the type of redirect we should perform
    Scheme scheme;
    if (nextUrl.equals("@mobile")) {
        scheme = new MobileScheme(request.getServerName());
    } else {
        String hostname = request.getServerName();
        if (request.getLocalPort() != 80 && request.getLocalPort() != 0) {
            hostname = hostname + ":" + request.getLocalPort();
        }
        scheme = new WebScheme(request.getScheme(), hostname);
    }


    // get user
    User currentUser = UserServiceFactory.getUserService().getCurrentUser();

    //OpenID login did not succeed
    if (currentUser == null) {
        response.sendRedirect(scheme.getErrorUrl(new LeanException(LeanException.Error.OpenIdAuthFailed)));
    }
    // get toke for this user
    AuthToken authToken;

    LeanAccount account = AccountUtils.findAccountByProvider(currentUser.getUserId(),
            currentUser.getFederatedIdentity());

    if (account == null) {
        //todo this is one-to-one mapping between Account and User - change this in the future

        Map<String, Object> props = new HashMap<String, Object>();
        props.put("email", currentUser.getEmail());

        // account does not yet exist - create it
        account = new LeanAccount(
                0,
                currentUser.getNickname(),
                currentUser.getUserId(),
                currentUser.getFederatedIdentity(),
                props
        );

        // saving the LeanAccount sets the 'id' on it
        AccountUtils.saveAccount(account);
    }

    // create our own authentication token
    authToken = AuthService.createAuthToken(account.id);

    // save token in session
    session.setAttribute("lean_token", authToken.token);

    //send lean_token back to browser
    response.sendRedirect(scheme.getUrl(authToken.token, nextUrl));
%>