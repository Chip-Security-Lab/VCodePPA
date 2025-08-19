//SystemVerilog
module basic_right_shift #(parameter WIDTH = 8) (
    input wire clk,
    input wire reset_n,
    input wire serial_in,
    output wire serial_out
);
    // 移位寄存器
    reg [WIDTH-1:0] shift_reg;
    // 输出寄存器
    reg serial_out_reg;
    
    // 移位寄存器输入控制 - 处理输入位移位
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg[WIDTH-1] <= 1'b0;
        end else begin
            shift_reg[WIDTH-1] <= serial_in;
        end
    end
    
    // 移位寄存器主体控制 - 处理内部位移位
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg[WIDTH-2:0] <= {(WIDTH-1){1'b0}};
        end else begin
            for (int i = 0; i < WIDTH-1; i = i + 1) begin
                shift_reg[i] <= shift_reg[i+1];
            end
        end
    end
    
    // 输出寄存器控制 - 处理输出位采样
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            serial_out_reg <= 1'b0;
        end else begin
            serial_out_reg <= shift_reg[0];
        end
    end
    
    // 输出驱动
    assign serial_out = serial_out_reg;
endmodule