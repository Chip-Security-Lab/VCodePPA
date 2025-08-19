//SystemVerilog
module phase_locked_clk(
    input ref_clk,
    input target_clk,
    input rst,
    output reg clk_out,
    output reg locked
);
    // 状态编码优化为独热码，改善时序和资源利用
    localparam PHASE_0 = 2'b01;
    localparam PHASE_1 = 2'b10;
    
    reg [1:0] phase_state;
    reg ref_sync, target_sync;
    reg ref_detect_meta, target_detect_meta; // 添加亚稳态寄存器以改善时序
    
    // 参考时钟域中的双寄存器同步器
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            ref_detect_meta <= 1'b0;
            ref_sync <= 1'b0;
        end else begin
            ref_detect_meta <= 1'b1;
            ref_sync <= ref_detect_meta;
        end
    end
    
    // 目标时钟域中的双寄存器同步器，降低亚稳态风险
    always @(posedge target_clk or posedge rst) begin
        if (rst) begin
            target_detect_meta <= 1'b0;
            target_sync <= 1'b0;
        end else begin
            target_detect_meta <= ref_sync;
            target_sync <= target_detect_meta;
        end
    end
    
    // 相位状态控制逻辑优化
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            phase_state <= PHASE_0;
        end else begin
            // 使用条件赋值简化状态转换
            phase_state <= target_sync ? PHASE_0 : 
                          (phase_state == PHASE_0) ? PHASE_1 : PHASE_0;
        end
    end
    
    // 锁定状态控制优化
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            locked <= 1'b0;
        end else begin
            // 简化锁定条件判断
            locked <= target_sync | (phase_state == PHASE_0);
        end
    end
    
    // 时钟输出逻辑优化
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else if (phase_state == PHASE_0) begin
            clk_out <= ~clk_out;
        end
    end
    
endmodule