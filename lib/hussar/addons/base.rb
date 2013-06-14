addon "Base" do
  option :env, {}
  option :git_url, nil
  option :git_branch, "master"
  option :skip_bundle, false

  generate do
    service do
      software_name "Ruby"

      configure do
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
          printf '--> Building in %s\n' $BUILD_DIR #{log}
          mkdir -p $BUILD_DIR
        }

        # Update git repository
        sh %Q{
          if [ -d SERVICE_PREFIX/scm/objects ]; then
            printf '--> Fetching new git commits\n' #{log}
            pushd SERVICE_PREFIX/scm
            git fetch #{opts.git_url} #{opts.git_branch}:#{opts.git_branch} --force #{log}
            popd
          else
            printf '--> Cloning git repository #{opts.git_url}\n' #{log}
            git clone #{opts.git_url} SERVICE_PREFIX/scm --bare #{log}
          fi
        }

        # Copy working directory to build dir
        sh %Q{
          pushd $BUILD_DIR
          printf '--> Using git branch #{opts.git_branch}\n' #{log}
          git clone SERVICE_PREFIX/scm . --recursive --branch #{opts.git_branch}
          printf '--> Using this git commit\n' #{log}
          git --no-pager log --format="%aN (%h):%n> %s" -n 1 #{log}
          rm -rf "$BUILD_DIR/.git"
          popd
        }

        # Build app
        unless opts.skip_bundle?
          # Install gems
          sh %Q{
            pushd $BUILD_DIR
            if [ -d SERVICE_PREFIX/current/bundle.installed ]; then
              printf '--> Copying bundle.installed form previous release\n' #{log}
              cp -R SERVICE_PREFIX/current/bundle.installed bundle.installed #{log}
            fi;
            printf '--> Running bundle install\n' #{log}
            SERVICE_ROOT/exports/bundle install \\
              --without development:test \\
              --path bundle.installed \\
              --deployment \\
              --binstubs #{log}
            printf '--> Cleaning bundle\n' #{log}
            SERVICE_ROOT/exports/bundle clean #{log}
            popd
          }
        end

        # Release app
        sh %Q{
          printf '--> Releasing %s to %s\n' $BUILD_DIR $RELEASE_DIR #{log}
          mv $BUILD_DIR $RELEASE_DIR
          rm -f SERVICE_PREFIX/current
          ln -s $RELEASE_DIR SERVICE_PREFIX/current
        }
      end

      start do
        env_load
        sh %{
          cd SERVICE_PREFIX/current

          printf 'service port = %s\n' SERVICE_PORT #{log}
          bin/rackup \\
            -p SERVICE_PORT \\
            -E $RACK_ENV \\
            -D -P SERVICE_PREFIX/service.pid
        }
      end
    end
  end
end
