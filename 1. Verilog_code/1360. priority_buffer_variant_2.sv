//SystemVerilog
module priority_buffer (
    input wire clk,
    input wire [7:0] data_a, data_b, data_c,
    input wire valid_a, valid_b, valid_c,
    output reg [7:0] data_out,
    output reg [1:0] source
);
    // 组合逻辑预先确定优先级
    reg [7:0] next_data;
    reg [1:0] next_source;
    
    // 添加缓冲寄存器，为不同负载提供独立的驱动源
    reg [7:0] next_data_buf1_a, next_data_buf1_b, next_data_buf1_c;
    reg [1:0] next_source_buf1_a, next_source_buf1_b, next_source_buf1_c;
    
    // 第二级缓冲用于进一步分散负载
    reg [7:0] next_data_buf2_a, next_data_buf2_b;
    reg [1:0] next_source_buf2_a, next_source_buf2_b;
    
    always @(*) begin
        // 默认值防止锁存器生成
        next_data = data_out;
        next_source = source;
        
        // 优先级编码 - 一次性并行评估
        casez ({valid_a, valid_b, valid_c})
            3'b1??: begin  // A有效，最高优先级
                next_data = data_a;
                next_source = 2'b00;
            end
            3'b01?: begin  // A无效，B有效
                next_data = data_b;
                next_source = 2'b01;
            end
            3'b001: begin  // A和B无效，C有效
                next_data = data_c;
                next_source = 2'b10;
            end
            default: begin
                // 保持原值
            end
        endcase
    end
    
    // 分散负载的多级缓冲实现
    always @(posedge clk) begin
        // 第一级缓冲寄存器 - 分为三路以分散扇出负载
        next_data_buf1_a <= next_data;
        next_data_buf1_b <= next_data;
        next_data_buf1_c <= next_data;
        
        next_source_buf1_a <= next_source;
        next_source_buf1_b <= next_source;
        next_source_buf1_c <= next_source;
        
        // 第二级缓冲寄存器 - 进一步分散负载
        next_data_buf2_a <= next_data_buf1_a;
        next_data_buf2_b <= next_data_buf1_b;
        
        next_source_buf2_a <= next_source_buf1_a;
        next_source_buf2_b <= next_source_buf1_b;
        
        // 最终输出寄存器更新 - 从不同的缓冲中获取数据以平衡负载
        data_out <= next_data_buf2_a;
        source <= next_source_buf2_b;
    end
endmodule