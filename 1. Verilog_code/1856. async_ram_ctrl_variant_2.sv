//SystemVerilog
module async_ram_ctrl #(parameter DATA_W=8, ADDR_W=4, DEPTH=16) (
    input wr_clk, rd_clk, rst,
    input [DATA_W-1:0] din,
    input [ADDR_W-1:0] waddr, raddr,
    input we,
    input sub_op,  // 减法操作控制信号
    output reg [DATA_W-1:0] dout
);
    reg [DATA_W-1:0] mem [0:DEPTH-1];
    integer i;
    
    // 注册输入数据和地址，实现前向寄存器重定时
    reg [DATA_W-1:0] din_reg;
    reg [ADDR_W-1:0] waddr_reg;
    reg we_reg;
    reg sub_op_reg;  // 注册减法操作控制信号
    reg [ADDR_W-1:0] raddr_reg;
    
    // 补码加法实现减法所需的信号
    reg [DATA_W-1:0] operand_b;
    reg [DATA_W-1:0] add_result;
    
    // 在写时钟域注册输入信号
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            din_reg <= 0;
            waddr_reg <= 0;
            we_reg <= 0;
            sub_op_reg <= 0;
        end else begin
            din_reg <= din;
            waddr_reg <= waddr;
            we_reg <= we;
            sub_op_reg <= sub_op;
        end
    end
    
    // 补码加法实现减法逻辑
    always @(*) begin
        if (sub_op_reg) begin
            // 使用补码加法: A - B = A + (-B) = A + (~B + 1)
            operand_b = ~mem[raddr_reg] + 1'b1;
            add_result = din_reg + operand_b;
        end else begin
            add_result = din_reg;
        end
    end
    
    // 写存储逻辑
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            for(i=0; i<DEPTH; i=i+1)
                mem[i] <= 0;
        end else if (we_reg) begin
            mem[waddr_reg] <= sub_op_reg ? add_result : din_reg;
        end
    end
    
    // 在读时钟域注册读地址
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            raddr_reg <= 0;
        end else begin
            raddr_reg <= raddr;
        end
    end
    
    // 读取逻辑
    always @(posedge rd_clk) 
        dout <= mem[raddr_reg];
endmodule