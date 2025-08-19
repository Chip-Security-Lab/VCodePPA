//SystemVerilog
module autoincrement_buffer (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire valid_in,
    output wire ready_out,
    input wire ready_in,
    output reg valid_out,
    output reg [7:0] data_out
);
    reg [7:0] memory [0:15];
    reg [3:0] write_addr;
    reg [3:0] read_addr;
    reg [4:0] count;
    
    // 优化ready_out信号，将reg改为wire以减少逻辑层级
    assign ready_out = (count < 16);
    
    // 预计算count变化情况，降低关键路径复杂度
    reg count_inc, count_dec;
    wire [4:0] next_count;
    
    always @(*) begin
        count_inc = valid_in && ready_out && (count < 16);
        count_dec = ready_in && valid_out && (count > 0);
    end
    
    // 平衡计数逻辑路径
    assign next_count = count + count_inc - count_dec;
    
    // 预计算下一个valid_out状态
    wire next_valid_out;
    assign next_valid_out = (count == 0 && count_inc) ? 1'b1 :
                           ((count == 1) && count_dec) ? 1'b0 : valid_out;
    
    // 写入和计数逻辑重构
    always @(posedge clk) begin
        if (rst) begin
            write_addr <= 4'b0;
            count <= 5'b0;
            valid_out <= 1'b0;
        end else begin
            // 更新计数值
            count <= next_count;
            valid_out <= next_valid_out;
            
            // 写入逻辑优化
            if (valid_in && ready_out) begin
                memory[write_addr] <= data_in;
                write_addr <= write_addr + 1;
            end
            
            // 读取地址更新优化
            if (ready_in && valid_out) begin
                read_addr <= read_addr + 1;
            end
        end
    end
    
    // 读取逻辑优化 - 添加输出寄存器以增强时序性能
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 8'b0;
            read_addr <= 4'b0;
        end else if (ready_in && valid_out) begin
            data_out <= memory[read_addr];
        end
    end
endmodule