//SystemVerilog
module autoincrement_buffer (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  data_in,
    input  wire        write,
    input  wire        read,
    output reg  [7:0]  data_out
);
    // 内存阵列
    reg [7:0] memory [0:15];
    
    // 地址管理
    reg [3:0] write_addr;
    reg [3:0] read_addr;
    
    // 单一控制流水线级别
    reg write_valid;
    reg read_valid;
    
    // 高扇出信号的缓冲寄存器
    reg write_buf1, write_buf2;
    reg rst_buf1, rst_buf2;
    
    // 为高扇出信号添加缓冲寄存器
    always @(posedge clk) begin
        write_buf1 <= write;
        write_buf2 <= write;
        rst_buf1 <= rst;
        rst_buf2 <= rst;
    end
    
    // 优化的地址控制逻辑
    always @(posedge clk or posedge rst_buf1) begin
        if (rst_buf1) begin
            write_addr <= 4'b0;
            read_addr  <= 4'b0;
            write_valid <= 1'b0;
            read_valid <= 1'b0;
        end
        else begin
            // 使用并行赋值提高清晰度和综合效率
            write_valid <= write_buf1;
            read_valid <= read;
            
            // 条件自增，避免不必要的加法器消耗
            if (write_buf1)
                write_addr <= write_addr + 1'b1;
                
            // 读地址控制逻辑改进
            // 直接跟随写地址更新，减少额外的寄存器依赖
            read_addr <= write_buf1;
        end
    end
    
    // 优化的内存访问逻辑：合并写入和读取操作
    always @(posedge clk) begin
        // 内存写入路径 - 不受复位影响
        if (write_buf2)
            memory[write_addr] <= data_in;
            
        // 数据输出路径 - 使用异步复位提高响应速度
        if (rst_buf2)
            data_out <= 8'b0;
        else if (read)
            data_out <= memory[read_addr];
    end
    
endmodule