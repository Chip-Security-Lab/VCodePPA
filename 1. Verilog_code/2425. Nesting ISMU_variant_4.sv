//SystemVerilog
// 顶层模块
module nesting_ismu(
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] intr_src,
    input  logic [7:0] intr_enable,
    input  logic [7:0] intr_priority,
    input  logic [2:0] current_level,
    output logic [2:0] intr_level,
    output logic       intr_active
);
    // 第一级流水线信号
    logic [7:0] active_src_stage1;
    logic [7:0] intr_priority_stage1;
    logic [2:0] current_level_stage1;
    logic       valid_stage1;
    
    // 第二级流水线信号
    logic [2:0] max_level_high_stage2;
    logic [3:0] active_src_low_stage2;
    logic [3:0] intr_priority_low_stage2;
    logic [2:0] current_level_stage2;
    logic       valid_stage2;
    
    // 第三级流水线信号
    logic [2:0] max_level_stage3;
    logic       valid_stage3;

    // 第一级流水线模块实例化
    intr_stage1 u_intr_stage1 (
        .clk               (clk),
        .rst               (rst),
        .intr_src          (intr_src),
        .intr_enable       (intr_enable),
        .intr_priority     (intr_priority),
        .current_level     (current_level),
        .active_src_out    (active_src_stage1),
        .intr_priority_out (intr_priority_stage1),
        .current_level_out (current_level_stage1),
        .valid_out         (valid_stage1)
    );

    // 第二级流水线模块实例化
    intr_stage2 u_intr_stage2 (
        .clk                    (clk),
        .rst                    (rst),
        .active_src_in          (active_src_stage1),
        .intr_priority_in       (intr_priority_stage1),
        .current_level_in       (current_level_stage1),
        .valid_in               (valid_stage1),
        .max_level_high_out     (max_level_high_stage2),
        .active_src_low_out     (active_src_low_stage2),
        .intr_priority_low_out  (intr_priority_low_stage2),
        .current_level_out      (current_level_stage2),
        .valid_out              (valid_stage2)
    );

    // 第三级流水线模块实例化
    intr_stage3 u_intr_stage3 (
        .clk                   (clk),
        .rst                   (rst),
        .max_level_high_in     (max_level_high_stage2),
        .active_src_low_in     (active_src_low_stage2),
        .intr_priority_low_in  (intr_priority_low_stage2),
        .current_level_in      (current_level_stage2),
        .valid_in              (valid_stage2),
        .max_level_out         (max_level_stage3),
        .valid_out             (valid_stage3)
    );

    // 输出处理模块实例化
    intr_output u_intr_output (
        .clk                  (clk),
        .rst                  (rst),
        .max_level_in         (max_level_stage3),
        .valid_in             (valid_stage3),
        .active_src_low       (active_src_low_stage2),
        .intr_priority_low    (intr_priority_low_stage2),
        .current_level        (current_level_stage2),
        .intr_level           (intr_level),
        .intr_active          (intr_active)
    );

endmodule

// 第一级流水线：计算活跃中断源
module intr_stage1 (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] intr_src,
    input  logic [7:0] intr_enable,
    input  logic [7:0] intr_priority,
    input  logic [2:0] current_level,
    output logic [7:0] active_src_out,
    output logic [7:0] intr_priority_out,
    output logic [2:0] current_level_out,
    output logic       valid_out
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            active_src_out    <= 8'd0;
            intr_priority_out <= 8'd0;
            current_level_out <= 3'd0;
            valid_out         <= 1'b0;
        end else begin
            active_src_out    <= intr_src & intr_enable;
            intr_priority_out <= intr_priority;
            current_level_out <= current_level;
            valid_out         <= 1'b1;
        end
    end
endmodule

// 第二级流水线：计算中断级别的前半部分(高4位)
module intr_stage2 (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] active_src_in,
    input  logic [7:0] intr_priority_in,
    input  logic [2:0] current_level_in,
    input  logic       valid_in,
    output logic [2:0] max_level_high_out,
    output logic [3:0] active_src_low_out,
    output logic [3:0] intr_priority_low_out,
    output logic [2:0] current_level_out,
    output logic       valid_out
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            max_level_high_out    <= 3'd0;
            active_src_low_out    <= 4'd0;
            intr_priority_low_out <= 4'd0;
            current_level_out     <= 3'd0;
            valid_out             <= 1'b0;
        end else if (valid_in) begin
            // 处理高4位中断源的优先级
            if (active_src_in[7] & intr_priority_in[7] > current_level_in)
                max_level_high_out <= 3'd7;
            else if (active_src_in[6] & intr_priority_in[6] > current_level_in)
                max_level_high_out <= 3'd6;
            else if (active_src_in[5] & intr_priority_in[5] > current_level_in)
                max_level_high_out <= 3'd5;
            else if (active_src_in[4] & intr_priority_in[4] > current_level_in)
                max_level_high_out <= 3'd4;
            else
                max_level_high_out <= 3'd0;
                
            // 传递低4位数据到下一级
            active_src_low_out    <= active_src_in[3:0];
            intr_priority_low_out <= intr_priority_in[3:0];
            current_level_out     <= current_level_in;
            valid_out             <= valid_in;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule

// 第三级流水线：计算中断级别的后半部分(低4位)
module intr_stage3 (
    input  logic       clk,
    input  logic       rst,
    input  logic [2:0] max_level_high_in,
    input  logic [3:0] active_src_low_in,
    input  logic [3:0] intr_priority_low_in,
    input  logic [2:0] current_level_in,
    input  logic       valid_in,
    output logic [2:0] max_level_out,
    output logic       valid_out
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            max_level_out <= 3'd0;
            valid_out     <= 1'b0;
        end else if (valid_in) begin
            // 如果高4位已经有结果，则使用它
            if (max_level_high_in != 3'd0) begin
                max_level_out <= max_level_high_in;
            end
            // 否则检查低4位
            else if (active_src_low_in[3] & intr_priority_low_in[3] > current_level_in)
                max_level_out <= 3'd3;
            else if (active_src_low_in[2] & intr_priority_low_in[2] > current_level_in)
                max_level_out <= 3'd2;
            else if (active_src_low_in[1] & intr_priority_low_in[1] > current_level_in)
                max_level_out <= 3'd1;
            else if (active_src_low_in[0] & intr_priority_low_in[0] > current_level_in)
                max_level_out <= 3'd0;
            else
                max_level_out <= 3'd0;
                
            valid_out <= valid_in;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule

// 输出处理模块
module intr_output (
    input  logic       clk,
    input  logic       rst,
    input  logic [2:0] max_level_in,
    input  logic       valid_in,
    input  logic [3:0] active_src_low,
    input  logic [3:0] intr_priority_low,
    input  logic [2:0] current_level,
    output logic [2:0] intr_level,
    output logic       intr_active
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_level  <= 3'd0;
            intr_active <= 1'b0;
        end else if (valid_in) begin
            intr_level  <= max_level_in;
            intr_active <= (max_level_in > 3'd0) | 
                          ((max_level_in == 3'd0) & (active_src_low[0] & intr_priority_low[0] > current_level));
        end
    end
endmodule