//SystemVerilog
module rising_edge_detector #(
    parameter COUNT_LIMIT = 4
)(
    input  wire clk_in,
    input  wire rst_n,
    input  wire signal_in,
    output reg  edge_detected,
    output reg [$clog2(COUNT_LIMIT):0] edge_count
);
    // 信号采样阶段
    reg signal_d1;
    reg signal_d2;
    
    // 边沿检测阶段
    wire edge_found_pre;
    reg  edge_found_reg;
    
    // 计数器控制信号
    reg counter_reset;
    reg counter_increment;
    
    // 边沿检测逻辑 - 第一阶段：边沿识别
    assign edge_found_pre = signal_d1 & ~signal_d2;
    
    // 第一阶段：信号采样
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            signal_d1 <= 1'b0;
            signal_d2 <= 1'b0;
        end else begin
            signal_d1 <= signal_in;
            signal_d2 <= signal_d1;
        end
    end
    
    // 第二阶段：边沿检测与计数器控制信号生成
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            edge_found_reg <= 1'b0;
            edge_detected <= 1'b0;
            counter_reset <= 1'b0;
            counter_increment <= 1'b0;
        end else begin
            edge_found_reg <= edge_found_pre;
            edge_detected <= edge_found_reg;
            
            // 计数器控制逻辑
            counter_reset <= edge_found_reg && (edge_count == COUNT_LIMIT - 1);
            counter_increment <= edge_found_reg && (edge_count < COUNT_LIMIT);
        end
    end
    
    // 第三阶段：计数器更新
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            edge_count <= {$clog2(COUNT_LIMIT)+1{1'b0}};
        end else begin
            if (counter_reset) begin
                edge_count <= {$clog2(COUNT_LIMIT)+1{1'b0}};
            end else if (counter_increment) begin
                edge_count <= edge_count + 1'b1;
            end
        end
    end
endmodule