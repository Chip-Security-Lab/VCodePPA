//SystemVerilog
module capture_compare_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire capture_trig,
    input wire [WIDTH-1:0] compare_val,
    output reg compare_match,
    output reg [WIDTH-1:0] capture_val
);
    reg [WIDTH-1:0] counter;
    reg [1:0] capture_trig_sync;  // 2-stage synchronizer
    
    // 优化的比较逻辑
    reg [WIDTH-1:0] compare_val_reg;
    wire compare_equal;
    
    // 优化边缘检测
    wire capture_edge;
    
    // 同步器和边缘检测
    always @(posedge clk) begin
        if (rst)
            capture_trig_sync <= 2'b00;
        else
            capture_trig_sync <= {capture_trig_sync[0], capture_trig};
    end
    
    // 边缘检测逻辑优化
    assign capture_edge = capture_trig_sync[1:0] == 2'b10;
    
    // 计数器和寄存器更新
    always @(posedge clk) begin
        if (rst) begin
            counter <= {WIDTH{1'b0}};
            compare_val_reg <= {WIDTH{1'b0}};
            compare_match <= 1'b0;
            capture_val <= {WIDTH{1'b0}};
        end else begin
            // 计数器逻辑
            counter <= counter + 1'b1;
            
            // 注册比较值以改善时序
            compare_val_reg <= compare_val;
            
            // 捕获操作 - 在检测到边缘时更新
            if (capture_edge)
                capture_val <= counter;
                
            // 比较匹配输出
            compare_match <= compare_equal;
        end
    end
    
    // 优化的比较逻辑 - 使用专用比较器实现
    // 从时序路径中分离比较逻辑以降低关键路径延迟
    assign compare_equal = (counter == compare_val_reg);

endmodule