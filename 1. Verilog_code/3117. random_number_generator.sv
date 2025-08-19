module random_number_generator(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [7:0] seed,
    input wire load_seed,
    output reg [15:0] random_value
);
    parameter [1:0] IDLE = 2'b00, LOAD = 2'b01, GENERATE = 2'b10;
    reg [1:0] state, next_state;
    reg [15:0] lfsr_reg;
    reg feedback;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            lfsr_reg <= 16'h1234; // Default seed
            random_value <= 16'h0000;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    // Do nothing
                end
                LOAD: begin
                    lfsr_reg <= {seed, 8'h01}; // Ensure not all zeros
                end
                GENERATE: begin
                    if (enable) begin
                        feedback = lfsr_reg[15] ^ lfsr_reg[14] ^ lfsr_reg[12] ^ lfsr_reg[3];
                        lfsr_reg <= {lfsr_reg[14:0], feedback};
                        random_value <= lfsr_reg;
                    end
                end
            endcase
        end
    end
    
    always @(*) begin
        case (state)
            IDLE: begin
                if (load_seed)
                    next_state = LOAD;
                else if (enable)
                    next_state = GENERATE;
                else
                    next_state = IDLE;
            end
            LOAD: begin
                next_state = GENERATE;
            end
            GENERATE: begin
                if (!enable)
                    next_state = IDLE;
                else if (load_seed)
                    next_state = LOAD;
                else
                    next_state = GENERATE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule