//SystemVerilog
module shift_reg_4bit (
    input wire clk,                // Clock input
    input wire rst,                // Reset signal
    input wire load_en,            // Parallel load enable
    input wire shift_en,           // Shift enable
    input wire serial_in,          // Serial input data
    input wire [3:0] parallel_data, // Parallel input data
    output wire serial_out,        // Serial output data
    output wire [3:0] parallel_out  // Parallel output data
);
    // Main shift register
    reg [3:0] sr;
    
    // Next state logic - separating combinational logic from sequential
    reg [3:0] next_sr;
    
    // Control signals combined for case statement
    wire [1:0] ctrl = {rst, load_en};
    
    // Combinational logic for calculating next state using case statement
    always @(*) begin
        case ({rst, load_en, shift_en})
            3'b100, 3'b101: next_sr = 4'b0000;      // Reset active
            3'b010, 3'b011: next_sr = parallel_data; // Load active
            3'b001:         next_sr = {sr[2:0], serial_in}; // Shift active
            default:        next_sr = sr;           // Hold current value
        endcase
    end
    
    // Sequential logic for register update
    always @(posedge clk) begin
        sr <= next_sr;
    end
    
    // Output assignments
    assign serial_out = sr[3];
    assign parallel_out = sr;
    
endmodule