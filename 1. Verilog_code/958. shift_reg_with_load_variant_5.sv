//SystemVerilog
module shift_reg_with_load (
    input wire clk, reset,
    input wire shift_en, load_en,
    input wire serial_in,
    input wire [7:0] parallel_in,
    output wire serial_out,
    output wire [7:0] parallel_out
);
    // Main shift register
    reg [7:0] shift_reg;
    
    // Split control path and data path to optimize critical path
    reg shift_en_reg, load_en_reg;
    reg serial_in_reg;
    reg [7:0] parallel_in_reg;
    
    // Pre-compute next shift value to reduce logic depth
    reg [7:0] next_shift_value;
    
    // Register control signals with priority encoding to reduce mux depth
    always @(posedge clk) begin
        if (reset) begin
            shift_en_reg <= 1'b0;
            load_en_reg <= 1'b0;
            serial_in_reg <= 1'b0;
            parallel_in_reg <= 8'h00;
        end else begin
            shift_en_reg <= shift_en;
            load_en_reg <= load_en;
            serial_in_reg <= serial_in;
            parallel_in_reg <= parallel_in;
        end
    end
    
    // Pre-compute next shift value to balance path delays
    always @(*) begin
        next_shift_value = {shift_reg[6:0], serial_in_reg};
    end
    
    // Simplified control path with balanced paths
    always @(posedge clk) begin
        if (reset)
            shift_reg <= 8'h00;
        else if (load_en_reg)
            shift_reg <= parallel_in_reg;
        else if (shift_en_reg)
            shift_reg <= next_shift_value;
    end
    
    // Direct output assignments
    assign serial_out = shift_reg[7];
    assign parallel_out = shift_reg;
endmodule