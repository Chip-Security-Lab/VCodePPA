module shadow_reg_dynamic #(parameter MAX_WIDTH=16) (
    input clk,
    input [3:0] width_sel,
    input [MAX_WIDTH-1:0] data_in,
    output reg [MAX_WIDTH-1:0] data_out
);
    reg [MAX_WIDTH-1:0] shadow;
    always @(posedge clk) begin
        shadow <= data_in;
        data_out <= shadow & ((1 << width_sel) - 1);
    end
endmodule