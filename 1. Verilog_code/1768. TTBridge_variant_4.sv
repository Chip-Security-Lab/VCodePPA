//SystemVerilog
module TTBridge #(
    parameter SCHEDULE = 32'h0000_FFFF
)(
    input clk, rst_n,
    input [31:0] timestamp,
    output reg trigger
);
    // 流水线寄存器
    reg [31:0] last_ts;
    reg [31:0] timestamp_stage1;
    reg [31:0] diff_stage2;
    reg schedule_match_stage1;
    reg time_valid_stage2;
    reg valid_stage1, valid_stage2;

    // 第一级流水线：捕获输入并检查schedule匹配
    always @(posedge clk) begin
        if (!rst_n) begin
            timestamp_stage1 <= 0;
            schedule_match_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            timestamp_stage1 <= timestamp;
            schedule_match_stage1 <= (timestamp & SCHEDULE) != 0;
            valid_stage1 <= 1'b1;
        end
    end

    // 第二级流水线：计算时间差并确定是否触发
    always @(posedge clk) begin
        if (!rst_n) begin
            diff_stage2 <= 0;
            time_valid_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (valid_stage1) begin
            diff_stage2 <= timestamp_stage1 - last_ts;
            time_valid_stage2 <= schedule_match_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // 第三级流水线：生成触发信号并更新last_ts
    always @(posedge clk) begin
        if (!rst_n) begin
            trigger <= 0;
            last_ts <= 0;
        end else if (valid_stage2) begin
            if (time_valid_stage2 && (diff_stage2 >= 100)) begin
                trigger <= 1'b1;
                last_ts <= timestamp_stage1;
            end else begin
                trigger <= 1'b0;
            end
        end else begin
            trigger <= 1'b0;
        end
    end
endmodule