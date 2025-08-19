//SystemVerilog
module priority_buf #(parameter DW=16) (
    input clk, rst_n,
    input [1:0] pri_level,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    // 内部存储器和指针
    reg [DW-1:0] mem[0:3];
    reg [1:0] rd_ptr;
    
    // 复位逻辑 - 单独的always块处理异步复位
    always @(negedge rst_n) begin
        if(!rst_n) begin
            mem[0] <= 0;
            mem[1] <= 0;
            mem[2] <= 0;
            mem[3] <= 0;
            rd_ptr <= 2'b00;
        end
    end
    
    // 写入逻辑 - 专门处理存储器写入操作
    always @(posedge clk) begin
        if(rst_n && wr_en) begin
            mem[pri_level] <= din;
        end
    end
    
    // 读取数据逻辑 - 专门处理数据输出
    always @(posedge clk) begin
        if(rst_n && rd_en) begin
            dout <= mem[rd_ptr];
        end
    end
    
    // 先行借位减法器实现 (2位)
    wire borrow_in, borrow_mid;
    wire [1:0] next_ptr;
    
    assign borrow_in = 1'b0; // 初始无借位
    assign borrow_mid = (~rd_ptr[0]) & 1'b1; // 第一位借位逻辑
    
    // 计算每一位的结果: A - B - borrow_in
    assign next_ptr[0] = rd_ptr[0] ^ 1'b1 ^ borrow_in;
    assign next_ptr[1] = rd_ptr[1] ^ 1'b0 ^ borrow_mid;
    
    // 溢出检测逻辑
    wire is_max;
    assign is_max = (rd_ptr == 2'b11);
    
    // 读取指针更新逻辑 - 专门处理指针更新
    always @(posedge clk) begin
        if(rst_n && rd_en) begin
            rd_ptr <= is_max ? 2'b00 : next_ptr;
        end
    end
endmodule