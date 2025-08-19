//SystemVerilog
module ClockGating #(
    parameter SYNC_STAGES = 2
)(
    input clk, rst_n,
    input enable,
    input test_mode,
    output gated_clk
);
    reg [SYNC_STAGES-1:0] enable_sync;
    reg clock_gate;
    wire final_gate;

    // 同步使能信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            enable_sync <= {enable_sync[SYNC_STAGES-2:0], enable};
        end
    end

    // 时钟门控逻辑
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clock_gate <= 1'b0;
        end else begin
            clock_gate <= enable_sync[SYNC_STAGES-1] | test_mode;
        end
    end

    // 优化的门控逻辑，减少逻辑层级
    assign final_gate = clock_gate;
    
    // 优化的时钟输出，使用赋值而不是always块
    assign gated_clk = clk & final_gate;
endmodule