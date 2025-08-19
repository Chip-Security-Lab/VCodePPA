//SystemVerilog
module seedable_rng (
    input wire clk,
    input wire rst_n,
    input wire load_seed,
    input wire [31:0] seed_value,
    output wire [31:0] random_data
);
    // One-hot encoded FSM states
    typedef enum logic [2:0] {
        STATE_IDLE    = 3'b001,
        STATE_LOAD    = 3'b010,
        STATE_SHIFT   = 3'b100
    } fsm_state_t;

    fsm_state_t current_state, next_state;

    reg [31:0] lfsr_state;
    wire feedback_bit;
    wire [31:0] lfsr_next_state;

    // Feedback bit calculation
    wire bit_31 = lfsr_state[31];
    wire bit_21 = lfsr_state[21];
    wire bit_1  = lfsr_state[1];
    wire bit_0  = lfsr_state[0];

    assign feedback_bit = bit_31 ^ bit_21 ^ bit_1 ^ bit_0;
    assign lfsr_next_state = {lfsr_state[30:0], feedback_bit};

    // FSM state transition
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM next state logic
    always_comb begin
        case (current_state)
            STATE_IDLE: begin
                if (load_seed)
                    next_state = STATE_LOAD;
                else
                    next_state = STATE_SHIFT;
            end
            STATE_LOAD: begin
                next_state = STATE_SHIFT;
            end
            STATE_SHIFT: begin
                if (load_seed)
                    next_state = STATE_LOAD;
                else
                    next_state = STATE_SHIFT;
            end
            default: next_state = STATE_IDLE;
        endcase
    end

    // LFSR state update logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state <= 32'h1;
        end else begin
            case (next_state)
                STATE_IDLE: begin
                    lfsr_state <= 32'h1;
                end
                STATE_LOAD: begin
                    lfsr_state <= seed_value;
                end
                STATE_SHIFT: begin
                    lfsr_state <= lfsr_next_state;
                end
                default: lfsr_state <= 32'h1;
            endcase
        end
    end

    assign random_data = lfsr_state;
endmodule