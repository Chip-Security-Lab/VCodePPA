//SystemVerilog
module shift_reg_with_load (
    input wire clk, reset,
    input wire shift_en, load_en,
    input wire serial_in,
    input wire [7:0] parallel_in,
    output wire serial_out,
    output wire [7:0] parallel_out
);
    reg [7:0] shift_reg;
    reg [7:0] shift_reg_buf1;
    reg [7:0] shift_reg_buf2;
    
    // Control signals combined for case statement
    reg [1:0] ctrl;
    
    // Main shift register logic with case statement
    always @(posedge clk) begin
        // Combine control signals
        ctrl = {load_en, shift_en};
        
        case (reset ? 2'b11 : ctrl)
            2'b11,   // Reset condition (priority) or undefined state
            2'b00:   // No operation
                shift_reg <= reset ? 8'h00 : shift_reg;
            2'b10:   // Load operation
                shift_reg <= parallel_in;
            2'b01:   // Shift operation
                shift_reg <= {shift_reg[6:0], serial_in};
            default: // Extra safety
                shift_reg <= shift_reg;
        endcase
    end
    
    // Buffer registers with enable logic to reduce power
    always @(posedge clk) begin
        if (reset) begin
            shift_reg_buf1 <= 8'h00;
            shift_reg_buf2 <= 8'h00;
        end
        else begin
            // Only update buffers when needed
            if (load_en || shift_en) begin
                shift_reg_buf1 <= shift_reg;
                shift_reg_buf2 <= shift_reg;
            end
        end
    end
    
    // Use buffered outputs to reduce loading on shift_reg
    assign serial_out = shift_reg_buf1[7];
    assign parallel_out = shift_reg_buf2;
endmodule