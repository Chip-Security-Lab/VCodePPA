//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: int_ctrl_level_mask
// Description: Interrupt controller level mask with registered output
//              and optimized data path for improved timing and power efficiency
// Standard: IEEE 1364-2005 Verilog
///////////////////////////////////////////////////////////////////////////////
module int_ctrl_level_mask #(
    parameter N = 4  // Number of interrupt bits
) (
    input                 clk,     // System clock
    input                 rst_n,   // Active low reset
    input      [N-1:0]    int_in,  // Interrupt input signals
    input      [N-1:0]    mask_reg,// Mask register bits
    output reg [N-1:0]    int_out  // Masked interrupt output
);

    // Internal pipeline registers
    reg [N-1:0] int_in_reg;    // Registered input interrupts
    reg [N-1:0] mask_reg_sync; // Synchronized mask register
    
    // Combined process for stage 1 and 2 to reduce register count
    // Stage 1 & 2: Register inputs and calculate masked interrupts
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_in_reg <= {N{1'b0}};
            mask_reg_sync <= {N{1'b0}};
            int_out <= {N{1'b0}};
        end else begin
            int_in_reg <= int_in;
            mask_reg_sync <= mask_reg;
            int_out <= int_in_reg & mask_reg_sync;
        end
    end

endmodule