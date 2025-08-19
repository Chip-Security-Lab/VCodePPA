//SystemVerilog
module priority_arbiter_pipeline(
    input wire clk,
    input wire reset,
    input wire [3:0] requests,
    output reg [3:0] grant,
    output reg busy
);
    parameter [1:0] IDLE = 2'b00, GRANT0 = 2'b01, GRANT1 = 2'b10, GRANT2 = 2'b11;
    reg [1:0] state, next_state;
    reg [1:0] state_stage1, state_stage2;
    reg [3:0] grant_stage1, grant_stage2;
    reg busy_stage1, busy_stage2;
    reg valid_stage1, valid_stage2;

    // Next state logic - Combinational
    always @(*) begin
        if (requests == 4'b0000)
            next_state = IDLE;
        else if (requests[0])
            next_state = GRANT0;
        else if (requests[1])
            next_state = GRANT1;
        else if (requests[2])
            next_state = GRANT2;
        else
            next_state = 2'b11;
    end

    // Stage 1 state register
    always @(posedge clk or posedge reset) begin
        if (reset)
            state_stage1 <= IDLE;
        else
            state_stage1 <= next_state;
    end

    // Stage 1 grant logic
    always @(posedge clk or posedge reset) begin
        if (reset)
            grant_stage1 <= 4'b0000;
        else begin
            case (state_stage1)
                IDLE: grant_stage1 <= 4'b0000;
                GRANT0: grant_stage1 <= 4'b0001;
                GRANT1: grant_stage1 <= 4'b0010;
                GRANT2: grant_stage1 <= 4'b0100;
                default: grant_stage1 <= 4'b1000;
            endcase
        end
    end

    // Stage 1 busy logic
    always @(posedge clk or posedge reset) begin
        if (reset)
            busy_stage1 <= 1'b0;
        else
            busy_stage1 <= (state_stage1 != IDLE);
    end

    // Stage 1 valid logic
    always @(posedge clk or posedge reset) begin
        if (reset)
            valid_stage1 <= 1'b0;
        else
            valid_stage1 <= 1'b1;
    end

    // Stage 2 state register
    always @(posedge clk) begin
        if (valid_stage1)
            state_stage2 <= state_stage1;
    end

    // Stage 2 grant register
    always @(posedge clk) begin
        if (valid_stage1)
            grant_stage2 <= grant_stage1;
    end

    // Stage 2 busy register
    always @(posedge clk) begin
        if (valid_stage1)
            busy_stage2 <= busy_stage1;
    end

    // Stage 2 valid register
    always @(posedge clk) begin
        if (valid_stage1)
            valid_stage2 <= 1'b1;
    end

    // Final output registers
    always @(posedge clk) begin
        if (valid_stage2) begin
            grant <= grant_stage2;
            busy <= busy_stage2;
        end
    end

endmodule