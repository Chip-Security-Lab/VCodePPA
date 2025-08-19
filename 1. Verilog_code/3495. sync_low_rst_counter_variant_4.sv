//SystemVerilog
module sync_low_rst_counter #(parameter COUNT_WIDTH=8)(
    input wire clk,
    input wire rst_n,
    input wire load,
    input wire [COUNT_WIDTH-1:0] load_value,
    output reg [COUNT_WIDTH-1:0] counter
);

    // 捕获输入信号，将寄存器移到组合逻辑之后
    reg load_r;
    reg [COUNT_WIDTH-1:0] load_value_r;
    reg [COUNT_WIDTH-1:0] next_counter_value;
    
    // 流水线寄存器
    reg [COUNT_WIDTH-1:0] counter_stage1;
    reg [COUNT_WIDTH-1:0] counter_stage2;
    
    // 组合逻辑计算递减值
    wire [COUNT_WIDTH-1:0] ones_complement;
    wire [COUNT_WIDTH-1:0] twos_complement;
    wire [COUNT_WIDTH-1:0] increment_value;
    
    // 二进制补码计算
    assign ones_complement = ~{{COUNT_WIDTH-1{1'b0}}, 1'b1};  // 对1取反
    assign twos_complement = ones_complement + 1'b1;          // 加1得到补码(-1)
    assign increment_value = ~twos_complement + 1'b1;         // -(-1) = 1
    
    // 捕获输入信号，移动到组合逻辑之后
    always @(posedge clk) begin
        if (!rst_n) begin
            load_r <= 1'b0;
            load_value_r <= {COUNT_WIDTH{1'b0}};
        end else begin
            load_r <= load;
            load_value_r <= load_value;
        end
    end
    
    // 组合逻辑计算下一状态
    always @(*) begin
        if (load_r)
            next_counter_value = load_value_r;
        else
            next_counter_value = counter_stage2 + increment_value; // counter + 1
    end
    
    // 阶段1: 更新计数器第一级
    always @(posedge clk) begin
        if (!rst_n) begin
            counter_stage1 <= {COUNT_WIDTH{1'b0}};
        end else begin
            counter_stage1 <= next_counter_value;
        end
    end
    
    // 阶段2: 更新计数器第二级
    always @(posedge clk) begin
        if (!rst_n) begin
            counter_stage2 <= {COUNT_WIDTH{1'b0}};
        end else begin
            counter_stage2 <= counter_stage1;
        end
    end
    
    // 更新输出
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= {COUNT_WIDTH{1'b0}};
        end else begin
            counter <= counter_stage2;
        end
    end

endmodule