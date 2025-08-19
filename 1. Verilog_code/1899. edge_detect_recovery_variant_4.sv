//SystemVerilog
module edge_detect_recovery (
    input wire clk,
    input wire rst_n,
    input wire signal_in,
    output reg rising_edge,
    output reg falling_edge,
    output reg [7:0] edge_count
);
    // 流水线Stage1: 信号捕获和边沿检测预处理
    reg signal_stage1;
    reg signal_prev_stage1;
    
    // 流水线Stage2: 边沿判断
    reg signal_stage2;
    reg signal_prev_stage2;
    wire edge_detected_stage2;
    reg rising_edge_stage2;
    reg falling_edge_stage2;
    
    // 流水线Stage3: 边沿计数和输出准备
    reg edge_detected_stage3;
    reg rising_edge_stage3;
    reg falling_edge_stage3;
    
    // 边沿检测逻辑
    assign edge_detected_stage2 = signal_prev_stage2 ^ signal_stage2;
    
    // 流水线Stage1: 信号捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_stage1 <= 1'b0;
            signal_prev_stage1 <= 1'b0;
        end else begin
            signal_stage1 <= signal_in;
            signal_prev_stage1 <= signal_stage1;
        end
    end
    
    // 流水线Stage2: 边沿判断
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_stage2 <= 1'b0;
            signal_prev_stage2 <= 1'b0;
            rising_edge_stage2 <= 1'b0;
            falling_edge_stage2 <= 1'b0;
        end else begin
            signal_stage2 <= signal_stage1;
            signal_prev_stage2 <= signal_prev_stage1;
            
            // 边沿检测
            rising_edge_stage2 <= signal_stage2 & ~signal_prev_stage2;
            falling_edge_stage2 <= ~signal_stage2 & signal_prev_stage2;
        end
    end
    
    // 流水线Stage3: 边沿计数和输出准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_detected_stage3 <= 1'b0;
            rising_edge_stage3 <= 1'b0;
            falling_edge_stage3 <= 1'b0;
            rising_edge <= 1'b0;
            falling_edge <= 1'b0;
            edge_count <= 8'h00;
        end else begin
            edge_detected_stage3 <= edge_detected_stage2;
            rising_edge_stage3 <= rising_edge_stage2;
            falling_edge_stage3 <= falling_edge_stage2;
            
            // 输出最终结果
            rising_edge <= rising_edge_stage3;
            falling_edge <= falling_edge_stage3;
            
            // 计数逻辑
            if (edge_detected_stage3)
                edge_count <= edge_count + 1'b1;
        end
    end
endmodule