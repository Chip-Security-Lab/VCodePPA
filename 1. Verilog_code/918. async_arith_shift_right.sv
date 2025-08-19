module async_arith_shift_right (
    input      [15:0] data_i,
    input      [3:0]  shamt_i,
    input             enable_i,
    output reg [15:0] data_o
);
    // Combinational implementation with enable control
    always @(*) begin
        if (enable_i)
            // Arithmetic right shift preserves sign bit
            data_o = $signed(data_i) >>> shamt_i;
        else
            data_o = data_i; // Pass through when disabled
    end
    
    // Sign extension ensures MSB is replicated during right shift
    // This maintains the sign of the original number
endmodule