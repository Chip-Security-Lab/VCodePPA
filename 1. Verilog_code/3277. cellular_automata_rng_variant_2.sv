//SystemVerilog
module cellular_automata_rng (
    input wire clk,
    input wire rst,
    output wire [15:0] random_value
);
    reg [15:0] ca_state_reg;
    reg [15:0] ca_state_buf1;
    reg [15:0] ca_state_buf2;
    reg [15:0] next_state_reg;
    reg [15:0] next_state_buf;
    reg [3:0] i_reg;
    reg [3:0] i_buf;

    wire [15:0] next_state_wire;

    // Multi-stage buffer for ca_state to reduce fanout
    always @(posedge clk) begin
        if (rst) begin
            ca_state_reg <= 16'h8001;
            ca_state_buf1 <= 16'h8001;
            ca_state_buf2 <= 16'h8001;
        end else begin
            ca_state_reg <= next_state_reg;
            ca_state_buf1 <= ca_state_reg;
            ca_state_buf2 <= ca_state_buf1;
        end
    end

    // Buffer for next_state
    always @(posedge clk) begin
        if (rst) begin
            next_state_reg <= 16'h8001;
            next_state_buf <= 16'h8001;
        end else begin
            next_state_reg <= next_state_wire;
            next_state_buf <= next_state_reg;
        end
    end

    // Buffer for i (used in generate)
    always @(posedge clk) begin
        if (rst) begin
            i_reg <= 4'd0;
            i_buf <= 4'd0;
        end else begin
            i_reg <= i_reg + 1'b1;
            i_buf <= i_reg;
        end
    end

    // Rule 30 cellular automaton with buffered ca_state, optimized Boolean expressions
    genvar idx;
    generate
        for (idx = 0; idx < 16; idx = idx + 1) begin : rule30_gen
            if (idx == 0) begin
                // Original: ca_state_buf2[15] ^ (ca_state_buf2[0] | ca_state_buf2[1])
                // Simplified: (~ca_state_buf2[15] & (ca_state_buf2[0] | ca_state_buf2[1])) | (ca_state_buf2[15] & ~(ca_state_buf2[0] | ca_state_buf2[1]))
                assign next_state_wire[idx] = (~ca_state_buf2[15] & (ca_state_buf2[0] | ca_state_buf2[1])) | (ca_state_buf2[15] & ~ca_state_buf2[0] & ~ca_state_buf2[1]);
            end else if (idx == 15) begin
                // Original: ca_state_buf2[14] ^ (ca_state_buf2[15] | ca_state_buf2[0])
                // Simplified: (~ca_state_buf2[14] & (ca_state_buf2[15] | ca_state_buf2[0])) | (ca_state_buf2[14] & ~ca_state_buf2[15] & ~ca_state_buf2[0])
                assign next_state_wire[idx] = (~ca_state_buf2[14] & (ca_state_buf2[15] | ca_state_buf2[0])) | (ca_state_buf2[14] & ~ca_state_buf2[15] & ~ca_state_buf2[0]);
            end else begin
                // Original: ca_state_buf2[idx-1] ^ (ca_state_buf2[idx] | ca_state_buf2[idx+1])
                // Simplified: (~ca_state_buf2[idx-1] & (ca_state_buf2[idx] | ca_state_buf2[idx+1])) | (ca_state_buf2[idx-1] & ~ca_state_buf2[idx] & ~ca_state_buf2[idx+1])
                assign next_state_wire[idx] = (~ca_state_buf2[idx-1] & (ca_state_buf2[idx] | ca_state_buf2[idx+1])) | (ca_state_buf2[idx-1] & ~ca_state_buf2[idx] & ~ca_state_buf2[idx+1]);
            end
        end
    endgenerate

    assign random_value = ca_state_reg;

endmodule