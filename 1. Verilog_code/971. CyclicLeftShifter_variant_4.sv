//SystemVerilog
module CyclicLeftShifter #(parameter WIDTH=8, parameter STAGES=4) (
    input clk, rst_n, en,
    input serial_in,
    output reg [WIDTH-1:0] parallel_out
);
    // 定义流水线寄存器
    reg [WIDTH-1:0] pipe_stage1, pipe_stage2, pipe_stage3;
    reg valid_stage1, valid_stage2, valid_stage3;
    reg serial_stage1, serial_stage2, serial_stage3;
    
    // 每级流水线的工作量（移位数量）
    localparam SHIFT_PER_STAGE = WIDTH / STAGES;
    
    // 减法器信号 - 使用条件求和减法算法
    reg [WIDTH-1:0] minuend, subtrahend;
    wire [WIDTH-1:0] difference;
    
    // 条件求和减法器实例化
    ConditionalSumSubtractor #(.WIDTH(WIDTH)) css_inst (
        .minuend(minuend),
        .subtrahend(subtrahend),
        .difference(difference)
    );
    
    // 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_stage1 <= 0;
            valid_stage1 <= 0;
            serial_stage1 <= 0;
            minuend <= 0;
            subtrahend <= 0;
        end
        else if (en) begin
            // 第一级执行部分移位操作
            pipe_stage1 <= {parallel_out[WIDTH-2:WIDTH-SHIFT_PER_STAGE], 
                           parallel_out[WIDTH-SHIFT_PER_STAGE-1:0], 
                           serial_in};
            valid_stage1 <= 1;
            serial_stage1 <= serial_in;
            
            // 设置减法器输入
            minuend <= parallel_out;
            subtrahend <= {parallel_out[WIDTH-2:0], serial_in};
        end
        else begin
            valid_stage1 <= 0;
        end
    end
    
    // 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_stage2 <= 0;
            valid_stage2 <= 0;
            serial_stage2 <= 0;
        end
        else if (valid_stage1) begin
            // 使用减法器结果代替直接移位
            pipe_stage2 <= difference;
            valid_stage2 <= 1;
            serial_stage2 <= serial_stage1;
        end
        else begin
            valid_stage2 <= 0;
        end
    end
    
    // 第三级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_stage3 <= 0;
            valid_stage3 <= 0;
            serial_stage3 <= 0;
        end
        else if (valid_stage2) begin
            // 第三级执行部分移位操作
            pipe_stage3 <= {pipe_stage2[WIDTH-2:WIDTH-SHIFT_PER_STAGE], 
                           pipe_stage2[WIDTH-SHIFT_PER_STAGE-1:0], 
                           serial_stage2};
            valid_stage3 <= 1;
            serial_stage3 <= serial_stage2;
        end
        else begin
            valid_stage3 <= 0;
        end
    end
    
    // 最终输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_out <= 0;
        end
        else if (valid_stage3) begin
            // 第四级完成最后的移位操作
            parallel_out <= {pipe_stage3[WIDTH-2:WIDTH-SHIFT_PER_STAGE], 
                            pipe_stage3[WIDTH-SHIFT_PER_STAGE-1:0], 
                            serial_stage3};
        end
    end
endmodule

// 条件求和减法器模块 - 8位宽
module ConditionalSumSubtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference
);
    // 条件求和减法算法实现
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] diff_with_carry0, diff_with_carry1;
    wire [WIDTH/2-1:0] carries_0, carries_1;
    
    // 初始借位
    assign carry[0] = 1'b1; // 使用补码表示，初始借位为1
    
    // 第一层: 生成两组可能的差值 (假设进位为0和1的情况)
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin: gen_diffs
            assign diff_with_carry0[i] = minuend[i] ^ ~subtrahend[i] ^ 1'b0;
            assign diff_with_carry1[i] = minuend[i] ^ ~subtrahend[i] ^ 1'b1;
        end
    endgenerate
    
    // 第二层: 2位一组计算可能的进位
    generate
        for (genvar i = 0; i < WIDTH/2; i = i + 1) begin: gen_carries
            // 当进位输入为0时的组进位
            assign carries_0[i] = 
                ((minuend[i*2] & ~subtrahend[i*2]) | 
                 (minuend[i*2] & 1'b0) | 
                 (~subtrahend[i*2] & 1'b0)) &
                ((minuend[i*2+1] & ~subtrahend[i*2+1]) | 
                 (minuend[i*2+1] & carries_0[i]) | 
                 (~subtrahend[i*2+1] & carries_0[i]));
            
            // 当进位输入为1时的组进位
            assign carries_1[i] = 
                ((minuend[i*2] & ~subtrahend[i*2]) | 
                 (minuend[i*2] & 1'b1) | 
                 (~subtrahend[i*2] & 1'b1)) &
                ((minuend[i*2+1] & ~subtrahend[i*2+1]) | 
                 (minuend[i*2+1] & carries_1[i]) | 
                 (~subtrahend[i*2+1] & carries_1[i]));
        end
    endgenerate
    
    // 第三层: 根据前一组的进位选择正确的差值
    assign carry[1] = carry[0] ? carries_1[0] : carries_0[0];
    
    generate
        for (genvar i = 1; i < WIDTH/2; i = i + 1) begin: gen_select_carries
            assign carry[i+1] = carry[i] ? carries_1[i] : carries_0[i];
        end
    endgenerate
    
    // 最后: 根据进位选择正确的差值位
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin: gen_final_diff
            assign difference[i] = (i == 0) ? 
                                  (carry[0] ? diff_with_carry1[i] : diff_with_carry0[i]) :
                                  (carry[i/2] ? diff_with_carry1[i] : diff_with_carry0[i]);
        end
    endgenerate
    
endmodule