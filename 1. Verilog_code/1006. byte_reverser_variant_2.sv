//SystemVerilog
module byte_reverser #(
    parameter BYTES = 4  // Default 32-bit word
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   reverse_en,
    input  wire [BYTES*8-1:0]     data_in,
    output reg  [BYTES*8-1:0]     data_out
);

    // Pipeline Stage 1: Input Latching
    reg [BYTES*8-1:0] stage1_data;
    reg               stage1_reverse_en;
    reg               stage1_valid;

    // Pipeline Stage 2: Byte Reverse or Pass-through
    reg [BYTES*8-1:0] stage2_data_reversed;
    reg [BYTES*8-1:0] stage2_data;
    reg               stage2_reverse_en;
    reg               stage2_valid;

    // Pipeline Stage 3: Output Register
    reg [BYTES*8-1:0] stage3_data_out;
    reg               stage3_valid;

    // Stage 1: Register input and control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data        <= {(BYTES*8){1'b0}};
            stage1_reverse_en  <= 1'b0;
            stage1_valid       <= 1'b0;
        end else begin
            stage1_data        <= data_in;
            stage1_reverse_en  <= reverse_en;
            stage1_valid       <= 1'b1;
        end
    end

    // Stage 2: Byte Reverse (optimized comparison logic)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data_reversed <= {(BYTES*8){1'b0}};
            stage2_data          <= {(BYTES*8){1'b0}};
            stage2_reverse_en    <= 1'b0;
            stage2_valid         <= 1'b0;
        end else begin
            stage2_data          <= stage1_data;
            stage2_reverse_en    <= stage1_reverse_en;
            stage2_valid         <= stage1_valid;

            // Optimized byte reversal using generate-for and range assignment
            if (stage1_reverse_en) begin : reverse_block
                integer b;
                for (b = 0; b < BYTES; b = b + 1) begin
                    stage2_data_reversed[b*8 +: 8] <= stage1_data[((BYTES-b-1)*8) +: 8];
                end
            end else begin
                stage2_data_reversed <= stage1_data;
            end
        end
    end

    // Stage 3: Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_data_out <= {(BYTES*8){1'b0}};
            stage3_valid    <= 1'b0;
        end else begin
            // Use range check for efficient selection
            stage3_data_out <= (stage2_reverse_en) ? stage2_data_reversed : stage2_data;
            stage3_valid    <= stage2_valid;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {(BYTES*8){1'b0}};
        end else if (stage3_valid) begin
            data_out <= stage3_data_out;
        end
    end

endmodule