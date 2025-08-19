module DynamicWidthBridge #(
    parameter IN_W = 32,
    parameter OUT_W = 64
)(
    input clk, rst_n,
    input [IN_W-1:0] data_in,
    input in_valid,
    output [OUT_W-1:0] data_out,
    output out_valid
);
    localparam RATIO = OUT_W / IN_W;
    reg [OUT_W-1:0] shift_reg;
    reg [3:0] count = 0;

    always @(posedge clk) begin
        if (in_valid) begin
            shift_reg <= {shift_reg[IN_W-1:0], data_in};
            count <= (count == RATIO-1) ? 0 : count + 1;
        end
    end
    assign data_out = shift_reg;
    assign out_valid = (count == RATIO-1) & in_valid;
endmodule