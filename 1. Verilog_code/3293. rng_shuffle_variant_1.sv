//SystemVerilog
module rng_shuffle_13(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  rand_o
);
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        RESET = 2'b01,
        ENABLE= 2'b10
    } state_t;

    // State pipelining
    state_t next_state_stage1, next_state_stage2;
    state_t current_state_stage1, current_state_stage2;

    // Pipeline registers for random output
    reg [7:0] rand_stage1;
    reg [7:0] rand_stage2;

    // Pipeline intermediate signals
    reg [7:0] shuffle_stage1;
    reg [7:0] shuffle_stage2;
    reg [7:0] xor_stage1;
    reg [7:0] xor_stage2;

    // Stage 1: State transition logic
    always @(*) begin
        if(rst)
            next_state_stage1 = RESET;
        else if(en)
            next_state_stage1 = ENABLE;
        else
            next_state_stage1 = IDLE;
    end

    // Stage 2: State register pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state_stage1 <= RESET;
            current_state_stage2 <= RESET;
            next_state_stage2 <= RESET;
        end else begin
            current_state_stage1 <= next_state_stage1;
            next_state_stage2 <= current_state_stage1;
            current_state_stage2 <= next_state_stage2;
        end
    end

    // Stage 1: Latch input or keep previous value
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rand_stage1 <= 8'hC3;
        end else begin
            rand_stage1 <= rand_o;
        end
    end

    // Stage 2: Shuffle (swap) operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shuffle_stage1 <= 8'hC3;
        end else begin
            shuffle_stage1 <= {rand_stage1[3:0], rand_stage1[7:4]};
        end
    end

    // Stage 3: XOR operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            xor_stage1 <= 8'hC3;
        end else begin
            xor_stage1 <= shuffle_stage1 ^ {4'h9, 4'h6};
        end
    end

    // Stage 4: Final output register based on pipelined state
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rand_stage2 <= 8'hC3;
        end else begin
            case(current_state_stage2)
                RESET:  rand_stage2 <= 8'hC3;
                ENABLE: rand_stage2 <= xor_stage1;
                IDLE:   rand_stage2 <= rand_stage2;
                default:rand_stage2 <= rand_stage2;
            endcase
        end
    end

    // Output assignment
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rand_o <= 8'hC3;
        end else begin
            rand_o <= rand_stage2;
        end
    end

endmodule