module cam_valid_mask_pipeline #(parameter WIDTH=12, DEPTH=64)(
    input clk,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] data_in,
    input [DEPTH-1:0] valid_mask,
    output reg [DEPTH-1:0] match_lines
);
    reg [WIDTH-1:0] cam_table [0:DEPTH-1];
    reg [DEPTH-1:0] raw_matches_stage1, raw_matches_stage2;
    reg valid_stage1, valid_stage2;

    // Pipeline register for write operation
    always @(posedge clk) begin
        if (write_en) begin
            cam_table[write_addr] <= write_data;
        end
    end

    // Stage 1: Compare and generate raw matches
    always @(posedge clk) begin
        valid_stage1 <= 1'b1; // Indicate that stage 1 is valid
        for (integer j = 0; j < DEPTH; j = j + 1) begin
            if (valid_mask[j]) begin
                raw_matches_stage1[j] <= (cam_table[j] == data_in);
            end else begin
                raw_matches_stage1[j] <= 1'b0; // Invalid entry directly set to not match
            end
        end
    end

    // Stage 2: Pass the results to output
    always @(posedge clk) begin
        valid_stage2 <= valid_stage1; // Propagate valid signal
        raw_matches_stage2 <= raw_matches_stage1; // Pipeline register to hold matches
    end

    // Output the final matches
    always @(posedge clk) begin
        match_lines <= raw_matches_stage2; // Output the results from stage 2
    end
endmodule