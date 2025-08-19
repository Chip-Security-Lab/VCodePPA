//SystemVerilog
// 顶层模块
module DynamicWidthShifter #(
    parameter MAX_WIDTH = 16
)(
    input  wire clk,
    input  wire [4:0] current_width,
    input  wire serial_in,
    output wire serial_out
);
    // 内部信号
    wire [MAX_WIDTH-1:0] buffer;
    wire [4:0] width_reg;
    wire intermediate_out;
    
    // 实例化输入处理子模块
    InputStage #(
        .MAX_WIDTH(MAX_WIDTH)
    ) input_stage_inst (
        .clk(clk),
        .serial_in(serial_in),
        .buffer_out(buffer)
    );
    
    // 实例化宽度控制子模块
    WidthControl width_control_inst (
        .clk(clk),
        .current_width(current_width),
        .width_reg_out(width_reg)
    );
    
    // 实例化选择器子模块
    Selector #(
        .MAX_WIDTH(MAX_WIDTH)
    ) selector_inst (
        .buffer_in(buffer),
        .width_reg(width_reg),
        .selected_bit(intermediate_out)
    );
    
    // 实例化输出处理子模块
    OutputStage output_stage_inst (
        .clk(clk),
        .intermediate_in(intermediate_out),
        .serial_out(serial_out)
    );
    
endmodule

// 输入处理子模块
module InputStage #(
    parameter MAX_WIDTH = 16
)(
    input  wire clk,
    input  wire serial_in,
    output wire [MAX_WIDTH-1:0] buffer_out
);
    reg [MAX_WIDTH-1:0] buffer;
    
    always @(posedge clk) begin
        buffer <= {buffer[MAX_WIDTH-2:0], serial_in};
    end
    
    assign buffer_out = buffer;
    
endmodule

// 宽度控制子模块
module WidthControl (
    input  wire clk,
    input  wire [4:0] current_width,
    output wire [4:0] width_reg_out
);
    reg [4:0] width_reg;
    
    always @(posedge clk) begin
        width_reg <= current_width;
    end
    
    assign width_reg_out = width_reg;
    
endmodule

// 选择器子模块
module Selector #(
    parameter MAX_WIDTH = 16
)(
    input  wire [MAX_WIDTH-1:0] buffer_in,
    input  wire [4:0] width_reg,
    output wire selected_bit
);
    // 使用先行借位减法器计算索引
    wire [4:0] index;
    wire [4:0] one = 5'b00001;
    wire [4:0] p, g, c;
    
    // 生成信号 (Generate signals)
    assign g = ~width_reg & one;
    
    // 传播信号 (Propagate signals)
    assign p = ~width_reg | one;
    
    // 借位链 (Borrow chain)
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & c[0]);
    assign c[2] = g[2] | (p[2] & c[1]);
    assign c[3] = g[3] | (p[3] & c[2]);
    assign c[4] = g[4] | (p[4] & c[3]);
    
    // 计算差值 (Calculate difference)
    assign index = width_reg ^ one ^ {c[3:0], 1'b0};
    
    // 组合逻辑选择器，使用计算出的索引
    assign selected_bit = buffer_in[index];
    
endmodule

// 输出处理子模块
module OutputStage (
    input  wire clk,
    input  wire intermediate_in,
    output wire serial_out
);
    reg serial_out_reg;
    
    always @(posedge clk) begin
        serial_out_reg <= intermediate_in;
    end
    
    assign serial_out = serial_out_reg;
    
endmodule