module watchdog_timer(
    input wire clk, rst_n,
    input wire [15:0] timeout_value,
    input wire update_timeout,
    input wire kick,
    output reg timeout,
    output reg [2:0] warn_level
);
    localparam IDLE=2'b00, COUNTING=2'b01, TIMEOUT=2'b10, RESET=2'b11;
    reg [1:0] state, next;
    reg [15:0] counter;
    reg [15:0] timeout_reg;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            counter <= 16'd0;
            timeout_reg <= 16'd1000; // Default timeout
            timeout <= 1'b0;
            warn_level <= 3'd0;
        end else begin
            state <= next;
            
            if (update_timeout)
                timeout_reg <= timeout_value;
                
            case (state)
                IDLE: begin
                    counter <= 16'd0;
                    timeout <= 1'b0;
                    warn_level <= 3'd0;
                end
                COUNTING: begin
                    if (kick)
                        counter <= 16'd0;
                    else begin
                        counter <= counter + 16'd1;
                        
                        // Set warning levels
                        if (counter > (timeout_reg >> 1))
                            warn_level <= 3'd3;
                        else if (counter > (timeout_reg >> 2))
                            warn_level <= 3'd2;
                        else if (counter > (timeout_reg >> 3))
                            warn_level <= 3'd1;
                        else
                            warn_level <= 3'd0;
                    end
                end
                TIMEOUT: begin
                    timeout <= 1'b1;
                    warn_level <= 3'd7;
                end
                RESET: begin
                    counter <= 16'd0;
                    timeout <= 1'b0;
                    warn_level <= 3'd0;
                end
            endcase
        end
    
    always @(*)
        case (state)
            IDLE: next = COUNTING;
            COUNTING: next = (counter >= timeout_reg) ? TIMEOUT : COUNTING;
            TIMEOUT: next = kick ? RESET : TIMEOUT;
            RESET: next = COUNTING;
            default: next = IDLE;
        endcase
endmodule