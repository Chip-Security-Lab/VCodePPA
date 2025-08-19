//SystemVerilog
module hamming_8bit_secded(
    input clk,
    input rst_n,
    input [7:0] data_in,
    input data_valid,
    output reg data_ready,
    output reg [12:0] code_out,
    output reg code_valid,
    input code_ready
);

    // Internal registers for data and handshaking
    reg [7:0] data_reg;
    reg [3:0] parity_reg;
    reg overall_parity_reg;
    reg [12:0] code_reg;
    
    // Parity calculation logic
    wire [3:0] parity;
    wire overall_parity;
    
    // Calculate parity bits
    assign parity[0] = ^(data_reg & 8'b10101010);
    assign parity[1] = ^(data_reg & 8'b11001100);
    assign parity[2] = ^(data_reg & 8'b11110000);
    assign parity[3] = ^data_reg;
    
    // Calculate overall parity for double error detection
    assign overall_parity = ^{parity, data_reg};
    
    // Handshaking state machine
    localparam IDLE = 2'b00,
               PROCESSING = 2'b01,
               WAITING = 2'b10;
    
    reg [1:0] state, next_state;
    
    // State machine sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            data_reg <= 8'b0;
            parity_reg <= 4'b0;
            overall_parity_reg <= 1'b0;
            code_reg <= 13'b0;
            code_out <= 13'b0;
            code_valid <= 1'b0;
        end else begin
            state <= next_state;
            
            // Input data capture
            if (state == IDLE && data_valid && data_ready) begin
                data_reg <= data_in;
            end
            
            // Parity and code calculation
            if (state == PROCESSING) begin
                parity_reg <= parity;
                overall_parity_reg <= overall_parity;
                code_reg <= {overall_parity,
                           data_reg[7:4],
                           parity[3],
                           data_reg[3:1],
                           parity[2],
                           data_reg[0],
                           parity[1],
                           parity[0]};
                code_out <= code_reg;
                code_valid <= 1'b1;
            end else if (state == WAITING && code_ready && code_valid) begin
                code_valid <= 1'b0;
            end
        end
    end
    
    // State machine combinational logic
    always @(*) begin
        data_ready = 1'b0;
        next_state = state;
        
        case (state)
            IDLE: begin
                data_ready = 1'b1;
                if (data_valid && data_ready) begin
                    next_state = PROCESSING;
                end
            end
            
            PROCESSING: begin
                next_state = WAITING;
            end
            
            WAITING: begin
                if (code_ready && code_valid) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
endmodule