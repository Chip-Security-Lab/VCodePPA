//SystemVerilog-2005
module siso_shift_reg #(parameter WIDTH = 8) (
    input wire clk, rst, data_in,
    input wire valid_in,  // 流水线有效输入信号
    output wire data_out,
    output wire valid_out // 流水线有效输出信号
);
    // 移位寄存器流水线化
    reg [WIDTH-1:0] shift_reg;
    
    // 流水线控制信号
    reg [WIDTH-1:0] valid_pipeline;
    
    // 数据移位流水线逻辑
    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= {WIDTH{1'b0}};
        end else if (valid_in) begin
            shift_reg <= {shift_reg[WIDTH-2:0], data_in};
        end
    end
    
    // 控制信号流水线逻辑
    always @(posedge clk) begin
        if (rst) begin
            valid_pipeline <= {WIDTH{1'b0}};
        end else begin
            valid_pipeline <= {valid_pipeline[WIDTH-2:0], valid_in};
        end
    end
    
    // 输出赋值
    assign data_out = shift_reg[WIDTH-1];
    assign valid_out = valid_pipeline[WIDTH-1];
endmodule