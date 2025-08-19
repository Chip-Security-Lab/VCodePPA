//SystemVerilog
module dual_edge_divider (
    input wire clkin, rst,
    output reg clkout
);
    // 定义多级流水线计数器和状态寄存器
    reg [1:0] pos_count_stage1, pos_count_stage2;
    reg [1:0] neg_count_stage1, neg_count_stage2;
    reg pos_toggle_stage1, pos_toggle_stage2, pos_toggle_stage3;
    reg neg_toggle_stage1, neg_toggle_stage2, neg_toggle_stage3;
    
    // 流水线控制信号
    reg pos_valid_stage1, pos_valid_stage2;
    reg neg_valid_stage1, neg_valid_stage2;
    
    // 临时信号用于显式多路复用
    reg [1:0] pos_count_next;
    reg pos_toggle_next;
    reg [1:0] neg_count_next;
    reg neg_toggle_next;
    
    // 显式多路复用器 - 正边沿计数逻辑
    always @(*) begin
        case (pos_count_stage1)
            2'b11: pos_count_next = 2'b00;
            default: pos_count_next = pos_count_stage1 + 1'b1;
        endcase
    end
    
    // 显式多路复用器 - 正边沿翻转逻辑
    always @(*) begin
        case (pos_count_stage1)
            2'b11: pos_toggle_next = ~pos_toggle_stage1;
            default: pos_toggle_next = pos_toggle_stage1;
        endcase
    end
    
    // 显式多路复用器 - 负边沿计数逻辑
    always @(*) begin
        case (neg_count_stage1)
            2'b11: neg_count_next = 2'b00;
            default: neg_count_next = neg_count_stage1 + 1'b1;
        endcase
    end
    
    // 显式多路复用器 - 负边沿翻转逻辑
    always @(*) begin
        case (neg_count_stage1)
            2'b11: neg_toggle_next = ~neg_toggle_stage1;
            default: neg_toggle_next = neg_toggle_stage1;
        endcase
    end
    
    // 流水线级别1：计数和比较 - 正边沿
    always @(posedge clkin or posedge rst) begin
        if (rst) begin
            pos_count_stage1 <= 2'b00;
            pos_valid_stage1 <= 1'b0;
        end else begin
            pos_count_stage1 <= pos_count_next;
            pos_valid_stage1 <= 1'b1;
        end
    end
    
    // 流水线级别2：正边沿触发器逻辑
    always @(posedge clkin or posedge rst) begin
        if (rst) begin
            pos_count_stage2 <= 2'b00;
            pos_toggle_stage1 <= 1'b0;
            pos_valid_stage2 <= 1'b0;
        end else if (pos_valid_stage1) begin
            pos_count_stage2 <= pos_count_stage1;
            pos_toggle_stage1 <= pos_toggle_next;
            pos_valid_stage2 <= pos_valid_stage1;
        end
    end
    
    // 流水线级别3：正边沿触发器结果缓存
    always @(posedge clkin or posedge rst) begin
        if (rst) begin
            pos_toggle_stage2 <= 1'b0;
            pos_toggle_stage3 <= 1'b0;
        end else if (pos_valid_stage2) begin
            pos_toggle_stage2 <= pos_toggle_stage1;
            pos_toggle_stage3 <= pos_toggle_stage2;
        end
    end
    
    // 负边沿流水线级别1：计数和比较
    always @(negedge clkin or posedge rst) begin
        if (rst) begin
            neg_count_stage1 <= 2'b00;
            neg_valid_stage1 <= 1'b0;
        end else begin
            neg_count_stage1 <= neg_count_next;
            neg_valid_stage1 <= 1'b1;
        end
    end
    
    // 负边沿流水线级别2：切换逻辑
    always @(negedge clkin or posedge rst) begin
        if (rst) begin
            neg_count_stage2 <= 2'b00;
            neg_toggle_stage1 <= 1'b0;
            neg_valid_stage2 <= 1'b0;
        end else if (neg_valid_stage1) begin
            neg_count_stage2 <= neg_count_stage1;
            neg_toggle_stage1 <= neg_toggle_next;
            neg_valid_stage2 <= neg_valid_stage1;
        end
    end
    
    // 负边沿流水线级别3：结果缓存
    always @(negedge clkin or posedge rst) begin
        if (rst) begin
            neg_toggle_stage2 <= 1'b0;
            neg_toggle_stage3 <= 1'b0;
        end else if (neg_valid_stage2) begin
            neg_toggle_stage2 <= neg_toggle_stage1;
            neg_toggle_stage3 <= neg_toggle_stage2;
        end
    end
    
    // 输出逻辑：使用更高效的双沿触发
    reg prev_pos_toggle_stage3, prev_neg_toggle_stage3;
    
    always @(posedge clkin or posedge rst) begin
        if (rst)
            prev_pos_toggle_stage3 <= 1'b0;
        else
            prev_pos_toggle_stage3 <= pos_toggle_stage3;
    end
    
    always @(negedge clkin or posedge rst) begin
        if (rst)
            prev_neg_toggle_stage3 <= 1'b0;
        else
            prev_neg_toggle_stage3 <= neg_toggle_stage3;
    end
    
    // 改进的输出逻辑：减少敏感信号列表，提高性能
    always @(pos_toggle_stage3 or neg_toggle_stage3 or rst) begin
        if (rst)
            clkout = 1'b0;
        else
            clkout = pos_toggle_stage3 ^ neg_toggle_stage3;
    end
endmodule