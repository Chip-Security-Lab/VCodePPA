module SyncNor(input clk, rst, a, b, output reg y);
    always @(posedge clk) begin
        if(rst) y <= 0;
        else y <= ~(a | b);
    end
endmodule