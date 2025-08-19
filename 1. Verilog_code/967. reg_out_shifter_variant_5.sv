//SystemVerilog
module reg_out_shifter (
    input clk,
    input reset_n,
    input serial_in,
    output reg serial_out
);
    reg [3:0] shift;
    reg shift_0_reg;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift <= 4'b0000;
            shift_0_reg <= 1'b0;
            serial_out <= 1'b0;
        end
        else begin
            shift <= {serial_in, shift[3:1]};
            shift_0_reg <= shift[0];
            serial_out <= shift_0_reg;
        end
    end
endmodule