//SystemVerilog
module param_mux_array #(
    parameter CHANNELS = 4,
    parameter WIDTH = 8,
    parameter SEL_BITS = $clog2(CHANNELS)
)(
    input [WIDTH-1:0] data_in [0:CHANNELS-1],
    input [SEL_BITS-1:0] channel_sel,
    output [WIDTH-1:0] data_out
);

    wire [WIDTH-1:0] decoded_data;
    wire [CHANNELS-1:0] channel_enable;

    channel_decoder #(
        .CHANNELS(CHANNELS),
        .SEL_BITS(SEL_BITS)
    ) decoder_inst (
        .sel(channel_sel),
        .enable(channel_enable)
    );

    data_selector #(
        .CHANNELS(CHANNELS),
        .WIDTH(WIDTH)
    ) selector_inst (
        .data_in(data_in),
        .channel_enable(channel_enable),
        .data_out(decoded_data)
    );

    output_register #(
        .WIDTH(WIDTH)
    ) reg_inst (
        .data_in(decoded_data),
        .data_out(data_out)
    );

endmodule

module channel_decoder #(
    parameter CHANNELS = 4,
    parameter SEL_BITS = 2
)(
    input [SEL_BITS-1:0] sel,
    output reg [CHANNELS-1:0] enable
);

    always @(*) begin
        enable = {CHANNELS{1'b0}};
        enable[sel] = 1'b1;
    end

endmodule

module data_selector #(
    parameter CHANNELS = 4,
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in [0:CHANNELS-1],
    input [CHANNELS-1:0] channel_enable,
    output reg [WIDTH-1:0] data_out
);

    wire [WIDTH-1:0] selected_data [0:CHANNELS-1];
    wire [WIDTH-1:0] carry_chain [0:CHANNELS];
    
    genvar i;
    generate
        for(i = 0; i < CHANNELS; i = i + 1) begin : data_select
            assign selected_data[i] = data_in[i] & {WIDTH{channel_enable[i]}};
        end
    endgenerate

    assign carry_chain[0] = {WIDTH{1'b0}};
    generate
        for(i = 0; i < CHANNELS; i = i + 1) begin : carry_prop
            assign carry_chain[i+1] = carry_chain[i] | selected_data[i];
        end
    endgenerate

    always @(*) begin
        data_out = carry_chain[CHANNELS];
    end

endmodule

module output_register #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

    always @(*) begin
        data_out = data_in;
    end

endmodule