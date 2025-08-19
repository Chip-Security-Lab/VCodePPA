//SystemVerilog
//------------------------------------------------------------------------------
// Huffman encoder with Req-Ack handshake interface
//------------------------------------------------------------------------------
module huffman_encoder (
    input        clk,         // Clock signal (added)
    input        rst_n,       // Reset signal (added)
    input [7:0]  symbol_in,   // Input symbol
    input        req_in,      // Request signal (replaces enable)
    output       ack_in,      // Acknowledge signal (new)
    output [15:0] code_out,   // Output code
    output [3:0]  code_len,   // Code length
    output       req_out,     // Request output (new)
    input        ack_out      // Acknowledge input (new)
);
    // Internal registers
    reg [15:0] code_out_reg;
    reg [3:0]  code_len_reg;
    reg        req_out_reg;
    reg        ack_in_reg;
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam WAIT_ACK = 2'b10;
    reg [1:0] state, next_state;
    
    // Wires to connect with lookup module
    wire [15:0] symbol_code;
    wire [3:0]  symbol_len;
    
    // Symbol lookup module instance
    huffman_lookup u_lookup (
        .symbol(symbol_in),
        .code(symbol_code),
        .code_length(symbol_len)
    );
    
    // Assign outputs
    assign code_out = code_out_reg;
    assign code_len = code_len_reg;
    assign req_out = req_out_reg;
    assign ack_in = ack_in_reg;
    
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
                if (req_in) next_state = PROCESS;
            end
            
            PROCESS: begin
                next_state = WAIT_ACK;
            end
            
            WAIT_ACK: begin
                if (ack_out) next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_out_reg <= 16'b0;
            code_len_reg <= 4'b0;
            req_out_reg <= 1'b0;
            ack_in_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    req_out_reg <= 1'b0;
                    ack_in_reg <= req_in ? 1'b1 : 1'b0;
                end
                
                PROCESS: begin
                    code_out_reg <= symbol_code;
                    code_len_reg <= symbol_len;
                    req_out_reg <= 1'b1;
                    ack_in_reg <= 1'b0;
                end
                
                WAIT_ACK: begin
                    if (ack_out) begin
                        req_out_reg <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule

//------------------------------------------------------------------------------
// Symbol to Huffman code lookup module
//------------------------------------------------------------------------------
module huffman_lookup (
    input [7:0] symbol,
    output reg [15:0] code,
    output reg [3:0] code_length
);
    // Parameterized lookup table implementation
    always @(*) begin
        case (symbol)
            8'h41: begin code = 16'b0; code_length = 4'd1; end        // 'A'
            8'h42: begin code = 16'b10; code_length = 4'd2; end       // 'B'
            8'h43: begin code = 16'b110; code_length = 4'd3; end      // 'C'
            8'h44: begin code = 16'b1110; code_length = 4'd4; end     // 'D'
            8'h45: begin code = 16'b11110; code_length = 4'd5; end    // 'E'
            default: begin code = 16'b111110; code_length = 4'd6; end // Others
        endcase
    end
endmodule