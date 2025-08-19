//SystemVerilog
module async_arith_shift_right (
    input      [15:0] data_i,
    input      [3:0]  shamt_i,
    input             enable_i,
    output reg [15:0] data_o
);

    // Pipeline stage 1: Input register and enable control
    reg [15:0] data_reg;
    reg [3:0]  shamt_reg;
    reg        enable_reg;
    
    // Pipeline stage 2: Shift operation
    reg [15:0] shifted_data;
    
    // Stage 1: Input registration
    always @(*) begin
        data_reg   = data_i;
        shamt_reg  = shamt_i;
        enable_reg = enable_i;
    end
    
    // Stage 2: Shift operation with sign extension
    always @(*) begin
        shifted_data = enable_reg ? ($signed(data_reg) >>> shamt_reg) : data_reg;
    end
    
    // Stage 3: Output registration
    always @(*) begin
        data_o = shifted_data;
    end

endmodule