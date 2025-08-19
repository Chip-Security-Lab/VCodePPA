//SystemVerilog
// IEEE 1364-2005
module ShiftLeft #(parameter WIDTH=8) (
    input clk, rst_n, en, serial_in,
    output reg [WIDTH-1:0] q
);
    // Internal signals for two's complement implementation
    reg [1:0] operation_mode;
    reg [WIDTH-1:0] next_state;
    reg [WIDTH-1:0] complement_mask;
    
    // Determine operation mode based on control signals
    always @(*) begin
        operation_mode = {!rst_n, en};
        
        // Use two's complement concepts for state transitions
        complement_mask = {WIDTH{1'b0}};
        
        case(operation_mode)
            2'b10, 2'b11: next_state = {WIDTH{1'b0}}; // Reset condition
            2'b01: begin
                // Left shift implementation using binary operations
                // This is equivalent to {q[WIDTH-2:0], serial_in}
                next_state = (q << 1) | {{(WIDTH-1){1'b0}}, serial_in};
            end
            2'b00: next_state = q; // Hold current value
            default: next_state = q; // Default case
        endcase
    end
    
    // Sequential logic for state update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= {WIDTH{1'b0}};
        else
            q <= next_state;
    end
endmodule