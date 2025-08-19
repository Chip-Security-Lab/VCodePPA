//SystemVerilog
module ErrorCounter #(parameter WIDTH=8, MAX_ERR=3) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] pattern_in,
    input valid_in,
    output ready_out,
    output reg alarm,
    output valid_out
);

    // Stage 1: 比较和错误检测
    reg [WIDTH-1:0] data_stage1, pattern_stage1;
    reg valid_stage1;
    reg mismatch_stage1;
    wire ready_stage2;
    
    // Stage 2: 错误计数
    reg [3:0] err_count_stage2;
    reg valid_stage2;
    wire ready_stage3;
    
    // Stage 3: 警报生成
    reg valid_stage3;
    
    // 流水线控制逻辑
    assign ready_out = ready_stage2;
    assign ready_stage2 = rst_n;
    assign ready_stage3 = 1'b1;
    assign valid_out = valid_stage3;
    
    // Stage 1: 数据比较
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            pattern_stage1 <= 0;
            mismatch_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (ready_stage2) begin
            data_stage1 <= data_in;
            pattern_stage1 <= pattern_in;
            mismatch_stage1 <= (data_in != pattern_in);
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: 错误计数
    reg [3:0] err_count;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            err_count <= 0;
            err_count_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (ready_stage3) begin
            if (valid_stage1) begin
                err_count <= mismatch_stage1 ? err_count + 1 : 0;
                err_count_stage2 <= mismatch_stage1 ? err_count + 1 : 0;
                valid_stage2 <= valid_stage1;
            end else begin
                valid_stage2 <= 0;
            end
        end
    end
    
    // Stage 3: 警报生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alarm <= 0;
            valid_stage3 <= 0;
        end else begin
            if (valid_stage2) begin
                alarm <= (err_count_stage2 >= MAX_ERR);
                valid_stage3 <= valid_stage2;
            end else begin
                valid_stage3 <= 0;
            end
        end
    end

endmodule