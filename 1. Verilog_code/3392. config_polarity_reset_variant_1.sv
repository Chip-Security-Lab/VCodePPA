//SystemVerilog
module config_polarity_reset #(
    parameter CHANNELS = 4
)(
    input  wire                 clk,              // Clock input
    input  wire                 reset_in,         // Input reset signal
    input  wire [CHANNELS-1:0]  polarity_config,  // Polarity configuration bits
    output reg  [CHANNELS-1:0]  reset_out         // Output reset signals
);

    // Registered polarity configuration and input reset signal
    reg [CHANNELS-1:0] polarity_config_r;
    reg reset_in_r;
    
    // Intermediate signals for better path organization
    wire [CHANNELS-1:0] reset_normal;
    wire [CHANNELS-1:0] reset_inverted;
    reg [CHANNELS-1:0] reset_selected;

    // Prepare both polarities in parallel
    assign reset_normal = {CHANNELS{reset_in_r}};
    assign reset_inverted = {CHANNELS{~reset_in_r}};
    
    // Combined always block for all clocked operations
    always @(posedge clk) begin
        // Stage 1: Register inputs
        polarity_config_r <= polarity_config;
        reset_in_r <= reset_in;
        
        // Stage 3: Select appropriate polarity based on configuration
        for (integer i = 0; i < CHANNELS; i = i + 1) begin
            reset_selected[i] <= polarity_config_r[i] ? reset_normal[i] : reset_inverted[i];
        end
        
        // Stage 4: Register outputs
        reset_out <= reset_selected;
    end

endmodule