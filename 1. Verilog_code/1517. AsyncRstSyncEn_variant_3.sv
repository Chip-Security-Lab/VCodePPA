//SystemVerilog
// IEEE 1364-2005 Verilog标准
module AsyncRstSyncEn #(parameter W=6) (
    input sys_clk, async_rst_n, en_shift,
    input serial_data,
    output reg [W-1:0] shift_reg
);

    // 直接使用常规移位操作替代LUT结构
    // 这种实现更简单、更高效，适合大多数FPGA/ASIC实现
    always @(posedge sys_clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            shift_reg <= {W{1'b0}};
        end else if (en_shift) begin
            shift_reg <= {shift_reg[W-2:0], serial_data};
        end
    end

endmodule