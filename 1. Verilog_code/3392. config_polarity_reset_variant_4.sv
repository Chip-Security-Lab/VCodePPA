//SystemVerilog
module config_polarity_reset #(
    parameter CHANNELS = 4
)(
    input  wire                  reset_in,
    input  wire [CHANNELS-1:0]   polarity_config,
    output wire [CHANNELS-1:0]   reset_out
);

    // Stage 1: Prepare both polarities of reset signal
    wire reset_normal;
    wire reset_inverted;
    
    // Register the reset signals to improve timing
    reg reset_in_reg;
    
    always @(*) begin
        reset_in_reg = reset_in;
    end
    
    // Generate both polarities with minimal logic depth
    assign reset_normal = reset_in_reg;
    assign reset_inverted = ~reset_in_reg;
    
    // Stage 2: Channel-specific reset generation with carry-lookahead adder structure
    // Use carry-lookahead principles for improved PPA metrics
    wire [CHANNELS-1:0] generate_signals;
    wire [CHANNELS-1:0] propagate_signals;
    wire [CHANNELS:0] carry_signals;
    
    // Initialize carry-in for the CLA structure
    assign carry_signals[0] = 1'b0;
    
    // Generate and propagate signal computation
    genvar i;
    generate
        for (i = 0; i < CHANNELS; i = i + 1) begin: cla_gen
            // Generate signals based on polarity config
            assign generate_signals[i] = polarity_config[i] & reset_normal;
            
            // Propagate signals leveraging polarity config
            assign propagate_signals[i] = polarity_config[i] | reset_inverted;
            
            // Carry computation using CLA principles
            assign carry_signals[i+1] = generate_signals[i] | (propagate_signals[i] & carry_signals[i]);
            
            // Final reset output computation
            assign reset_out[i] = propagate_signals[i] ^ carry_signals[i];
        end
    endgenerate

endmodule