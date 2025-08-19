//SystemVerilog
module byte_reverser #(
    parameter BYTES = 4  // Default 32-bit word
)(
    input wire clk,
    input wire rst_n,
    input wire reverse_en,
    input wire [BYTES*8-1:0] data_in,
    output reg [BYTES*8-1:0] data_out
);

    // Buffer data_in and reverse_en for timing and fanout optimization
    reg [BYTES*8-1:0] data_in_reg;
    reg reverse_en_reg;

    // High fanout buffer for idx: multi-level buffering for balanced fanout
    reg [2:0] idx_buf_stage1 [0:BYTES-1];
    reg [2:0] idx_buf_stage2 [0:BYTES-1];

    reg [BYTES*8-1:0] reversed_data;

    integer i;

    // Buffer data_in and reverse_en for timing and fanout optimization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= {(BYTES*8){1'b0}};
            reverse_en_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            reverse_en_reg <= reverse_en;
        end
    end

    // First stage buffer for idx
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < BYTES; i = i + 1) begin
                idx_buf_stage1[i] <= 3'd0;
            end
        end else begin
            for (i = 0; i < BYTES; i = i + 1) begin
                idx_buf_stage1[i] <= i[2:0];
            end
        end
    end

    // Second stage buffer for idx
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < BYTES; i = i + 1) begin
                idx_buf_stage2[i] <= 3'd0;
            end
        end else begin
            for (i = 0; i < BYTES; i = i + 1) begin
                idx_buf_stage2[i] <= idx_buf_stage1[i];
            end
        end
    end

    // Efficient byte reversal using generate block and buffered idx
    genvar idx;
    generate
        for (idx = 0; idx < BYTES; idx = idx + 1) begin : gen_byte_reverse
            always @(*) begin
                reversed_data[idx*8 +: 8] = data_in_reg[(BYTES-1-idx_buf_stage2[idx])*8 +: 8];
            end
        end
    endgenerate

    // Output register with optimized comparison logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {(BYTES*8){1'b0}};
        end else if (reverse_en_reg) begin
            data_out <= reversed_data;
        end else begin
            data_out <= data_in_reg;
        end
    end

endmodule