//SystemVerilog
module random_number_generator(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [7:0] seed,
    input wire load_seed,
    output reg [15:0] random_value,
    output reg valid,
    input wire ready
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
            valid <= 0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    valid <= 0; // Data not valid in IDLE state
                end
                LOAD: begin
                    lfsr_reg <= {seed, 8'h01}; // Ensure not all zeros
                    valid <= 0; // Data not valid during load
                end
                GENERATE: begin
                    if (enable && ready) begin
                        feedback = lfsr_reg[15] ^ lfsr_reg[14] ^ lfsr_reg[12] ^ lfsr_reg[3];
                        lfsr_reg <= {lfsr_reg[14:0], feedback};
                        random_value <= lfsr_reg;
                        valid <= 1; // Data valid after generation
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
                else if (enable && ready)
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
                else if (valid && ready) // Transition only if ready
                    next_state = GENERATE;
                else
                    next_state = GENERATE;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule