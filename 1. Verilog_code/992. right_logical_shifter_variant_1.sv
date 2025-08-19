//SystemVerilog
module right_logical_shifter #(
    parameter WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire enable,
    input wire [WIDTH-1:0] in_data,
    input wire [$clog2(WIDTH)-1:0] shift_amount,
    output reg [WIDTH-1:0] out_data
);

    wire [WIDTH-1:0] stage [0:$clog2(WIDTH)];
    integer i;

    assign stage[0] = in_data;

    genvar k;
    generate
        for (k = 0; k < $clog2(WIDTH); k = k + 1) begin : barrel_shifter
            wire [WIDTH-1:0] shifted;
            assign shifted = stage[k] >> (1 << k);
            assign stage[k+1] = shift_amount[k] ? shifted : stage[k];
        end
    endgenerate

    wire [WIDTH-1:0] shifted_data;
    assign shifted_data = (shift_amount >= WIDTH) ? {WIDTH{1'b0}} : stage[$clog2(WIDTH)];

    always @(posedge clock) begin
        if (reset) begin
            out_data <= {WIDTH{1'b0}};
        end else if (enable) begin
            out_data <= shifted_data;
        end
    end

endmodule