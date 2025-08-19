//SystemVerilog
module eth_frame_sync #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 32
)(
    input clk,
    input rst,
    input [IN_WIDTH-1:0] data_in,
    input in_valid,
    output reg [OUT_WIDTH-1:0] data_out,
    output reg out_valid,
    output reg sof,
    output reg eof
);
    localparam RATIO = OUT_WIDTH / IN_WIDTH;
    localparam SOF_PATTERN = 8'hD5;
    localparam EOF_PATTERN = 8'hFD;
    
    // 流水线寄存器 - 第一级：输入捕获和SOF检测
    reg [IN_WIDTH-1:0] data_in_stage1;
    reg in_valid_stage1;
    reg is_sof_pattern_stage1;
    
    // 流水线寄存器 - 第二级：移位和计数
    reg [IN_WIDTH*RATIO-1:0] shift_reg_stage2;
    reg [$clog2(RATIO):0] count_stage2;
    reg prev_sof_stage2;
    reg detect_sof_stage2;
    reg in_valid_stage2;
    
    // 流水线寄存器 - 第三级：数据处理
    reg [IN_WIDTH*RATIO-1:0] shift_reg_stage3;
    reg count_at_max_stage3;
    reg is_eof_pattern_stage3;
    reg detect_sof_stage3;
    reg in_valid_stage3;
    
    // 流水线寄存器 - 第四级：输出生成
    reg [OUT_WIDTH-1:0] data_out_stage4;
    reg out_valid_stage4;
    reg sof_stage4;
    reg eof_stage4;
    
    // 第一级流水线：输入捕获和SOF检测
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage1 <= {IN_WIDTH{1'b0}};
            in_valid_stage1 <= 1'b0;
            is_sof_pattern_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            in_valid_stage1 <= in_valid;
            is_sof_pattern_stage1 <= (data_in == SOF_PATTERN);
        end
    end
    
    // 第二级流水线：移位和计数
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage2 <= {(IN_WIDTH*RATIO){1'b0}};
            count_stage2 <= 0;
            prev_sof_stage2 <= 1'b0;
            detect_sof_stage2 <= 1'b0;
            in_valid_stage2 <= 1'b0;
        end else begin
            in_valid_stage2 <= in_valid_stage1;
            
            if (in_valid_stage1) begin
                shift_reg_stage2 <= {shift_reg_stage2[IN_WIDTH*(RATIO-1)-1:0], data_in_stage1};
                
                detect_sof_stage2 <= is_sof_pattern_stage1 && !prev_sof_stage2;
                
                if (is_sof_pattern_stage1 && !prev_sof_stage2) begin
                    prev_sof_stage2 <= 1'b1;
                    count_stage2 <= 0;
                end else begin
                    prev_sof_stage2 <= prev_sof_stage2;
                    count_stage2 <= (count_stage2 == RATIO-1) ? 0 : count_stage2 + 1'b1;
                end
            end
        end
    end
    
    // 第三级流水线：数据处理
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage3 <= {(IN_WIDTH*RATIO){1'b0}};
            count_at_max_stage3 <= 1'b0;
            is_eof_pattern_stage3 <= 1'b0;
            detect_sof_stage3 <= 1'b0;
            in_valid_stage3 <= 1'b0;
        end else begin
            shift_reg_stage3 <= shift_reg_stage2;
            count_at_max_stage3 <= (count_stage2 == RATIO-1);
            is_eof_pattern_stage3 <= (shift_reg_stage2[IN_WIDTH*(RATIO-1)-1:IN_WIDTH*(RATIO-2)] == EOF_PATTERN);
            detect_sof_stage3 <= detect_sof_stage2;
            in_valid_stage3 <= in_valid_stage2;
        end
    end
    
    // 第四级流水线：输出生成
    always @(posedge clk) begin
        if (rst) begin
            data_out_stage4 <= {OUT_WIDTH{1'b0}};
            out_valid_stage4 <= 1'b0;
            sof_stage4 <= 1'b0;
            eof_stage4 <= 1'b0;
        end else begin
            sof_stage4 <= detect_sof_stage3;
            
            if (in_valid_stage3) begin
                if (count_at_max_stage3) begin
                    data_out_stage4 <= shift_reg_stage3;
                    out_valid_stage4 <= 1'b1;
                    eof_stage4 <= is_eof_pattern_stage3;
                end else begin
                    out_valid_stage4 <= 1'b0;
                    eof_stage4 <= 1'b0;
                end
            end else begin
                out_valid_stage4 <= 1'b0;
                sof_stage4 <= 1'b0;
                eof_stage4 <= 1'b0;
            end
        end
    end
    
    // 最终输出赋值
    always @(posedge clk) begin
        if (rst) begin
            data_out <= {OUT_WIDTH{1'b0}};
            out_valid <= 1'b0;
            sof <= 1'b0;
            eof <= 1'b0;
        end else begin
            data_out <= data_out_stage4;
            out_valid <= out_valid_stage4;
            sof <= sof_stage4;
            eof <= eof_stage4;
        end
    end
endmodule