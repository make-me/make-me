module MakeMe
  class MiracleGrueConfigurator
    attr_reader :config

    def initialize(config)
      @config = defaults.merge(config)
    end

    def save(filename)
      File.open(filename, 'w') do |file|
        file.write Yajl::Encoder.encode(config)
      end
    end

    def defaults
      {
        :infillDensity           => 0.05, # How solid should it be
        :numberOfShells          => 2,    # Number of shells to print
        :insetDistanceMultiplier => 1.05, # unit: layerW/how far apart are insets from each other
        :roofLayerCount          => 5,    # How many solid layers for roofs
        :floorLayerCount         => 5,    # How many solid layers for floors
        :layerWidthRatio         => 1.67, # Width over height ratio
        :preCoarseness           => 0.1,  # Coarseness before all processing
        :coarseness              => 0.05, # Moves shorter than this are combined
        :directionWeight         => 0.5,
        :gridSpacingMultiplier   => 0.85,

        :doOutlines => false,
        :doInfills  => true,
        :doInsets   => true,

        :doGraphOptimization => true, # Do we want to apply our graph optimization?
        :iterativeEffort     => 999,  # Max number of iterations to run after graph,
                                      # sanity check only

        # how fast to move when not extruding in mm/sec
        :rapidMoveFeedRateXY => 120,
        :rapidMoveFeedRateZ  => 23,

        # Rafts
        :doRaft                 => false,
        :raftLayers             => 3,    # Number of raft layers to print
        :raftBaseThickness      => 0.5,  # Thickness of first raft layer
        :raftInterfaceThickness => 0.25, # Thickness of other raft layers
        :raftOutset             => 6,    # Distance to outset rafts
        :raftModelSpacing       => 0.1,  # Distance between top most raft and bottom of model
        :raftDensity            => 0.23, # Overall density of the raft

        # Supports
        :doSupport      => false,
        :supportMargin  => 2.0,   # Distance between sides of object and start of support in mm
        :supportDensity => 0.095,

        :bedZOffset  => 0.0,  # Height to start printing the first layer
        :layerHeight => 0.27, # Height of a layer

        # Assumed starting position after header gcode is done
        :startX => -110.4,
        :startY => -74.0,
        :startZ => 0.2,

        # Start and end GCode to send before & after actual print
        # Default to /dev/null since s3g can send this for us.
        :startGcode => "/dev/null",
        :endGcode   => "/dev/null",

        :doPrintProgress => true, # Display % printed

        :doFanCommand => true, # Turn on filament fan
        :fanLayer     => 5,    # Turn it on after layer 5

        :defaultExtruder => 0,
        :extruderProfiles => [ # configuration values for our single extruder
          {
            :firstLayerExtrusionProfile => "firstlayer",
            :insetsExtrusionProfile     => "insets",
            :infillsExtrusionProfile    => "infill",
            :outlinesExtrusionProfile   => "outlines",

            :feedDiameter         => 1.82, # diameter in mm of feedstock
            :nozzleDiameter       => 0.4,
            :retractDistance      => 1,    # mm
            :retractRate          => 20,   # mm/sec
            :restartExtraDistance => 0.0   # mm
          }
        ],
        # Different extrusion settings for each profile as defined above
        # Temperatures in degrees C and feedrate in mm/s
        :extrusionProfiles => {
          :insets     => { :temperature => 220.0, :feedrate => 80 },
          :infill     => { :temperature => 220.0, :feedrate => 80 },
          :firstlayer => { :temperature => 220.0, :feedrate => 50 },
          :outlines   => { :temperature => 220.0, :feedrate => 50 }
        }
      }
    end
  end
end
