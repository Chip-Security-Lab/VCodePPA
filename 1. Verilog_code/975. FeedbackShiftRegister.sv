module FeedbackShiftRegister #(parameter WIDTH=8) (
    input clk, en,
    input feedback_in,
    output serial_out // 移除reg
);
reg [WIDTH-1:0] shift_reg;
reg out_bit; // 添加中间寄存器

always @(posedge clk) begin
    if (en) begin
        shift_reg <= {shift_reg[WIDTH-2:0], feedback_in ^ shift_reg[WIDTH-1]};
        out_bit <= shift_reg[WIDTH-1];
    end
end

assign serial_out = out_bit;
endmodule