module RubyPulse
  module Collectors
    class Container
      def collect
        { collector: :container, containers: detect_containers, timestamp: Time.now }
      end

      private

      def detect_containers
        containers = []

        if docker_available?
          containers.concat(docker_list)
        end

        if podman_available?
          containers.concat(podman_list)
        end

        containers
      end

      def docker_available?
        @has_docker = system("docker info >/dev/null 2>&1") if @has_docker.nil?
        @has_docker
      end

      def podman_available?
        @has_podman = system("podman info >/dev/null 2>&1") if @has_podman.nil?
        @has_podman
      end

      def docker_list
        output = `docker ps --format '{{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}\t{{.Size}}' 2>/dev/null`
        parse_container_output(output, :docker)
      rescue
        []
      end

      def podman_list
        output = `podman ps --format '{{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}' 2>/dev/null`
        parse_container_output(output, :podman)
      rescue
        []
      end

      def parse_container_output(output, runtime)
        output.lines.filter_map do |line|
          parts = line.strip.split("\t")
          next if parts.size < 4

          {
            runtime: runtime,
            id: parts[0],
            image: parts[1],
            status: parts[2],
            name: parts[3],
            running: parts[2].downcase.start_with?("up")
          }
        end
      end
    end
  end
end
