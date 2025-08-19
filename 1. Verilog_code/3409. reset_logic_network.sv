module reset_logic_network(
    input wire [3:0] reset_sources,
    input wire [3:0] config_bits,
    output wire [3:0] reset_outputs
);
    // Output uses AND or OR based on config
    assign reset_outputs[0] = config_bits[0] ? 
        (reset_sources[0] & reset_sources[1]) : 
        (reset_sources[0] | reset_sources[1]);
    assign reset_outputs[1] = config_bits[1] ? 
        (reset_sources[1] & reset_sources[2]) : 
        (reset_sources[1] | reset_sources[2]);
    assign reset_outputs[2] = config_bits[2] ? 
        (reset_sources[2] & reset_sources[3]) : 
        (reset_sources[2] | reset_sources[3]);
    assign reset_outputs[3] = config_bits[3] ? 
        (reset_sources[3] & reset_sources[0]) : 
        (reset_sources[3] | reset_sources[0]);
endmodule
