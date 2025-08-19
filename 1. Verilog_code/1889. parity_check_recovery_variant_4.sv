//SystemVerilog
module parity_check_recovery (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] data_in,
    input  wire       parity_in,
    output reg  [7:0] data_out,
    output reg        valid,
    output reg        error
);
    // 数据流阶段1: 奇偶校验计算
    reg [7:0] data_stage1;
    reg       parity_in_stage1;
    reg       calculated_parity_stage1;
    
    // 数据流阶段2: 校验和输出
    reg       parity_match_stage2;
    reg [7:0] data_stage2;
    
    // 阶段1: 计算奇偶校验并寄存输入数据
    always @(posedge clk) begin
        if (reset) begin
            data_stage1 <= 8'h00;
            parity_in_stage1 <= 1'b0;
            calculated_parity_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            parity_in_stage1 <= parity_in;
            calculated_parity_stage1 <= ^data_in; // 使用归约异或计算奇偶校验
        end
    end
    
    // 阶段2: 比较奇偶校验并准备输出
    always @(posedge clk) begin
        if (reset) begin
            parity_match_stage2 <= 1'b0;
            data_stage2 <= 8'h00;
        end else begin
            parity_match_stage2 <= (parity_in_stage1 == calculated_parity_stage1);
            data_stage2 <= data_stage1;
        end
    end
    
    // 阶段3: 生成最终输出
    always @(posedge clk) begin
        if (reset) begin
            data_out <= 8'h00;
            valid <= 1'b0;
            error <= 1'b0;
        end else begin
            valid <= 1'b1; // 在非复位条件下设置valid
            error <= ~parity_match_stage2;
            
            // 仅在校验匹配时更新数据输出
            if (parity_match_stage2) begin
                data_out <= data_stage2;
            end
            // 不匹配时保持上一个有效值
        end
    end
    
endmodule