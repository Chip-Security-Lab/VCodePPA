//SystemVerilog
module MAF #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n, en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    reg [WIDTH+3:0] acc;
    reg [WIDTH-1:0] din_reg;
    reg en_reg;
    integer i;
    
    // 输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            din_reg <= 0;
            en_reg <= 0;
        end else begin
            din_reg <= din;
            en_reg <= en;
        end
    end
    
    // 主逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            acc <= 0;
            dout <= 0;
            for(i=0; i<DEPTH; i=i+1)
                buffer[i] <= 0;
        end else if(en_reg) begin
            for(i=DEPTH-1; i>0; i=i-1)
                buffer[i] <= buffer[i-1];
            buffer[0] <= din_reg;
            
            acc <= acc + din_reg - buffer[DEPTH-1];
            dout <= acc / DEPTH;
        end
    end
endmodule