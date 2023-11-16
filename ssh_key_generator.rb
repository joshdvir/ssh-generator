require 'sinatra'
require 'open3'
require 'securerandom'

KEY_SIZES = {
  'rsa' => [4096, 2048, 1024],
  'dsa' => [1024],
  'ecdsa' => [521, 384, 256],
  'ed25519' => [512, 256]
}.freeze

get '/' do
  erb :index
end

post '/generate' do
  content_type :html
  type, size = default_sizes(params)
  public_key, private_key = generate_ssh_keys(type, size)

  erb :result, locals: { public_key: public_key, private_key: private_key }
end

post '/keys' do
  content_type :json
  type, size = default_sizes(params)
  public_key, private_key = generate_ssh_keys(type, size)

  { public_key: public_key, private_key: private_key }.to_json
end

def default_sizes(params)
  type = params.key?('type') && KEY_SIZES.keys.include?(params[:type]) ? params[:type] : 'ed25519'
  size = if params.key?('size') && KEY_SIZES[type].include?(params[:size].to_i)
           params[:size].to_i
         else
           KEY_SIZES[type].first
         end
  [type, size]
end

def generate_ssh_keys(type, size)
  case type
  when 'rsa', 'dsa', 'ecdsa', 'ed25519'
    public_key, private_key = generate_keys(type, size)
  else
    raise 'Unsupported key type'
  end
  [public_key, private_key]
end

def generate_keys(type, size)
  random_string = SecureRandom.hex
  Open3.capture2(
    'ssh-keygen', '-t', type, '-b', size.to_s, '-f',
    "/tmp/#{random_string}", '-N', '', '-q', '-C', ''
  )
  private_key = File.read("/tmp/#{random_string}").strip
  public_key = File.read("/tmp/#{random_string}.pub").strip
  File.unlink("/tmp/#{random_string}")
  File.unlink("/tmp/#{random_string}.pub")
  [public_key, private_key]
end

__END__

@@index
<!DOCTYPE html>
<html>
<head>
  <title>SSH Key Generator</title>
  <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
  <link rel="stylesheet" href="https://code.getmdl.io/1.3.0/material.indigo-pink.min.css">
  <script defer src="https://code.getmdl.io/1.3.0/material.min.js"></script>
  <style>
    .mdl-textfield {
      width: 100%;
    }

    .header-link {
      text-decoration: none;
      color: inherit;
    }
  </style>
</head>
<body>
  <div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
    <header class="mdl-layout__header">
      <div class="mdl-layout__header-row">
        <a class="mdl-layout-title header-link" href="/">SSH Key Generator</a>
      </div>
    </header>
    <main class="mdl-layout__content">
      <div class="mdl-grid">
        <div class="mdl-cell mdl-cell--3-col"></div>
        <div class="mdl-cell mdl-cell--6-col">
          <div class="mdl-shadow--2dp">
            <div class="mdl-card__title">
              <h2 class="mdl-card__title-text">Generate SSH Keys</h2>
            </div>
            <div class="mdl-card__supporting-text">
              <form action="/generate" method="post">
                <div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
                  <select name="type" id="type" class="mdl-textfield__input">
                    <option value="ed25519">ED25519</option>
                    <option value="ecdsa">ECDSA</option>
                    <option value="dsa">DSA</option>
                    <option value="rsa">RSA</option>
                  </select>
                  <label class="mdl-textfield__label" >Key Type</label>
                </div>
                <div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
                  <select name="size" id="size" class="mdl-textfield__input">
                    <option value="512">512</option>
                    <option value="256">256</option>
                  </select>
                  <label class="mdl-textfield__label">Key Size</label>
                </div>
                <br>
                <button class="mdl-button mdl-js-button mdl-button--raised mdl-button--colored">
                  Generate
                </button>
              </form>
            </div>
          </div>
        </div>
        <div class="mdl-cell mdl-cell--3-col"></div>
      </div>
    </main>
  </div>
  <script>
    function updateKeySizes() {
      var keyType = document.getElementById('type').value;
      var keySizeSelect = document.getElementById('size');

      // Clear previous options
      keySizeSelect.innerHTML = '';

      // Add options for selected key type
      var keySizes = <%= KEY_SIZES.to_json %>[keyType];
      for (var i = 0; i < keySizes.length; i++) {
        var option = document.createElement('option');
        option.value = keySizes[i];
        option.text = keySizes[i];
        keySizeSelect.appendChild(option);
      }
    }
    document.getElementById('type').addEventListener('change', updateKeySizes);
  </script>
</body>
</html>



@@result
<!DOCTYPE html>
<html>
<head>
  <title>SSH Key Generator</title>
  <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">
  <link rel="stylesheet" href="https://code.getmdl.io/1.3.0/material.indigo-pink.min.css">
  <script defer src="https://code.getmdl.io/1.3.0/material.min.js"></script>
  <style>
    .mdl-textfield {
      width: 100%;
    }

    .header-link {
      text-decoration: none;
      color: inherit;
    }
  </style>
</head>
<body>
  <div class="mdl-layout mdl-js-layout mdl-layout--fixed-header">
    <header class="mdl-layout__header">
      <div class="mdl-layout__header-row">
        <a class="mdl-layout-title header-link" href="/">SSH Key Generator</a>
      </div>
    </header>
    <main class="mdl-layout__content">
      <div class="mdl-grid">
        <div class="mdl-cell mdl-cell--3-col"></div>
        <div class="mdl-cell mdl-cell--6-col">
          <div class="mdl-shadow--2dp">
            <div class="mdl-card__title">
              <h2 class="mdl-card__title-text">Generated SSH Keys</h2>
            </div>
            <div class="mdl-card__supporting-text">
              <h3>Public Key:</h3>
              <div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
                <textarea class="mdl-textfield__input" rows="5" readonly id="public_key"><%= public_key %></textarea>
                <label class="mdl-textfield__label" for="public_key">Public Key</label>
              </div>
              <br>
              <button class="mdl-button mdl-js-button mdl-button--raised mdl-button--colored"
                      onclick="copyToClipboard('public_key')">
                Copy Public Key
              </button>
              <br><br>
              <h3>Private Key:</h3>
              <div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label">
                <textarea class="mdl-textfield__input" rows="12" readonly id="private_key"><%= private_key %></textarea>
                <label class="mdl-textfield__label" for="private_key">Private Key</label>
              </div>
              <br>
              <button class="mdl-button mdl-js-button mdl-button--raised mdl-button--colored"
                      onclick="copyToClipboard('private_key')">
                Copy Private Key
              </button>
            </div>
          </div>
        </div>
        <div class="mdl-cell mdl-cell--3-col"></div>
      </div>
    </main>
  </div>
  <script>
    function copyToClipboard(elementId) {
      var element = document.getElementById(elementId);
      element.select();
      element.setSelectionRange(0, 99999); // For mobile devices

      navigator.clipboard.writeText(element.value)
        .catch(function(error) {
          console.error("Failed to copy to clipboard:", error);
        });
    }
  </script>
</body>
</html>
