//SystemVerilog
module dynamic_mask #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] mask_pattern,
    input mask_en,
    output [WIDTH-1:0] data_out
);
    wire [WIDTH-1:0] masked_data;
    wire [WIDTH-1:0] bypass_data;
    
    mask_generator #(
        .WIDTH(WIDTH)
    ) mask_gen_inst (
        .data_in(data_in),
        .mask_pattern(mask_pattern),
        .masked_data(masked_data)
    );
    
    data_selector #(
        .WIDTH(WIDTH)
    ) data_sel_inst (
        .masked_data(masked_data),
        .bypass_data(data_in),
        .select_masked(mask_en),
        .data_out(data_out)
    );
endmodule

module mask_generator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] mask_pattern,
    output [WIDTH-1:0] masked_data
);
    assign masked_data = data_in & mask_pattern;
endmodule

module data_selector #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] masked_data,
    input [WIDTH-1:0] bypass_data,
    input select_masked,
    output reg [WIDTH-1:0] data_out
);
    always @(*) begin
        if (select_masked) begin
            data_out = masked_data;
        end else begin
            data_out = bypass_data;
        end
    end
endmodule