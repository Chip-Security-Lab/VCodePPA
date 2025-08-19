//SystemVerilog
// IEEE 1364-2005 Verilog标准
module ShiftLeft #(parameter WIDTH=8) (
    input wire clk, rst_n, en, serial_in,
    output wire [WIDTH-1:0] q
);
    // 将输入端寄存器前移，存储前一个周期的serial_in
    reg serial_in_reg;
    // 中间寄存器，存储移位后的数据
    reg [WIDTH-2:0] q_internal;
    
    // 前向注册serial_in信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_in_reg <= 1'b0;
        end else if (en) begin
            serial_in_reg <= serial_in;
        end
    end
    
    // 主移位寄存器逻辑，现在使用前一周期存储的serial_in值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_internal <= {(WIDTH-1){1'b0}};
        end else if (en) begin
            q_internal <= {q_internal[WIDTH-3:0], serial_in_reg};
        end
    end
    
    // 组合输出连接
    assign q = {q_internal, serial_in_reg};

endmodule