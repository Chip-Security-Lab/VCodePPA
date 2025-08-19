//SystemVerilog
module IVMU_NestingCtrl #(parameter LVL=3) (
    input clk, rst,
    input [LVL-1:0] int_lvl,
    output reg [LVL-1:0] current_lvl
);

// This logic updates current_lvl based on int_lvl and rst.
// current_lvl is set to 0 if rst is high or if int_lvl is 0.
// Otherwise, if int_lvl is non-zero and greater than the current_lvl,
// current_lvl is updated to int_lvl.

wire [LVL-1:0] next_current_lvl;
wire int_lvl_is_zero;
wire int_lvl_is_higher;

// Determine if int_lvl is zero using a reduction OR
assign int_lvl_is_zero = !(|int_lvl);

// Determine if int_lvl is strictly greater than current_lvl
assign int_lvl_is_higher = (int_lvl > current_lvl);

// Combinational logic to determine the next state of current_lvl
// next_current_lvl is 0 if reset is active or int_lvl is zero
// Otherwise, it's int_lvl if int_lvl is higher than current_lvl,
// or current_lvl if int_lvl is not higher (and non-zero)
assign next_current_lvl = (rst || int_lvl_is_zero) ? {LVL{1'b0}} :
                          (int_lvl_is_higher ? int_lvl : current_lvl);

// Sequential logic to update the register on the clock edge or reset
always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_lvl <= {LVL{1'b0}}; // Asynchronous reset to 0
    end else begin
        current_lvl <= next_current_lvl; // Update with the calculated next state
    end
end

endmodule