module Hussar
  Tasks = {}
  Tasks[:build_start] = lambda do
    sh "echo '' > SERVICE_PREFIX/service.log", :nolog

    info ""
    info("*" * 50)
    info "    Starting new deployment"
    info("*" * 50)
    info ""

    # Setup app env
    opts.env.each do |k,v|
      env k, v
    end

    # Create directories structure
    mkdir "build"
    mkdir "cache/bundle"
    mkdir "releases"
    mkdir "scm"
    mkdir "tmp"

    # Create new build dir
    sh %Q{
      STAMP="$(date +'%Y-%m-%d-%Hh%Mm%S')-$[${RANDOM}%10000]"
      BUILD_DIR="SERVICE_PREFIX/build/$STAMP"
      RELEASE_DIR="SERVICE_PREFIX/releases/$STAMP"
      mkdir -p $BUILD_DIR
    }

    info "Building in %s", "$BUILD_DIR"

    # Update git repository
    sh "if [ -d SERVICE_PREFIX/scm/objects ]; then", :nolog
      info "Fetching new git commits"
      sh "pushd SERVICE_PREFIX/scm", :nolog
      sh "git fetch #{opts.git_url} #{opts.git_branch}:#{opts.git_branch} --force", :validate
      sh "popd", :nolog
    sh "else", :nolog
      info "Cloning git repository #{opts.git_url}"
      sh "git clone #{opts.git_url} SERVICE_PREFIX/scm --bare", :validate
    sh "fi", :nolog

    # Copy working directory to build dir

    chdir "$BUILD_DIR" do
      info "Using git branch #{opts.git_branch}"
      sh "git clone SERVICE_PREFIX/scm . --recursive --branch #{opts.git_branch}", :validate
      info "Using this git commit"
      sh "GIT_COMMIT=$(git --no-pager log --format='%aN (%h):%n> %s' -n 1)", :nolog
      sh "echo $GIT_COMMIT"
      sh 'rm -rf "$BUILD_DIR/.git"'
    end
  end

  Tasks[:build_finish] = lambda do
    # Release app
    info "Releasing %s to %s", "$BUILD_DIR", "$RELEASE_DIR"
    sh "mv $BUILD_DIR $RELEASE_DIR", :validate
    info "Linking %s to %s", "$RELEASE_DIR", "SERVICE_PREFIX/current"
    sh "rm -f SERVICE_PREFIX/current", :validate
    sh "ln -s $RELEASE_DIR SERVICE_PREFIX/current", :validate

    notice "%s - Build Succeed\nCommit: %s", "#{service_name}", "$GIT_COMMIT"
    sh "echo 'Build Succeed'", :nolog
    expect "Build Succeed"
  end

  Tasks[:bundle] = lambda do
    # Install gems
    sh "if [ -d SERVICE_PREFIX/current/bundle.installed ]; then", :nolog
      info "Copying bundle.installed form previous release"
      sh "cp -R SERVICE_PREFIX/current/bundle.installed bundle.installed", :validate
    sh "fi", :nolog

    info "Running bundle install"
    sh %Q{
      SERVICE_ROOT/exports/bundle install \\
        --without development:test \\
        --path bundle.installed \\
        --deployment \\
        --binstubs #{log}
    }, :validate

    info "Cleaning bundle"
    sh "SERVICE_ROOT/exports/bundle clean", :validate
  end

  Tasks[:assets] = lambda do
    info "Compiling assets"
  end
end
