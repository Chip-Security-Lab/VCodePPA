//SystemVerilog
module debug_timer #(parameter WIDTH = 16)(
    input wire clk, rst_n, enable, debug_mode,
    input wire [WIDTH-1:0] reload,
    output reg [WIDTH-1:0] count,
    output wire expired
);
    // Fan-out buffering for count signal
    reg [WIDTH-1:0] count_buf1, count_buf2;
    reg reload_pending;
    wire count_max;
    
    // Count maximum condition buffered to reduce path delay
    assign count_max = (count == {WIDTH{1'b1}});
    
    // Control signals lookup table
    reg [1:0] control_state;
    wire [1:0] control_inputs;
    reg [1:0] next_action;
    
    // Pack control inputs into a single vector for LUT indexing
    assign control_inputs = {debug_mode, count_max | reload_pending};
    
    // Action encoding:
    // 2'b00: No change to count
    // 2'b01: Load reload value
    // 2'b10: Increment count
    // 2'b11: Set reload_pending
    
    // Pre-compute next actions based on control inputs
    always @(*) begin
        // Default action
        next_action = 2'b00;
        
        // Determine control state based on enable and other inputs
        control_state = {enable, control_inputs};
        
        // Lookup table implementation for control logic
        case (control_state)
            3'b100: next_action = 2'b10;  // enable=1, debug_mode=0, count_max|reload_pending=0 -> increment
            3'b101: next_action = 2'b01;  // enable=1, debug_mode=0, count_max|reload_pending=1 -> reload
            3'b111: next_action = 2'b00;  // enable=1, debug_mode=1, count_max|reload_pending=1 -> no change
            3'b110: next_action = 2'b00;  // enable=1, debug_mode=1, count_max|reload_pending=0 -> no change
            3'b011: next_action = 2'b11;  // enable=0, debug_mode=1, count_max|reload_pending=1 -> set pending
            default: next_action = 2'b00; // All other cases -> no change
        endcase
    end
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            count <= {WIDTH{1'b0}}; 
            count_buf1 <= {WIDTH{1'b0}};
            count_buf2 <= {WIDTH{1'b0}};
            reload_pending <= 1'b0; 
        end
        else begin
            // Update buffered count values to distribute fan-out
            count_buf1 <= count;
            count_buf2 <= count;
            
            // Execute action based on lookup table result
            case (next_action)
                2'b01: begin // Load reload value
                    count <= reload;
                    reload_pending <= 1'b0;
                end
                2'b10: begin // Increment count
                    count <= count + 1'b1;
                end
                2'b11: begin // Set reload_pending
                    reload_pending <= 1'b1;
                end
                default: begin // No change
                    count <= count;
                    reload_pending <= reload_pending;
                end
            endcase
        end
    end
    
    // Use buffered count for expired signal to reduce load on critical path
    assign expired = (count_buf1 == {WIDTH{1'b1}}) && enable && !debug_mode;
endmodule