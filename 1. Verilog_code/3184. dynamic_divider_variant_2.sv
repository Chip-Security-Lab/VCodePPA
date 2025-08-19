//SystemVerilog
module dynamic_divider #(
    parameter CTR_WIDTH = 8
)(
    input                  clk,
    input [CTR_WIDTH-1:0]  div_value,
    input                  load,
    output reg             clk_div
);
    // 数据流阶段1: 配置寄存器
    reg [CTR_WIDTH-1:0]    div_config;      // 分频配置寄存
    reg [CTR_WIDTH-1:0]    div_config_next; // 分频配置下一状态
    
    // 数据流阶段2: 计数器逻辑
    reg [CTR_WIDTH-1:0]    counter;         // 主计数器
    reg [CTR_WIDTH-1:0]    counter_next;    // 计数器下一状态
    
    // 数据流阶段3: 时钟生成控制
    reg                    clk_div_next;    // 输出时钟下一状态
    reg                    reset_detect;    // 复位检测信号
    
    // 配置寄存器更新路径
    always @(*) begin
        div_config_next = div_config;
        if (load) 
            div_config_next = div_value;
    end
    
    // 计数器逻辑路径
    always @(*) begin
        reset_detect = (counter == div_config - 1'b1);
        
        if (reset_detect)
            counter_next = 'd0;
        else
            counter_next = counter + 1'b1;
    end
    
    // 时钟生成控制路径
    always @(*) begin
        clk_div_next = clk_div;
        
        if (reset_detect)
            clk_div_next = ~clk_div;
    end
    
    // 流水线寄存器更新 - 统一时序控制
    always @(posedge clk) begin
        // 阶段1: 更新配置
        div_config <= div_config_next;
        
        // 阶段2: 更新计数器
        counter <= counter_next;
        
        // 阶段3: 更新输出时钟
        clk_div <= clk_div_next;
    end
endmodule