//SystemVerilog
module ClockGating #(
    parameter SYNC_STAGES = 2
)(
    input clk, rst_n,
    input enable,
    input test_mode,
    output reg gated_clk
);
    reg [SYNC_STAGES-1:0] enable_sync;
    reg clock_gate;
    reg test_mode_reg;
    
    // 同步使能信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_sync <= 0;
        end else begin
            enable_sync <= {enable_sync[SYNC_STAGES-2:0], enable};
        end
    end

    // 时钟门控逻辑
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clock_gate <= 0;
        end else begin
            clock_gate <= enable_sync[SYNC_STAGES-1];
        end
    end
    
    // 注册测试模式信号以减少关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_mode_reg <= 0;
        end else begin
            test_mode_reg <= test_mode;
        end
    end

    // 优化输出时钟逻辑，减少组合逻辑延迟
    always @(*) begin
        if (test_mode_reg) begin
            gated_clk = clk;
        end else begin
            gated_clk = clk & clock_gate;
        end
    end
endmodule