//SystemVerilog
module lin_codec (
    input clk, break_detect,
    input [7:0] pid,
    output reg tx
);
    // 增加流水线级数
    reg break_detect_stage1, break_detect_stage2, break_detect_stage3;
    reg [7:0] pid_stage1, pid_stage2, pid_stage3;
    reg [12:0] shift_reg_stage1, shift_reg_stage2, shift_reg_stage3;
    reg tx_stage1, tx_stage2;
    
    // 第一级流水线 - 输入捕获
    always @(posedge clk) begin
        break_detect_stage1 <= break_detect;
        pid_stage1 <= pid;
    end
    
    // 第二级流水线 - 中间处理
    always @(posedge clk) begin
        break_detect_stage2 <= break_detect_stage1;
        pid_stage2 <= pid_stage1;
        
        if(break_detect_stage1) begin
            shift_reg_stage1 <= {pid_stage1, 4'h0, 1'b1};
            tx_stage1 <= 0; // Send break
        end
        else begin
            tx_stage1 <= shift_reg_stage2[12];
            shift_reg_stage1 <= {shift_reg_stage2[11:0], 1'b1};
        end
    end
    
    // 第三级流水线 - 继续处理
    always @(posedge clk) begin
        break_detect_stage3 <= break_detect_stage2;
        pid_stage3 <= pid_stage2;
        shift_reg_stage2 <= shift_reg_stage1;
        tx_stage2 <= tx_stage1;
    end
    
    // 第四级流水线 - 输出生成
    always @(posedge clk) begin
        shift_reg_stage3 <= shift_reg_stage2;
        tx <= tx_stage2;
    end
endmodule