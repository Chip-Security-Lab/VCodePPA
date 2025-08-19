//SystemVerilog
module SARDiv_pipeline(
    input clk, start,
    input [7:0] D, d,
    output reg [7:0] q,
    output reg done
);
    reg [7:0] rem_stage1, rem_stage2;
    reg [3:0] bit_cnt_stage1, bit_cnt_stage2;
    reg valid_stage1, valid_stage2;
    wire [7:0] shifted_rem_stage1 = rem_stage1 << 1; // 预计算移位结果

    // Stage 1: Initialization
    always @(posedge clk) begin
        if (start) begin
            rem_stage1 <= D;
            bit_cnt_stage1 <= 7;
            q <= 0;
            done <= 0;
            valid_stage1 <= 1;
        end else if (valid_stage1) begin
            rem_stage1 <= rem_stage1; //保持不变
            bit_cnt_stage1 <= bit_cnt_stage1; //保持不变
            valid_stage1 <= 1;
        end
    end

    // Stage 2: Processing
    always @(posedge clk) begin
        if (valid_stage1) begin
            rem_stage2 <= shifted_rem_stage1;
            bit_cnt_stage2 <= bit_cnt_stage1;

            if (bit_cnt_stage1 <= 7) begin
                // 处理移位和减法
                if (shifted_rem_stage1 >= d && d != 0) begin
                    rem_stage2 <= shifted_rem_stage1 - d;
                    q[bit_cnt_stage2] <= 1'b1;
                end else begin
                    rem_stage2 <= shifted_rem_stage1;
                end

                // 更新位计数器和完成标志
                if (bit_cnt_stage2 == 0) begin
                    done <= 1;
                    valid_stage2 <= 0; // 处理完成
                end else begin
                    bit_cnt_stage2 <= bit_cnt_stage2 - 1;
                end
            end
        end
    end

    // Control Logic for Valid Signals
    always @(posedge clk) begin
        if (start) begin
            valid_stage2 <= 0; // Reset valid signal
        end else begin
            valid_stage2 <= valid_stage1; // Propagate valid signal
        end
    end
endmodule