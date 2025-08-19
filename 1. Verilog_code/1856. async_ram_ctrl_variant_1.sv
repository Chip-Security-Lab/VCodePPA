//SystemVerilog
module async_ram_ctrl #(parameter DATA_W=8, ADDR_W=4, DEPTH=16) (
    input wr_clk, rd_clk, rst,
    input [DATA_W-1:0] din,
    input [ADDR_W-1:0] waddr, raddr,
    input we,
    output reg [DATA_W-1:0] dout
);
    (* ram_style = "block" *) reg [DATA_W-1:0] mem [0:DEPTH-1];
    reg [DATA_W-1:0] din_reg;
    reg [ADDR_W-1:0] waddr_reg;
    reg we_reg;
    reg [ADDR_W-1:0] raddr_reg;
    
    // 写侧信号寄存器
    always_ff @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            din_reg <= '0;
            waddr_reg <= '0;
            we_reg <= 1'b0;
        end else begin
            din_reg <= din;
            waddr_reg <= waddr;
            we_reg <= we;
        end
    end
    
    // 读地址寄存器
    always_ff @(posedge rd_clk or posedge rst) begin
        if (rst)
            raddr_reg <= '0;
        else
            raddr_reg <= raddr;
    end
    
    // 写存储器逻辑
    always_ff @(posedge wr_clk) begin
        if (we_reg) begin
            mem[waddr_reg] <= din_reg;
        end
    end
    
    // 异步复位初始化
    initial begin
        for (int i = 0; i < DEPTH; i++)
            mem[i] = '0;
    end
    
    // 读存储器逻辑
    always_ff @(posedge rd_clk or posedge rst) begin
        if (rst)
            dout <= '0;
        else
            dout <= mem[raddr_reg];
    end
endmodule