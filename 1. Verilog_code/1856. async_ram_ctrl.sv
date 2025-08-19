module async_ram_ctrl #(parameter DATA_W=8, ADDR_W=4, DEPTH=16) (
    input wr_clk, rd_clk, rst,
    input [DATA_W-1:0] din,
    input [ADDR_W-1:0] waddr, raddr,
    input we,
    output reg [DATA_W-1:0] dout
);
    reg [DATA_W-1:0] mem [0:DEPTH-1];
    integer i;
    
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            for(i=0; i<DEPTH; i=i+1)
                mem[i] <= 0;
        end else if (we) begin
            mem[waddr] <= din;
        end
    end
    
    always @(posedge rd_clk) 
        dout <= mem[raddr];
endmodule