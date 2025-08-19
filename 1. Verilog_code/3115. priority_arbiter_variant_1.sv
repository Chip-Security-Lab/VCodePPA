//SystemVerilog
module priority_arbiter(
    input wire clk,
    input wire reset,
    input wire [3:0] requests,
    output reg [3:0] grant,
    output reg busy
);
    // Optimized state encoding for better synthesis
    parameter [1:0] IDLE = 2'b00, GRANT0 = 2'b01, GRANT1 = 2'b10, GRANT2 = 2'b11;
    reg [1:0] state, next_state;
    
    // Encoding priority directly in register for faster lookup
    reg [3:0] grant_lookup;
    
    // Sequential logic block
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            grant <= 4'b0000;
            busy <= 1'b0;
        end else begin
            state <= next_state;
            grant <= grant_lookup;
            busy <= (next_state != IDLE);
        end
    end
    
    // Optimized next-state and grant logic using case with conditional checks
    always @(*) begin
        // Default values
        next_state = IDLE;
        grant_lookup = 4'b0000;
        
        // Priority encoded using case with explicit conditions
        case (1'b1)
            requests[0]: begin 
                next_state = GRANT0;
                grant_lookup = 4'b0001;
            end
            requests[1]: begin
                next_state = GRANT1;
                grant_lookup = 4'b0010;
            end
            requests[2]: begin
                next_state = GRANT2;
                grant_lookup = 4'b0100;
            end
            requests[3]: begin
                next_state = 2'b11; // GRANT3
                grant_lookup = 4'b1000;
            end
            default: begin
                next_state = IDLE;
                grant_lookup = 4'b0000;
            end
        endcase
    end
endmodule