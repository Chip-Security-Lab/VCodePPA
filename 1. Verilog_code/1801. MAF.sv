module MAF #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n, en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    reg [WIDTH+3:0] acc;
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            acc <= 0;
            dout <= 0;
            for(i=0; i<DEPTH; i=i+1)
                buffer[i] <= 0;
        end else if(en) begin
            // 手动移位缓冲区
            for(i=DEPTH-1; i>0; i=i-1)
                buffer[i] <= buffer[i-1];
            buffer[0] <= din;
            
            acc <= acc + din - buffer[DEPTH-1];
            // 对于2的幂DEPTH，这将合成为移位
            dout <= acc / DEPTH;
        end
    end
endmodule