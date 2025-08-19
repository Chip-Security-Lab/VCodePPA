//SystemVerilog
module i2c_multi_slave #(
    parameter ADDR_COUNT = 4,
    parameter ADDR_WIDTH = 7
)(
    input clk,
    input rst_sync_n,
    inout sda,
    inout scl,
    output reg [7:0] data_out [0:ADDR_COUNT-1],
    input [7:0] addr_mask [0:ADDR_COUNT-1]
);
    // 优化：直接在输入处寄存输入信号
    reg sda_reg, scl_reg;
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            sda_reg <= 1'b0;
            scl_reg <= 1'b0;
        end else begin
            sda_reg <= sda;
            scl_reg <= scl;
        end
    end
    
    // 重新设计的状态变量
    reg [ADDR_WIDTH-1:0] recv_addr;
    reg [7:0] shift_reg;
    reg [3:0] bit_counter;
    reg data_valid;
    reg addr_updated;
    reg [ADDR_COUNT-1:0] addr_match_vector; // 位向量形式存储地址匹配结果
    
    // Initialize all registers
    integer j;
    initial begin
        recv_addr = 0;
        data_valid = 0;
        shift_reg = 0;
        bit_counter = 0;
        addr_updated = 0;
        addr_match_vector = 0;
        for (j=0; j<ADDR_COUNT; j=j+1) begin
            data_out[j] = 0;
        end
    end
    
    // 优化的数据接收逻辑 - 将寄存器前移到输入后
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            shift_reg <= 8'h00;
            data_valid <= 1'b0;
            bit_counter <= 4'd0;
            addr_updated <= 1'b0;
        end else begin
            // 默认状态
            data_valid <= 1'b0;
            addr_updated <= 1'b0;
            
            // 当时钟上升沿时移位数据
            if (scl_reg) begin
                shift_reg <= {shift_reg[6:0], sda_reg};
                
                // 使用Han-Carlson加法器实现bit_counter加法
                bit_counter <= han_carlson_adder_4bit(bit_counter, 4'd1);
                
                // 当接收到完整字节
                if (bit_counter == 4'd7) begin
                    data_valid <= 1'b1;
                    bit_counter <= 4'd0;
                    addr_updated <= 1'b1; // 标记地址更新
                end
            end
        end
    end
    
    // 地址捕获和匹配逻辑 - 组合优化后的组件
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            recv_addr <= {ADDR_WIDTH{1'b0}};
            addr_match_vector <= {ADDR_COUNT{1'b0}};
        end else begin
            // 当有新的有效数据时更新地址
            if (addr_updated) begin
                recv_addr <= shift_reg[ADDR_WIDTH-1:0];
                
                // 立即计算所有地址匹配 - 减少寄存器延迟
                for (j=0; j<ADDR_COUNT; j=j+1) begin
                    addr_match_vector[j] <= ((shift_reg[ADDR_WIDTH-1:0] & ~addr_mask[j][6:0]) == 0);
                end
            end
        end
    end
    
    // 优化的数据输出逻辑 - 使用位向量实现并行处理
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            for (j=0; j<ADDR_COUNT; j=j+1)
                data_out[j] <= 8'h00;
        end else if (data_valid) begin
            // 使用位向量高效处理多个地址匹配
            for (j=0; j<ADDR_COUNT; j=j+1) begin
                if (addr_match_vector[j])
                    data_out[j] <= shift_reg;
            end
        end
    end
    
    // 8位Han-Carlson并行前缀加法器函数实现
    function [3:0] han_carlson_adder_4bit;
        input [3:0] a;
        input [3:0] b;
        
        reg [3:0] p; // 生成位
        reg [3:0] g; // 传播位
        reg [3:0] c; // 进位信号
        reg [3:0] sum; // 求和结果
        
        begin
            // 第1阶段：生成p和g信号
            p = a ^ b;
            g = a & b;
            
            // 第2阶段：生成组进位信号(奇数位)
            c[1] = g[0] | (p[0] & 1'b0); // 初始进位为0
            c[3] = g[2] | (p[2] & c[1]); 
            
            // 第3阶段：生成组进位信号(偶数位)
            c[0] = 1'b0; // 初始进位为0
            c[2] = g[1] | (p[1] & c[1]);
            
            // 第4阶段：计算最终和
            sum = p ^ c;
            han_carlson_adder_4bit = sum;
        end
    endfunction
endmodule