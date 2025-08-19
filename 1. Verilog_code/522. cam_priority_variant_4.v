module cam_clock_gated #(parameter WIDTH=8, DEPTH=32)(
    input clk,
    input rst_n,
    input search_en,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] match_flags,
    output reg valid_out
);

    // Pipeline registers
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    reg [WIDTH-1:0] data_in_stage1;
    reg [WIDTH-1:0] data_in_stage2;
    reg search_en_stage1;
    reg search_en_stage2;
    reg [DEPTH-1:0] match_flags_stage1;
    reg [DEPTH-1:0] match_flags_stage2;
    reg valid_stage1;
    reg valid_stage2;

    // Stage 1: Data input pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 0;
        end else begin
            data_in_stage1 <= data_in;
        end
    end

    // Stage 1: Search enable pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            search_en_stage1 <= 0;
        end else begin
            search_en_stage1 <= search_en;
        end
    end

    // Stage 1: Valid signal pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 0;
        end else begin
            valid_stage1 <= search_en;
        end
    end

    // Stage 1: Write operation
    always @(posedge clk) begin
        if (write_en) begin
            entries[write_addr] <= write_data;
        end
    end

    // Stage 2: Data pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage2 <= 0;
        end else begin
            data_in_stage2 <= data_in_stage1;
        end
    end

    // Stage 2: Search enable pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            search_en_stage2 <= 0;
        end else begin
            search_en_stage2 <= search_en_stage1;
        end
    end

    // Stage 2: Valid signal pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 2: Comparison logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_flags_stage1 <= 0;
        end else if (search_en_stage1) begin
            for (integer i = 0; i < DEPTH; i = i + 1)
                match_flags_stage1[i] <= (entries[i] == data_in_stage1);
        end
    end

    // Stage 3: Output pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_flags <= 0;
            valid_out <= 0;
        end else begin
            match_flags <= match_flags_stage1;
            valid_out <= valid_stage2;
        end
    end

endmodule