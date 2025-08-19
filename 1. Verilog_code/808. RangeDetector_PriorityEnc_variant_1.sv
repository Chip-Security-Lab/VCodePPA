//SystemVerilog
module RangeDetector_PriorityEnc #(
    parameter WIDTH = 8,
    parameter ZONES = 4
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] zone_limits [ZONES:0],
    output reg [$clog2(ZONES)-1:0] zone_num
);
    wire [WIDTH-1:0] enhanced_data;
    wire [WIDTH-1:0] comparison_value;
    
    // 使用先行进位加法器处理数据
    CLA_Adder #(.WIDTH(WIDTH)) cla_inst (
        .a(data_in),
        .b(8'h01),
        .cin(1'b0),
        .sum(enhanced_data),
        .cout()
    );
    
    // 使用增强后的数据进行区域检测
    integer i;
    always @(*) begin
        zone_num = 0;
        for(i = 0; i < ZONES; i = i+1) begin
            if(enhanced_data >= zone_limits[i] && enhanced_data < zone_limits[i+1]) begin
                zone_num = i;
            end
        end
    end
endmodule

module CLA_Adder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    wire [WIDTH-1:0] p; // 进位传播
    wire [WIDTH-1:0] g; // 进位生成
    wire [WIDTH:0] c;   // 进位信号
    
    // 生成进位传播和进位生成信号
    assign p = a ^ b;
    assign g = a & b;
    
    // 先行进位逻辑
    assign c[0] = cin;
    
    genvar j;
    generate
        for(j = 0; j < WIDTH; j = j+1) begin: carry_gen
            assign c[j+1] = g[j] | (p[j] & c[j]);
        end
    endgenerate
    
    // 计算和
    assign sum = p ^ c[WIDTH-1:0];
    assign cout = c[WIDTH];
endmodule