//SystemVerilog
module cellular_automata_rng_pipeline (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output wire [15:0] random_value,
    output wire        valid
);

    reg  [15:0] ca_state_stage1;
    reg         valid_stage1;
    reg  [15:0] next_state_stage2;
    reg  [15:0] ca_state_stage2;
    reg         valid_stage2;
    reg  [15:0] ca_state_stage3;
    reg         valid_stage3;

    always @(posedge clk) begin
        if (rst) begin
            ca_state_stage1    <= 16'h8001;
            valid_stage1       <= 1'b0;

            ca_state_stage2    <= 16'h8001;
            next_state_stage2  <= 16'h0;
            valid_stage2       <= 1'b0;

            ca_state_stage3    <= 16'h8001;
            valid_stage3       <= 1'b0;
        end else begin
            // Stage 1
            if (start) begin
                ca_state_stage1 <= ca_state_stage1;
                valid_stage1    <= 1'b1;
            end else if (valid_stage2 && !start) begin
                ca_state_stage1 <= ca_state_stage2;
                valid_stage1    <= valid_stage2;
            end

            // Stage 2
            ca_state_stage2   <= ca_state_stage1;
            valid_stage2      <= valid_stage1;
            // Boolean simplification:
            // x ^ (x | y) = ~x & y
            // next_state_stage2[0]  <= ca_state_stage1[15] ^ (ca_state_stage1[0]  | ca_state_stage1[1]);
            next_state_stage2[0]  <= (~ca_state_stage1[15]) & (ca_state_stage1[0] | ca_state_stage1[1]);
            // next_state_stage2[15] <= ca_state_stage1[14] ^ (ca_state_stage1[15] | ca_state_stage1[0]);
            next_state_stage2[15] <= (~ca_state_stage1[14]) & (ca_state_stage1[15] | ca_state_stage1[0]);
            // next_state_stage2[14:1] <= ca_state_stage1[13:0] ^ (ca_state_stage1[14:1] | ca_state_stage1[15:2]);
            next_state_stage2[14:1] <= (~ca_state_stage1[13:0]) & (ca_state_stage1[14:1] | ca_state_stage1[15:2]);

            // Stage 3
            ca_state_stage3 <= next_state_stage2;
            valid_stage3    <= valid_stage2;
        end
    end

    assign random_value = ca_state_stage3;
    assign valid        = valid_stage3;

endmodule