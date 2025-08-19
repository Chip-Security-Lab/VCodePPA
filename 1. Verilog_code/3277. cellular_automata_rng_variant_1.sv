//SystemVerilog
module cellular_automata_rng (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output wire [15:0] random_value,
    output wire        valid
);
    // Stage 1: Fetch current state and compute neighbors
    reg  [15:0] ca_state_stage1;
    reg         valid_stage1;

    // Stage 2: Calculate next_state bits (Rule 30)
    reg  [15:0] left_neighbors_stage2;
    reg  [15:0] center_stage2;
    reg  [15:0] right_neighbors_stage2;
    reg         valid_stage2;

    // Stage 3: XOR and OR operations for Rule 30, register next_state
    reg  [15:0] next_state_stage3;
    reg         valid_stage3;

    // Stage 4: Update CA state and output
    reg  [15:0] ca_state_stage4;
    reg         valid_stage4;

    // Pipeline flush logic
    wire pipeline_flush = rst;

    // Stage 1: Latch CA state
    always @(posedge clk) begin
        if (pipeline_flush) begin
            ca_state_stage1 <= 16'h8001;
            valid_stage1    <= 1'b0;
        end else if (start) begin
            ca_state_stage1 <= ca_state_stage4;
            valid_stage1    <= 1'b1;
        end else begin
            valid_stage1    <= 1'b0;
        end
    end

    // Stage 2: Compute neighbors for Rule 30
    always @(posedge clk) begin
        if (pipeline_flush) begin
            left_neighbors_stage2   <= 16'b0;
            center_stage2           <= 16'b0;
            right_neighbors_stage2  <= 16'b0;
            valid_stage2            <= 1'b0;
        end else begin
            left_neighbors_stage2   <= {ca_state_stage1[14:0], ca_state_stage1[15]};
            center_stage2           <= ca_state_stage1;
            right_neighbors_stage2  <= {ca_state_stage1[0], ca_state_stage1[15:1]};
            valid_stage2            <= valid_stage1;
        end
    end

    // Stage 3: Apply Rule 30 logic (Unrolled loop)
    always @(posedge clk) begin
        if (pipeline_flush) begin
            next_state_stage3 <= 16'b0;
            valid_stage3      <= 1'b0;
        end else begin
            next_state_stage3[0]  <= left_neighbors_stage2[0]  ^ (center_stage2[0]  | right_neighbors_stage2[0]);
            next_state_stage3[1]  <= left_neighbors_stage2[1]  ^ (center_stage2[1]  | right_neighbors_stage2[1]);
            next_state_stage3[2]  <= left_neighbors_stage2[2]  ^ (center_stage2[2]  | right_neighbors_stage2[2]);
            next_state_stage3[3]  <= left_neighbors_stage2[3]  ^ (center_stage2[3]  | right_neighbors_stage2[3]);
            next_state_stage3[4]  <= left_neighbors_stage2[4]  ^ (center_stage2[4]  | right_neighbors_stage2[4]);
            next_state_stage3[5]  <= left_neighbors_stage2[5]  ^ (center_stage2[5]  | right_neighbors_stage2[5]);
            next_state_stage3[6]  <= left_neighbors_stage2[6]  ^ (center_stage2[6]  | right_neighbors_stage2[6]);
            next_state_stage3[7]  <= left_neighbors_stage2[7]  ^ (center_stage2[7]  | right_neighbors_stage2[7]);
            next_state_stage3[8]  <= left_neighbors_stage2[8]  ^ (center_stage2[8]  | right_neighbors_stage2[8]);
            next_state_stage3[9]  <= left_neighbors_stage2[9]  ^ (center_stage2[9]  | right_neighbors_stage2[9]);
            next_state_stage3[10] <= left_neighbors_stage2[10] ^ (center_stage2[10] | right_neighbors_stage2[10]);
            next_state_stage3[11] <= left_neighbors_stage2[11] ^ (center_stage2[11] | right_neighbors_stage2[11]);
            next_state_stage3[12] <= left_neighbors_stage2[12] ^ (center_stage2[12] | right_neighbors_stage2[12]);
            next_state_stage3[13] <= left_neighbors_stage2[13] ^ (center_stage2[13] | right_neighbors_stage2[13]);
            next_state_stage3[14] <= left_neighbors_stage2[14] ^ (center_stage2[14] | right_neighbors_stage2[14]);
            next_state_stage3[15] <= left_neighbors_stage2[15] ^ (center_stage2[15] | right_neighbors_stage2[15]);
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Register output and new CA state
    always @(posedge clk) begin
        if (pipeline_flush) begin
            ca_state_stage4 <= 16'h8001;
            valid_stage4    <= 1'b0;
        end else begin
            ca_state_stage4 <= next_state_stage3;
            valid_stage4    <= valid_stage3;
        end
    end

    assign random_value = ca_state_stage4;
    assign valid        = valid_stage4;

endmodule