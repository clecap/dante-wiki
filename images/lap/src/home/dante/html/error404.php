<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Page Not Found (404)</title>
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
    <h1>Page Not Found (404)</h1>
    <p>The requested URL <strong style="color:red;"><?php echo htmlspecialchars($_SERVER['REQUEST_URI']); ?></strong> was not found on this server.</p>
    <p>If you consider this to be in error and want to support the further development of this software, you can report this here: 
       <a href="https://github.com/clecap/dante-wiki/issues">https://github.com/clecap/dante-wiki/issues</a>.
    </p>
    <p>If you want to go back to your Dante-Wiki you can do so here
      <ul>
        <li><a href="/wiki-dir">/wiki-dir</a></li>
      </ul>
    </p>
    
</body>
</html>
