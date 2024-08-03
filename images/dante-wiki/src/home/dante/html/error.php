<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Error Page</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
        }
        h1 {
            font-size: 36px;
        }
        p {
            font-size: 18px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>We are sorry, but an error occurred while processing your request.</h1>

  <h2>Error Details</h2>
  <p><strong>Error Code:</strong> <?php echo $_SERVER['REDIRECT_STATUS']; ?></p>
  <p><strong>Request URI:</strong> <?php echo $_SERVER['REQUEST_URI']; ?></p>
  <p><strong>Referer:</strong> <?php echo isset($_SERVER['HTTP_REFERER']) ? $_SERVER['HTTP_REFERER'] : 'N/A'; ?></p>
  <p><strong>User Agent:</strong> <?php echo $_SERVER['HTTP_USER_AGENT']; ?></p>

  <p>You can support the further development of this software by reporting this here:
       <a href="https://github.com/clecap/dante-wiki/issues">https://github.com/clecap/dante-wiki/issues</a>
  </p>
  <p>If you want to go back to your Dante-Wiki you can do so here
    <ul>
      <li><a href="/wiki-dir">/wiki-dir</a></li>
    </ul>
  </p>
</body>
</html>
