//SystemVerilog
module dynamic_mask #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] mask_pattern,
    input wire mask_en,
    output wire [WIDTH-1:0] data_out
);
    mask_controller #(
        .WIDTH(WIDTH)
    ) mask_ctrl_inst (
        .data_in(data_in),
        .mask_pattern(mask_pattern),
        .mask_en(mask_en),
        .data_out(data_out)
    );
endmodule

module mask_controller #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] mask_pattern,
    input wire mask_en,
    output reg [WIDTH-1:0] data_out
);
    always @(*) begin
        if (mask_en) begin
            data_out = data_in & mask_pattern;
        end else begin
            data_out = data_in;
        end
    end
endmodule