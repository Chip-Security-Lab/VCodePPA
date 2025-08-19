//SystemVerilog
module enc_64b66b (
    input wire clk, rst_n,
    input wire encode,
    input wire [63:0] data_in,
    input wire [1:0] block_type, // 00=data, 01=ctrl, 10=mixed, 11=reserved
    input wire [65:0] encoded_in,
    output reg [65:0] encoded_out,
    output reg [63:0] data_out,
    output reg [1:0] type_out,
    output reg valid_out, err_detected
);
    // Scrambler polynomial: x^58 + x^39 + 1
    reg [57:0] scrambler_state;
    
    // One-hot encoding for FSM states
    localparam IDLE      = 5'b00001;
    localparam DATA_ENC  = 5'b00010;
    localparam CTRL_ENC  = 5'b00100;
    localparam MIXED_ENC = 5'b01000;
    localparam RESV_ENC  = 5'b10000;
    
    reg [4:0] state, next_state;
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            scrambler_state <= 58'h3_FFFF_FFFF_FFFF;
            valid_out <= 1'b0;
            encoded_out <= 66'b0;
        end else begin
            state <= next_state;
            
            case (state)
                DATA_ENC: begin
                    // Encoding data block
                    encoded_out[65:64] <= 2'b01;
                    // Scramble payload (would implement scrambling algorithm)
                    // encoded_out[63:0] = scrambled_data;
                    valid_out <= 1'b1;
                end
                
                CTRL_ENC, 
                MIXED_ENC, 
                RESV_ENC: begin
                    // Encoding control/mixed/reserved block
                    encoded_out[65:64] <= 2'b10;
                    // Scramble payload (would implement scrambling algorithm)
                    // encoded_out[63:0] = scrambled_data;
                    valid_out <= 1'b1;
                end
                
                IDLE: begin
                    // No operation in IDLE state
                    valid_out <= 1'b0;
                end
                
                default: begin
                    // Default case for safety
                    valid_out <= 1'b0;
                end
            endcase
        end
    end
    
    // Next state logic with one-hot encoding
    always @(*) begin
        next_state = state; // Default: stay in current state
        
        case (state)
            IDLE: begin
                if (encode) begin
                    case (block_type)
                        2'b00:   next_state = DATA_ENC;
                        2'b01:   next_state = CTRL_ENC;
                        2'b10:   next_state = MIXED_ENC;
                        2'b11:   next_state = RESV_ENC;
                        default: next_state = IDLE;
                    endcase
                end
            end
            
            DATA_ENC, CTRL_ENC, MIXED_ENC, RESV_ENC: begin
                next_state = IDLE; // Go back to IDLE after processing
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule