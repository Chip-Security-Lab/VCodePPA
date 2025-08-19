//SystemVerilog
module rom_param_init #(
    parameter INIT_VAL = 64'h1234_5678_9ABC_DEF0
)(
    input [2:0] adr,
    output reg [15:0] dat
);
    reg [15:0] rom_data;
    
    // ROM data selection logic
    always @(*) begin
        case (adr)
            3'b000: rom_data = INIT_VAL[15:0];
            3'b001: rom_data = INIT_VAL[31:16];
            3'b010: rom_data = INIT_VAL[47:32];
            3'b011: rom_data = INIT_VAL[63:48];
            default: rom_data = 16'h0000;
        endcase
    end
    
    // Shift-and-add multiplier implementation
    // This multiplier takes bits [7:0] and [15:8] of rom_data as inputs
    wire [7:0] multiplicand = rom_data[7:0];
    wire [7:0] multiplier = rom_data[15:8];
    wire [15:0] product;
    
    // Shift-and-add multiplier module instantiation
    shift_add_multiplier mult_unit (
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .product(product)
    );
    
    // Output multiplexing
    always @(*) begin
        if (adr[2]) begin
            dat = product;  // Use multiplier output when adr[2] is set
        end else begin
            dat = rom_data; // Use ROM data otherwise
        end
    end
endmodule

// Shift-and-add multiplier module
module shift_add_multiplier (
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output [15:0] product
);
    reg [15:0] product_reg;
    reg [15:0] shifted_multiplicand;
    reg [7:0] multiplier_reg;
    integer i;
    
    always @(*) begin
        // Initialize registers
        product_reg = 16'b0;
        shifted_multiplicand = {8'b0, multiplicand};
        multiplier_reg = multiplier;
        
        // Shift and add algorithm
        for (i = 0; i < 8; i = i + 1) begin
            if (multiplier_reg[0])
                product_reg = product_reg + shifted_multiplicand;
                
            // Shift for next iteration
            shifted_multiplicand = shifted_multiplicand << 1;
            multiplier_reg = multiplier_reg >> 1;
        end
    end
    
    assign product = product_reg;
endmodule