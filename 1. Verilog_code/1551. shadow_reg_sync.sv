module shadow_reg_sync #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] shadow;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) {data_out, shadow} <= 0;
        else if(en) shadow <= data_in;
        else data_out <= shadow;
    end
endmodule