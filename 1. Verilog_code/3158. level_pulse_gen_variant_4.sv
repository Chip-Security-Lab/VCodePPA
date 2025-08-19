//SystemVerilog
module level_pulse_gen(
    input clock,
    input trigger,
    input [3:0] pulse_width,
    output reg pulse
);
    reg [3:0] counter;
    reg triggered;
    reg [3:0] pulse_width_minus_one;
    
    // Define the possible states
    localparam IDLE = 2'b00;
    localparam ACTIVE = 2'b01;
    localparam TERMINATE = 2'b10;
    
    // Create a state value based on current conditions
    wire [1:0] state = (!triggered) ? 
                       (trigger ? ACTIVE : IDLE) : 
                       ((counter == pulse_width_minus_one) ? TERMINATE : ACTIVE);
    
    always @(posedge clock) begin
        // Pre-compute the pulse_width - 1 to reduce critical path
        pulse_width_minus_one <= pulse_width - 1'b1;
        
        // Use case statement based on state
        case (state)
            IDLE: begin
                // Default idle state
                pulse <= 1'b0;
                counter <= 4'd0;
            end
            
            ACTIVE: begin
                if (!triggered) begin
                    // Start of pulse sequence
                    triggered <= 1'b1;
                    counter <= 4'd0;
                    pulse <= 1'b1;
                end else begin
                    // Continue pulse sequence
                    counter <= counter + 1'b1;
                    pulse <= 1'b1;
                end
            end
            
            TERMINATE: begin
                // End of pulse sequence
                pulse <= 1'b0;
                triggered <= 1'b0;
                counter <= 4'd0;
            end
            
            default: begin
                // Safe default state
                pulse <= 1'b0;
                triggered <= 1'b0;
                counter <= 4'd0;
            end
        endcase
    end
endmodule