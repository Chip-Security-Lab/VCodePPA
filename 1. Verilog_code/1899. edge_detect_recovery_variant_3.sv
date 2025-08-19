//SystemVerilog
module edge_detect_recovery (
    input wire clk,
    input wire rst_n,
    input wire signal_in,
    output reg rising_edge,
    output reg falling_edge,
    output reg [7:0] edge_count
);
    // 信号采样流水线
    reg [2:0] signal_shift;
    
    // 边沿检测流水线寄存器
    reg [1:0] rising_edge_pipe;
    reg [1:0] falling_edge_pipe;
    
    // 计数相关流水线寄存器
    reg [1:0] edge_detected_pipe;
    reg [7:0] edge_count_next;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 批量复位所有寄存器以减少代码复杂度
            signal_shift <= 3'b000;
            rising_edge_pipe <= 2'b00;
            falling_edge_pipe <= 2'b00;
            rising_edge <= 1'b0;
            falling_edge <= 1'b0;
            edge_detected_pipe <= 2'b00;
            edge_count_next <= 8'h00;
            edge_count <= 8'h00;
        end else begin
            // 阶段1: 信号采样和移位寄存器
            // 使用位拼接提高代码效率
            signal_shift <= {signal_shift[1:0], signal_in};
            
            // 阶段2: 边沿检测优化逻辑
            // 使用异或和与操作实现高效的边沿检测
            rising_edge_pipe[0] <= signal_shift[0] & ~signal_shift[1];
            falling_edge_pipe[0] <= ~signal_shift[0] & signal_shift[1];
            
            // 阶段3: 流水线传递
            rising_edge_pipe[1] <= rising_edge_pipe[0];
            rising_edge <= rising_edge_pipe[1];
            
            falling_edge_pipe[1] <= falling_edge_pipe[0];
            falling_edge <= falling_edge_pipe[1];
            
            // 边沿检测标志计算 - 使用或运算合并标志
            edge_detected_pipe[0] <= rising_edge_pipe[0] | falling_edge_pipe[0];
            edge_detected_pipe[1] <= edge_detected_pipe[0];
            
            // 计数器优化：使用单一更新路径减少MUX结构
            edge_count_next <= edge_count + {7'b0000000, edge_detected_pipe[1]};
            edge_count <= edge_count_next;
        end
    end
endmodule