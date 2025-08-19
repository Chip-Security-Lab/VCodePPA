//SystemVerilog
// IEEE 1364-2005 Verilog
module flagged_shift_reg #(parameter DEPTH = 8) (
    input wire clk, rst, push, pop,
    input wire data_in,
    output wire data_out,
    output wire empty, full
);
    // 将FIFO分为多级流水线段
    localparam PIPELINE_STAGES = 4;
    localparam STAGE_SIZE = DEPTH / PIPELINE_STAGES;
    
    // 流水线寄存器
    reg [STAGE_SIZE-1:0] fifo_stage1, fifo_stage2, fifo_stage3, fifo_stage4;
    
    // 流水线控制信号
    reg [$clog2(DEPTH):0] count;
    reg [PIPELINE_STAGES-1:0] stage_valid;
    
    // 预先计算下一个时钟周期的控制信号
    reg push_enable_reg, pop_enable_reg;
    reg [PIPELINE_STAGES-1:0] next_stage_push, next_stage_pop;
    reg next_empty, next_full;
    reg [$clog2(DEPTH):0] next_count;
    
    // 移动至组合逻辑前的数据输出寄存器
    reg data_out_reg;
    
    // 组合逻辑部分
    wire push_enable, pop_enable;
    wire [PIPELINE_STAGES-1:0] stage_push, stage_pop;
    
    // 使能信号
    assign push_enable = push && !full;
    assign pop_enable = pop && !empty;
    
    // 流水线段控制逻辑
    assign stage_push[0] = push_enable;
    assign stage_push[1] = stage_valid[0] && push_enable;
    assign stage_push[2] = stage_valid[1] && push_enable;
    assign stage_push[3] = stage_valid[2] && push_enable;
    
    assign stage_pop[3] = pop_enable;
    assign stage_pop[2] = stage_pop[3] && (count > STAGE_SIZE*3);
    assign stage_pop[1] = stage_pop[2] && (count > STAGE_SIZE*2);
    assign stage_pop[0] = stage_pop[1] && (count > STAGE_SIZE*1);
    
    // 预计算下一周期的控制信号
    always @(posedge clk) begin
        if (rst) begin
            push_enable_reg <= 0;
            pop_enable_reg <= 0;
            next_stage_push <= 0;
            next_stage_pop <= 0;
            next_empty <= 1;
            next_full <= 0;
            next_count <= 0;
        end else begin
            // 预计算下一周期的值
            push_enable_reg <= push && !(count == DEPTH);
            pop_enable_reg <= pop && !(count == 0);
            
            next_count <= count;
            if (push_enable && !pop_enable)
                next_count <= count + 1;
            else if (!push_enable && pop_enable)
                next_count <= count - 1;
                
            next_empty <= (next_count == 0);
            next_full <= (next_count == DEPTH);
            
            // 预计算下一周期的流水线控制信号
            next_stage_push[0] <= push && !(count == DEPTH);
            next_stage_push[1] <= stage_valid[0] && push && !(count == DEPTH);
            next_stage_push[2] <= stage_valid[1] && push && !(count == DEPTH);
            next_stage_push[3] <= stage_valid[2] && push && !(count == DEPTH);
            
            next_stage_pop[3] <= pop && !(count == 0);
            next_stage_pop[2] <= (pop && !(count == 0)) && (count > STAGE_SIZE*3);
            next_stage_pop[1] <= (pop && !(count == 0)) && (count > STAGE_SIZE*3) && (count > STAGE_SIZE*2);
            next_stage_pop[0] <= (pop && !(count == 0)) && (count > STAGE_SIZE*3) && (count > STAGE_SIZE*2) && (count > STAGE_SIZE*1);
        end
    end
    
    // 使用预计算的控制信号的流水线有效性跟踪
    always @(posedge clk) begin
        if (rst) begin
            stage_valid <= 0;
        end else begin
            if (push_enable_reg && next_count < STAGE_SIZE) 
                stage_valid[0] <= 1;
            if (push_enable_reg && next_count >= STAGE_SIZE && next_count < STAGE_SIZE*2) 
                stage_valid[1] <= 1;
            if (push_enable_reg && next_count >= STAGE_SIZE*2 && next_count < STAGE_SIZE*3) 
                stage_valid[2] <= 1;
            if (push_enable_reg && next_count >= STAGE_SIZE*3) 
                stage_valid[3] <= 1;
                
            if (pop_enable_reg && next_count <= STAGE_SIZE) 
                stage_valid[0] <= 0;
            if (pop_enable_reg && next_count <= STAGE_SIZE*2 && next_count > STAGE_SIZE) 
                stage_valid[1] <= 0;
            if (pop_enable_reg && next_count <= STAGE_SIZE*3 && next_count > STAGE_SIZE*2) 
                stage_valid[2] <= 0;
            if (pop_enable_reg && next_count > STAGE_SIZE*3) 
                stage_valid[3] <= 0;
        end
    end
    
    // 计数器逻辑
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
        end else begin
            count <= next_count;
        end
    end
    
    // 第一级流水线
    always @(posedge clk) begin
        if (rst) begin
            fifo_stage1 <= 0;
        end else if (next_stage_push[0]) begin
            fifo_stage1 <= {fifo_stage1[STAGE_SIZE-2:0], data_in};
        end else if (next_stage_pop[0]) begin
            fifo_stage1 <= {1'b0, fifo_stage1[STAGE_SIZE-1:1]};
        end
    end
    
    // 第二级流水线
    always @(posedge clk) begin
        if (rst) begin
            fifo_stage2 <= 0;
        end else if (next_stage_push[1]) begin
            fifo_stage2 <= {fifo_stage2[STAGE_SIZE-2:0], fifo_stage1[STAGE_SIZE-1]};
        end else if (next_stage_pop[1]) begin
            fifo_stage2 <= {1'b0, fifo_stage2[STAGE_SIZE-1:1]};
        end
    end
    
    // 第三级流水线
    always @(posedge clk) begin
        if (rst) begin
            fifo_stage3 <= 0;
        end else if (next_stage_push[2]) begin
            fifo_stage3 <= {fifo_stage3[STAGE_SIZE-2:0], fifo_stage2[STAGE_SIZE-1]};
        end else if (next_stage_pop[2]) begin
            fifo_stage3 <= {1'b0, fifo_stage3[STAGE_SIZE-1:1]};
        end
    end
    
    // 第四级流水线与输出数据寄存器
    always @(posedge clk) begin
        if (rst) begin
            fifo_stage4 <= 0;
            data_out_reg <= 0;
        end else begin
            // 更新输出数据寄存器
            data_out_reg <= fifo_stage4[STAGE_SIZE-1];
            
            if (next_stage_push[3]) begin
                fifo_stage4 <= {fifo_stage4[STAGE_SIZE-2:0], fifo_stage3[STAGE_SIZE-1]};
            end else if (next_stage_pop[3]) begin
                fifo_stage4 <= {1'b0, fifo_stage4[STAGE_SIZE-1:1]};
            end
        end
    end
    
    // 输出逻辑 - 使用预先寄存的值
    assign data_out = data_out_reg;
    assign empty = next_empty;
    assign full = next_full;
endmodule