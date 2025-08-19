//SystemVerilog
// IEEE 1364-2005 Verilog标准
// 顶层模块：整合优先级计算和温度计生成子模块
module thermometer_priority_comp #(
    parameter WIDTH = 8
)(
    input wire clk, 
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] thermometer_out,
    output wire [$clog2(WIDTH)-1:0] priority_pos
);
    // 内部连线
    wire [$clog2(WIDTH)-1:0] priority_position_comb;
    reg [$clog2(WIDTH)-1:0] priority_position_reg;
    wire [WIDTH-1:0] thermometer_comb;
    
    // 实例化优先级计算子模块(仅包含组合逻辑)
    priority_encoder_comb #(
        .WIDTH(WIDTH)
    ) priority_encoder_inst (
        .data_in(data_in),
        .priority_pos(priority_position_comb)
    );
    
    // 寄存优先级位置
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_position_reg <= {$clog2(WIDTH){1'b0}};
        end else begin
            priority_position_reg <= priority_position_comb;
        end
    end
    
    // 实例化温度计生成子模块(仅包含组合逻辑)
    thermometer_generator_comb #(
        .WIDTH(WIDTH)
    ) thermometer_generator_inst (
        .priority_pos(priority_position_reg),
        .thermometer_out(thermometer_comb)
    );
    
    // 温度计输出寄存器
    reg [WIDTH-1:0] thermometer_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            thermometer_reg <= {WIDTH{1'b0}};
        end else begin
            thermometer_reg <= thermometer_comb;
        end
    end
    
    // 将输出连接到寄存器
    assign thermometer_out = thermometer_reg;
    assign priority_pos = priority_position_reg;
    
endmodule

// 子模块：优先级编码器组合逻辑部分
module priority_encoder_comb #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_pos
);
    integer i;
    
    always @(*) begin
        priority_pos = {$clog2(WIDTH){1'b0}}; // 默认值为0
        
        // 从高位到低位找到第一个'1'
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (data_in[i]) 
                priority_pos = i[$clog2(WIDTH)-1:0];
        end
    end
endmodule

// 子模块：温度计编码生成器组合逻辑部分
module thermometer_generator_comb #(
    parameter WIDTH = 8
)(
    input wire [$clog2(WIDTH)-1:0] priority_pos,
    output reg [WIDTH-1:0] thermometer_out
);
    integer j;
    
    always @(*) begin
        thermometer_out = {WIDTH{1'b0}}; // 初始全为0
        
        // 生成温度计编码：从0到priority_pos的位置全部置1
        for (j = 0; j < WIDTH; j = j + 1) begin
            if (j <= priority_pos)
                thermometer_out[j] = 1'b1;
            else
                thermometer_out[j] = 1'b0;
        end
    end
endmodule