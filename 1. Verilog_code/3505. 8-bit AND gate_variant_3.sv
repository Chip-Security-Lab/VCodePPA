//SystemVerilog
// 8-bit AND gate with pipelined structure using Req-Ack handshake protocol
module and_gate_8 (
    input wire clk,            // Clock input
    input wire rst_n,          // Active low reset
    input wire [7:0] a_in,     // 8-bit input A
    input wire [7:0] b_in,     // 8-bit input B
    input wire req_in,         // Request signal from sender
    output reg ack_in,         // Acknowledge signal to sender
    output reg [7:0] y_out,    // 8-bit registered output Y
    output reg req_out,        // Request signal to receiver
    input wire ack_out         // Acknowledge signal from receiver
);
    // Input registration stage
    reg [7:0] a_reg, b_reg;
    
    // Intermediate computation signals
    reg [3:0] lower_result, upper_result;
    
    // Handshake state machine states
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam WAIT_ACK = 2'b10;
    
    // State registers
    reg [1:0] state, next_state;
    reg data_valid;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (req_in && !ack_in)
                    next_state = COMPUTE;
            end
            
            COMPUTE: begin
                next_state = WAIT_ACK;
            end
            
            WAIT_ACK: begin
                if (ack_out) begin
                    if (!req_in)
                        next_state = IDLE;
                    else
                        next_state = COMPUTE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Data processing and handshake control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers
            a_reg <= 8'h00;
            b_reg <= 8'h00;
            lower_result <= 4'h0;
            upper_result <= 4'h0;
            y_out <= 8'h00;
            ack_in <= 1'b0;
            req_out <= 1'b0;
            data_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    ack_in <= 1'b0;
                    req_out <= 1'b0;
                    
                    if (req_in && !ack_in) begin
                        // Register inputs when request comes
                        a_reg <= a_in;
                        b_reg <= b_in;
                        ack_in <= 1'b1;
                    end
                end
                
                COMPUTE: begin
                    // Compute lower and upper nibbles separately
                    lower_result <= a_reg[3:0] & b_reg[3:0];
                    upper_result <= a_reg[7:4] & b_reg[7:4];
                    data_valid <= 1'b1;
                    ack_in <= 1'b0;
                end
                
                WAIT_ACK: begin
                    if (data_valid) begin
                        // Combine results and raise request to receiver
                        y_out <= {upper_result, lower_result};
                        req_out <= 1'b1;
                        data_valid <= 1'b0;
                    end
                    
                    if (ack_out) begin
                        // Receiver acknowledged, ready for next computation
                        req_out <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule