require "librarian-chef"
require "librarian/action"

module VagrantPlugins
  module LibrarianChef
    module Action
      class Install
        def initialize(app, env)
          @app = app
          # Config#finalize! SHOULD be called automatically
          env[:global_config].librarian_chef.finalize!

          # Only set cookbooks_path if a Cheffile is present
          set_cookbooks_path(env) if env[:global_config].librarian_chef.cheffile_present?(env)
        end

        def call(env)
          config = env[:global_config].librarian_chef
          # look for a Cheffile in the configured cheffile_dir
          if config.cheffile_present?(env)
            env[:ui].info "Installing Chef cookbooks with Librarian-Chef..."
            environment = Librarian::Chef::Environment.new({
              :project_path => config.cheffile_dir
            })
            Librarian::Action::Ensure.new(environment).run
            Librarian::Action::Resolve.new(environment).run
            Librarian::Action::Install.new(environment).run
          end
          @app.call(env)
        end

        def set_cookbooks_path(env)
          env[:global_config].vm.provision :chef_solo do |chef|
            # automatically set cookbooks_path only if unset
            if chef.cookbooks_path == Vagrant.plugin(2, :config)::UNSET_VALUE
              chef.cookbooks_path = env[:global_config].librarian_chef.cookbooks_path
            end
          end
        end
      end
    end
  end
end
