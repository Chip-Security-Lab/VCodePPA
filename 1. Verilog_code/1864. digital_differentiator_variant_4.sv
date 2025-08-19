//SystemVerilog
module digital_differentiator #(parameter WIDTH=8) (
    input clk, rst,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_diff
);
    // 内部连线
    wire [WIDTH-1:0] prev_data;
    
    // 时序逻辑子模块实例化
    diff_sequential_logic #(.WIDTH(WIDTH)) seq_logic (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .prev_data(prev_data)
    );
    
    // 组合逻辑子模块实例化
    diff_combinational_logic #(.WIDTH(WIDTH)) comb_logic (
        .data_in(data_in),
        .prev_data(prev_data),
        .data_diff(data_diff)
    );
endmodule

// 时序逻辑模块
module diff_sequential_logic #(parameter WIDTH=8) (
    input clk, rst,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] prev_data
);
    // 纯时序逻辑，处理数据延迟
    always @(posedge clk or posedge rst) begin
        if (rst) 
            prev_data <= {WIDTH{1'b0}};
        else 
            prev_data <= data_in;
    end
endmodule

// 组合逻辑模块
module diff_combinational_logic #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] prev_data,
    output [WIDTH-1:0] data_diff
);
    // 纯组合逻辑，计算差分
    assign data_diff = data_in ^ prev_data;
endmodule