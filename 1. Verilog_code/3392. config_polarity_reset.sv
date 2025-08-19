module config_polarity_reset #(
    parameter CHANNELS = 4
)(
    input wire reset_in,
    input wire [CHANNELS-1:0] polarity_config,
    output wire [CHANNELS-1:0] reset_out
);
    genvar i;
    generate
        for (i = 0; i < CHANNELS; i = i + 1) begin: reset_gen
            assign reset_out[i] = polarity_config[i] ? reset_in : ~reset_in;
        end
    endgenerate
endmodule
