//SystemVerilog
module bwt_encoder #(parameter WIDTH = 8, LENGTH = 4)(
    input                    clk,
    input                    reset,
    input                    enable,
    input  [WIDTH-1:0]       data_in,
    input                    in_valid,
    output reg [WIDTH-1:0]   data_out,
    output reg               out_valid,
    output reg [$clog2(LENGTH)-1:0] index
);
    reg [WIDTH-1:0] buffer [0:LENGTH-1];
    reg [$clog2(LENGTH)-1:0] buf_ptr;
    
    // One-hot state encoding 
    localparam STATE_RESET = 4'b0001;  // Reset state
    localparam STATE_FILL  = 4'b0010;  // Filling buffer
    localparam STATE_FULL  = 4'b0100;  // Buffer full, output data
    localparam STATE_IDLE  = 4'b1000;  // Idle state
    
    reg [3:0] current_state, next_state;
    
    // State register
    always @(posedge clk) begin
        if (reset)
            current_state <= STATE_RESET;
        else
            current_state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        next_state = current_state; // Default: maintain current state
        
        case (current_state)
            STATE_RESET: begin
                next_state = STATE_IDLE;
            end
            
            STATE_IDLE: begin
                if (enable && in_valid)
                    next_state = STATE_FILL;
            end
            
            STATE_FILL: begin
                if (buf_ptr == LENGTH-2 && enable && in_valid)
                    next_state = STATE_FULL;
                else if (!enable || !in_valid)
                    next_state = STATE_IDLE;
            end
            
            STATE_FULL: begin
                next_state = STATE_IDLE;
            end
            
            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end
    
    // Output and datapath logic
    always @(posedge clk) begin
        if (reset) begin
            buf_ptr <= 0;
            out_valid <= 0;
        end
        else begin
            case (current_state)
                STATE_RESET: begin
                    buf_ptr <= 0;
                    out_valid <= 0;
                end
                
                STATE_FILL: begin
                    if (enable && in_valid) begin
                        buffer[buf_ptr] <= data_in;
                        buf_ptr <= buf_ptr + 1;
                        out_valid <= 0;
                    end
                end
                
                STATE_FULL: begin
                    if (enable && in_valid) begin
                        buffer[buf_ptr] <= data_in;
                        data_out <= buffer[0];
                        index <= 0; // Original string position
                        out_valid <= 1;
                    end
                end
                
                STATE_IDLE: begin
                    out_valid <= 0;
                end
            endcase
        end
    end
endmodule