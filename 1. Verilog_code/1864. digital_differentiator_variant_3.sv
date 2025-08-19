//SystemVerilog
module digital_differentiator #(parameter WIDTH=8) (
    input clk, rst,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_diff
);
    // 内部信号声明
    reg [WIDTH-1:0] prev_data;
    wire [WIDTH-1:0] diff_result;
    reg [WIDTH-1:0] data_in_reg;
    
    // 时序逻辑部分 - 输入寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_reg <= {WIDTH{1'b0}};
        end else begin
            data_in_reg <= data_in;
        end
    end
    
    // 时序逻辑部分 - 输出寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prev_data <= {WIDTH{1'b0}};
        end else begin
            prev_data <= data_in_reg;
        end
    end
    
    // 组合逻辑部分 - 计算差值
    diff_calculator #(
        .WIDTH(WIDTH)
    ) diff_calc_inst (
        .current_data(data_in_reg),
        .previous_data(prev_data),
        .diff_out(diff_result)
    );
    
    // 输出赋值
    assign data_diff = diff_result;
    
endmodule

module diff_calculator #(parameter WIDTH=8) (
    input [WIDTH-1:0] current_data,
    input [WIDTH-1:0] previous_data,
    output [WIDTH-1:0] diff_out
);
    assign diff_out = current_data ^ previous_data;
endmodule