module rle_buffer #(parameter DW=8) (
    input clk, en,
    input [DW-1:0] din,
    output reg [2*DW-1:0] dout
);
    reg [DW-1:0] prev;
    reg [DW-1:0] count=0;
    
    always @(posedge clk) if(en) begin
        if(din == prev) count <= count + 1;
        else begin
            dout <= {count, prev};
            prev <= din;
            count <= 1;
        end
    end
endmodule
