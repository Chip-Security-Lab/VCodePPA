//SystemVerilog
module clear_ring_counter(
    input wire clk,
    input wire req,       // Request signal (replaces clear)
    output reg ack,       // Acknowledge signal (new output)
    output reg [3:0] counter
);
    // Internal state
    reg req_ff;           // Renamed from req_prev for better readability
    reg req_edge;         // New signal to capture request edge detection result
    reg [1:0] state;
    reg [1:0] next_state; // Added to implement forward retiming
    reg [3:0] next_counter; // Added for forward retiming of counter logic
    reg next_ack;         // Added for forward retiming of ack signal
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam COMPLETE = 2'b10;
    
    initial begin
        counter = 4'b0001;
        ack = 1'b0;
        req_ff = 1'b0;
        req_edge = 1'b0;
        state = IDLE;
        next_state = IDLE;
        next_counter = 4'b0001;
        next_ack = 1'b0;
    end
    
    // Move combinational logic before registers (forward retiming)
    always @(*) begin
        // Edge detection moved into combinational block
        req_edge = req && !req_ff;
        
        // Default assignments to prevent latches
        next_state = state;
        next_counter = counter;
        next_ack = ack;
        
        case(state)
            IDLE: begin
                next_ack = 1'b0;
                if (req_edge) begin
                    // Rising edge of request detected
                    next_counter = 4'b0000;
                    next_state = PROCESS;
                end
                else begin
                    // Optimized ring counter logic
                    next_counter = (counter == 4'b0000) ? 4'b0001 : {counter[2:0], counter[3]};
                end
            end
            
            PROCESS: begin
                next_state = COMPLETE;
                next_ack = 1'b1;    // Generate acknowledge
            end
            
            COMPLETE: begin
                if (!req) begin
                    // Wait for request to be deasserted
                    next_state = IDLE;
                    next_ack = 1'b0;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Register updates moved after combinational logic
    always @(posedge clk) begin
        req_ff <= req;       // Sample input
        state <= next_state;
        counter <= next_counter;
        ack <= next_ack;
    end
endmodule