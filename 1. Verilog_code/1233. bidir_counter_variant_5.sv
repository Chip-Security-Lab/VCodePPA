//SystemVerilog
module bidir_counter #(parameter N = 4) (
    input wire clock, clear, load, up_down,
    input wire [N-1:0] data_in,
    input wire valid_in,
    output wire valid_out,
    output wire [N-1:0] count
);
    // 流水线寄存器
    reg [N-1:0] count_stage1, count_stage2;
    reg [N-1:0] next_count_stage1;
    reg valid_stage1, valid_stage2;
    reg clear_stage1, load_stage1, up_down_stage1;
    reg [N-1:0] data_in_stage1;
    
    // 第一级流水线 - 输入寄存
    always @(posedge clock) begin
        if (clear) begin
            clear_stage1 <= 1'b1;
            load_stage1 <= 1'b0;
            up_down_stage1 <= 1'b0;
            data_in_stage1 <= {N{1'b0}};
            valid_stage1 <= 1'b0;
            count_stage1 <= {N{1'b0}};
        end else begin
            clear_stage1 <= clear;
            load_stage1 <= load;
            up_down_stage1 <= up_down;
            data_in_stage1 <= data_in;
            valid_stage1 <= valid_in;
            count_stage1 <= count_stage2; // 反馈最终值
        end
    end
    
    // 第一级流水线 - 计算逻辑
    always @(*) begin
        case (1'b1)
            clear_stage1:   next_count_stage1 = {N{1'b0}};
            load_stage1:    next_count_stage1 = data_in_stage1;
            default:        next_count_stage1 = up_down_stage1 ? (count_stage1 + 1'b1) : (count_stage1 - 1'b1);
        endcase
    end
    
    // 第二级流水线 - 更新计数值
    always @(posedge clock) begin
        if (clear) begin
            count_stage2 <= {N{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            count_stage2 <= next_count_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出赋值
    assign count = count_stage2;
    assign valid_out = valid_stage2;
    
endmodule