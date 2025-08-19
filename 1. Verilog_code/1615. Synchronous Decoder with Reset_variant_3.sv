//SystemVerilog
// Top level module
module sync_decoder_with_reset #(
    parameter ADDR_BITS = 2,
    parameter OUT_BITS = 4
)(
    input wire clk,
    input wire rst,
    input wire [ADDR_BITS-1:0] addr,
    output wire [OUT_BITS-1:0] decode
);

    // Internal signals
    wire [OUT_BITS-1:0] shift_out;
    wire [OUT_BITS-1:0] reset_out;

    // Shift module instance
    shift_module #(
        .ADDR_BITS(ADDR_BITS),
        .OUT_BITS(OUT_BITS)
    ) shift_inst (
        .addr(addr),
        .shift_out(shift_out)
    );

    // Reset control module instance
    reset_control #(
        .OUT_BITS(OUT_BITS)
    ) reset_inst (
        .clk(clk),
        .rst(rst),
        .data_in(shift_out),
        .data_out(reset_out)
    );

    // Output assignment
    assign decode = reset_out;

endmodule

// Shift module
module shift_module #(
    parameter ADDR_BITS = 2,
    parameter OUT_BITS = 4
)(
    input wire [ADDR_BITS-1:0] addr,
    output wire [OUT_BITS-1:0] shift_out
);

    assign shift_out = (1 << addr);

endmodule

// Reset control module
module reset_control #(
    parameter OUT_BITS = 4
)(
    input wire clk,
    input wire rst,
    input wire [OUT_BITS-1:0] data_in,
    output reg [OUT_BITS-1:0] data_out
);

    always @(posedge clk) begin
        data_out <= rst ? {OUT_BITS{1'b0}} : data_in;
    end

endmodule