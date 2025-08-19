//SystemVerilog
// 顶层模块
module shadow_reg_dynamic #(parameter MAX_WIDTH=16) (
    input clk,
    input [3:0] width_sel,
    input [MAX_WIDTH-1:0] data_in,
    output [MAX_WIDTH-1:0] data_out
);
    wire [MAX_WIDTH-1:0] shadow_data;
    wire [MAX_WIDTH-1:0] mask_value;
    
    // 数据缓存子模块实例
    data_buffer #(
        .WIDTH(MAX_WIDTH)
    ) buffer_inst (
        .clk(clk),
        .data_in(data_in),
        .shadow_data(shadow_data)
    );
    
    // 掩码生成器子模块实例
    mask_generator #(
        .MAX_WIDTH(MAX_WIDTH)
    ) mask_inst (
        .width_sel(width_sel),
        .mask_out(mask_value)
    );
    
    // 数据输出处理子模块实例
    output_controller #(
        .WIDTH(MAX_WIDTH)
    ) output_inst (
        .clk(clk),
        .shadow_data(shadow_data),
        .mask_value(mask_value),
        .data_out(data_out)
    );
endmodule

// 数据缓存子模块
module data_buffer #(parameter WIDTH=16) (
    input clk,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] shadow_data
);
    always @(posedge clk) begin
        shadow_data <= data_in;
    end
endmodule

// 掩码生成器子模块
module mask_generator #(parameter MAX_WIDTH=16) (
    input [3:0] width_sel,
    output [MAX_WIDTH-1:0] mask_out
);
    wire [MAX_WIDTH-1:0] shifted_value;
    wire [3:0] borrow;
    wire [MAX_WIDTH-1:0] result;
    
    // 左移操作生成被减数
    assign shifted_value = (1'b1 << width_sel);
    
    // 四位先行借位减法器核心逻辑
    lookahead_subtractor_4bit sub_core (
        .a(shifted_value[3:0]),
        .b(4'b0001),
        .bin(1'b0),
        .diff(result[3:0]),
        .bout(borrow[0])
    );
    
    // 处理高位
    generate
        if (MAX_WIDTH > 4) begin
            assign result[MAX_WIDTH-1:4] = shifted_value[MAX_WIDTH-1:4] - {(MAX_WIDTH-4){1'b0}} - borrow[0];
        end
    endgenerate
    
    assign mask_out = result;
endmodule

// 数据输出处理子模块
module output_controller #(parameter WIDTH=16) (
    input clk,
    input [WIDTH-1:0] shadow_data,
    input [WIDTH-1:0] mask_value,
    output reg [WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        data_out <= shadow_data & mask_value;
    end
endmodule

// 四位先行借位减法器
module lookahead_subtractor_4bit (
    input [3:0] a,
    input [3:0] b,
    input bin,
    output [3:0] diff,
    output bout
);
    wire [3:0] p; // 传播借位信号
    wire [3:0] g; // 生成借位信号
    wire [4:0] borrow; // 借位信号，包括输入借位和输出借位
    
    // 初始化输入借位
    assign borrow[0] = bin;
    
    // 计算传播和生成信号
    assign p = ~a | b;  // 传播信号：当 a < b 或 a = 0 时传播借位
    assign g = ~a & b;  // 生成信号：当 a < b 时产生借位
    
    // 先行借位逻辑
    assign borrow[1] = g[0] | (p[0] & borrow[0]);
    assign borrow[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & borrow[0]);
    assign borrow[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & borrow[0]);
    assign borrow[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & borrow[0]);
    
    // 计算差值
    assign diff = a ^ b ^ borrow[3:0];
    
    // 输出借位
    assign bout = borrow[4];
endmodule