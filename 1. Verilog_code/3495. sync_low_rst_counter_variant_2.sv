//SystemVerilog
module sync_low_rst_counter #(parameter COUNT_WIDTH=8)(
    input wire clk,
    input wire rst_n,
    input wire load,
    input wire [COUNT_WIDTH-1:0] load_value,
    input wire enable,
    output reg [COUNT_WIDTH-1:0] counter,
    output reg valid
);

    // 将输入信号直接寄存，减少输入到第一级寄存器的延迟
    reg load_r, enable_r;
    reg [COUNT_WIDTH-1:0] load_value_r;
    
    // 流水线阶段寄存器
    reg load_stage2;
    reg [COUNT_WIDTH-1:0] counter_stage1, counter_stage2;
    reg valid_stage1, valid_stage2;
    
    // 输入寄存阶段 - 前向重定时优化：将寄存器移到输入端
    always @(posedge clk) begin
        if (!rst_n) begin
            load_r <= 1'b0;
            load_value_r <= {COUNT_WIDTH{1'b0}};
            enable_r <= 1'b0;
        end
        else begin
            load_r <= load;
            load_value_r <= load_value;
            enable_r <= enable;
        end
    end
    
    // 阶段1: 执行计算逻辑 - 组合逻辑后的寄存器
    always @(posedge clk) begin
        if (!rst_n) begin
            counter_stage1 <= {COUNT_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            load_stage2 <= 1'b0;
        end
        else if (enable_r) begin
            // 计算逻辑移到前级寄存器之后
            if (load_r)
                counter_stage1 <= load_value_r;
            else
                counter_stage1 <= counter + 1'b1;
                
            valid_stage1 <= 1'b1;
            load_stage2 <= load_r;
        end
        else begin
            valid_stage1 <= 1'b0;
            load_stage2 <= 1'b0;
        end
    end
    
    // 阶段2: 进一步处理 - 中间流水线级
    always @(posedge clk) begin
        if (!rst_n) begin
            counter_stage2 <= {COUNT_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else if (enable_r) begin
            counter_stage2 <= counter_stage1;
            valid_stage2 <= valid_stage1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 输出阶段: 更新最终输出
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= {COUNT_WIDTH{1'b0}};
            valid <= 1'b0;
        end
        else if (enable_r) begin
            counter <= counter_stage2;
            valid <= valid_stage2;
        end
        else begin
            valid <= 1'b0;
        end
    end

endmodule