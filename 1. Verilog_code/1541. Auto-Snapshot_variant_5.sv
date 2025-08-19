//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog标准
module auto_snapshot_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire error_detected,
    output reg [WIDTH-1:0] shadow_data,
    output reg snapshot_taken
);
    // 主数据寄存器
    reg [WIDTH-1:0] main_reg;
    
    // 错误状态和捕获控制信号
    reg error_pending;
    
    // 主寄存器更新 - 使用非阻塞赋值保持时序一致性
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg <= {WIDTH{1'b0}};
        else 
            main_reg <= data_in;
    end
    
    // 优化的错误跟踪和捕获逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_pending <= 1'b0;
            snapshot_taken <= 1'b0;
            shadow_data <= {WIDTH{1'b0}};
        end
        else begin
            // 优化比较链，使用更简洁的表达式
            if (error_detected && !error_pending && !snapshot_taken) begin
                shadow_data <= main_reg;
                snapshot_taken <= 1'b1;
                error_pending <= 1'b1;
            end
            else if (!error_detected) begin
                error_pending <= 1'b0;
            end
        end
    end
endmodule