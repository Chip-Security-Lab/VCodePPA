//SystemVerilog
module mask_control #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] mask_pattern,
    input mask_en,
    output [WIDTH-1:0] masked_data
);
    assign masked_data = data_in & mask_pattern;
endmodule

module data_selector #(parameter WIDTH=8) (
    input [WIDTH-1:0] original_data,
    input [WIDTH-1:0] masked_data,
    input mask_en,
    output reg [WIDTH-1:0] data_out
);
    always @(*) begin
        data_out = mask_en ? masked_data : original_data;
    end
endmodule

module dynamic_mask #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] mask_pattern,
    input mask_en,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] masked_data;

    mask_control #(.WIDTH(WIDTH)) mask_control_inst (
        .data_in(data_in),
        .mask_pattern(mask_pattern),
        .mask_en(mask_en),
        .masked_data(masked_data)
    );

    data_selector #(.WIDTH(WIDTH)) data_selector_inst (
        .original_data(data_in),
        .masked_data(masked_data),
        .mask_en(mask_en),
        .data_out(data_out)
    );
endmodule