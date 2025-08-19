module AsyncRstSyncEn #(parameter W=6) (
    input sys_clk, async_rst_n, en_shift,
    input serial_data,
    output reg [W-1:0] shift_reg
);
always @(posedge sys_clk or negedge async_rst_n) begin
    if (!async_rst_n) shift_reg <= 0;
    else if (en_shift) shift_reg <= {shift_reg[W-2:0], serial_data};
end
endmodule
