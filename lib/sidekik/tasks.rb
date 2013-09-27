module Sidekik
  Tasks = {}
  Tasks[:build_start] = lambda do
    info ""
    info("*" * 50)
    info "    Starting new deployment"
    info("*" * 50)
    info ""

    # Setup app env
    opts.env.each do |k,v|
      set_env k, v
    end

    # Create directories structure
    service_mkdir "build"
    service_mkdir "cache/bundle"
    service_mkdir "releases"
    service_mkdir "scm"
    service_mkdir "tmp"

    # Create new build dir

    set "STAMP", "$(date +'%Y-%m-%d-%Hh%Mm%S')-$[${RANDOM}%10000]"
    set "BUILD_DIR", "SERVICE_PREFIX/build/$STAMP"
    set "RELEASE_DIR", "SERVICE_PREFIX/releases/$STAMP"
    mkdir "$BUILD_DIR"

    info "Building in %s", "$BUILD_DIR"

    # Update git repository
    sh "if [ -d SERVICE_PREFIX/scm/objects ]; then", :novalidate
      info "Fetching new git commits"
      chdir "SERVICE_PREFIX/scm" do
        sh "git fetch #{opts.git_url} #{opts.git_branch}:#{opts.git_branch} --force"
      end
    sh "else", :novalidate
      info "Cloning git repository #{opts.git_url}"
      sh "git clone #{opts.git_url} SERVICE_PREFIX/scm --bare"
    sh "fi", :novalidate

    # Copy working directory to build dir

    chdir "$BUILD_DIR" do
      info "Using git branch #{opts.git_branch}"
      sh "git clone SERVICE_PREFIX/scm . --recursive --branch #{opts.git_branch}"
      info "Using this git commit"
      set "GIT_COMMIT", "$(git --no-pager log --format='%aN (%h):%n> %s' -n 1)"
      sh "echo $GIT_COMMIT"
      sh 'rm -rf "$BUILD_DIR/.git"'
    end
  end

  Tasks[:build_finish] = lambda do
    # Release app
    info "Releasing %s to %s", "$BUILD_DIR", "$RELEASE_DIR"
    sh "mv $BUILD_DIR $RELEASE_DIR"
    info "Linking %s to %s", "$RELEASE_DIR", "SERVICE_PREFIX/current"
    sh "rm -f SERVICE_PREFIX/current"
    sh "ln -s $RELEASE_DIR SERVICE_PREFIX/current"

    notice "%s - Build Succeed\nCommit: %s", "#{service_name}", "$GIT_COMMIT"
  end

  Tasks[:bundle] = lambda do
    # Install gems
    sh "if [ -d SERVICE_PREFIX/current/bundle.installed ]; then", :novalidate
      info "Copying bundle.installed form previous release"
      sh "cp -R SERVICE_PREFIX/current/bundle.installed bundle.installed"
    sh "fi", :novalidate

    info "Running bundle install"
    sh %Q{
      SERVICE_ROOT/exports/bundle install \\
        --without development:test \\
        --path bundle.installed \\
        --deployment \\
        --binstubs
    }

    info "Cleaning bundle"
    sh "SERVICE_ROOT/exports/bundle clean"
  end

  Tasks[:assets] = lambda do
    info "Compiling assets"
  end
end
