module cam_clock_gated_pipeline #(parameter WIDTH=8, DEPTH=32)(
    input clk,
    input search_en,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] match_flags
);
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    
    // Pipeline registers
    reg [WIDTH-1:0] write_data_stage1, write_data_stage2;
    reg [$clog2(DEPTH)-1:0] write_addr_stage1, write_addr_stage2;
    reg search_en_stage1, search_en_stage2, search_en_stage3;
    reg [WIDTH-1:0] data_in_stage1, data_in_stage2, data_in_stage3;
    
    // Valid signals for pipeline stages
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // Intermediate match results for segmented matching
    reg [DEPTH/2-1:0] match_flags_stage3_lower;
    reg [DEPTH/2-1:0] match_flags_stage3_upper;

    // Write logic with pipeline
    always @(posedge clk) begin
        if (write_en) begin
            entries[write_addr] <= write_data;
        end
    end

    // Stage 1: Capture inputs
    always @(posedge clk) begin
        if (search_en) begin
            write_data_stage1 <= write_data;
            write_addr_stage1 <= write_addr;
            search_en_stage1 <= search_en;
            data_in_stage1 <= data_in;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Pass through pipeline registers
    always @(posedge clk) begin
        write_data_stage2 <= write_data_stage1;
        write_addr_stage2 <= write_addr_stage1;
        search_en_stage2 <= search_en_stage1;
        data_in_stage2 <= data_in_stage1;
        valid_stage2 <= valid_stage1;
    end

    // Stage 3: Split match logic into two parts (lower half)
    integer i;
    always @(posedge clk) begin
        if (valid_stage2) begin
            for (i = 0; i < DEPTH/2; i = i + 1) begin
                match_flags_stage3_lower[i] <= (entries[i] == data_in_stage2);
            end
            search_en_stage3 <= search_en_stage2;
            data_in_stage3 <= data_in_stage2;
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    // Stage 3: Split match logic into two parts (upper half) - runs in parallel with lower half
    integer j;
    always @(posedge clk) begin
        if (valid_stage2) begin
            for (j = DEPTH/2; j < DEPTH; j = j + 1) begin
                match_flags_stage3_upper[j-DEPTH/2] <= (entries[j] == data_in_stage2);
            end
        end
    end

    // Stage 4: Combine the match results
    always @(posedge clk) begin
        if (valid_stage3) begin
            match_flags[0 +: DEPTH/2] <= match_flags_stage3_lower;
            match_flags[DEPTH/2 +: DEPTH/2] <= match_flags_stage3_upper;
            valid_stage4 <= 1'b1;
        end else begin
            valid_stage4 <= 1'b0;
        end
    end

    // Reset logic
    always @(posedge clk) begin
        if (!search_en) begin
            match_flags <= 0;
        end
    end
endmodule