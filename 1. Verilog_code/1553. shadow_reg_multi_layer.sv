module shadow_reg_multi_layer #(parameter DW=8, DEPTH=3) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out
);
    reg [DW-1:0] shadow [0:DEPTH-1];
    reg [1:0] ptr;
    always @(posedge clk) begin
        if(rst) ptr <= 0;
        else if(en) begin
            shadow[ptr] <= data_in;
            ptr <= (ptr == DEPTH-1) ? 0 : ptr + 1;
        end
    end
    assign data_out = shadow[ptr];
endmodule
