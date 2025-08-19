//SystemVerilog
module equality_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_a, data_b,
    output reg [$clog2(WIDTH)-1:0] priority_idx,
    output reg equal, a_greater, b_greater
);

    reg [WIDTH-1:0] bit_greater_a; // Intermediate signal for bit-by-bit comparison (a > b)
    reg [$clog2(WIDTH)-1:0] highest_diff_idx_reg; // Register to hold the highest differing index
    reg equal_reg; // Register for equal flag
    reg a_greater_reg; // Register for a_greater flag
    reg b_greater_reg; // Register for b_greater flag

    // Reset and sequential logic for priority index
    // Finds the index of the most significant bit where data_a and data_b differ
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            highest_diff_idx_reg <= 0;
        end else begin
            highest_diff_idx_reg <= 0; // Default to 0
            for (integer j = WIDTH-1; j >= 0; j = j - 1) begin
                if (data_a[j] != data_b[j]) begin
                    highest_diff_idx_reg <= j[$clog2(WIDTH)-1:0];
                end
            end
        end
    end

    // Sequential logic for bit-by-bit comparison (a > b)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_greater_a <= 0;
        end else begin
            for (integer i = 0; i < WIDTH; i = i + 1) begin
                bit_greater_a[i] <= (data_a[i] > data_b[i]);
            end
        end
    end

    // Sequential logic for comparison flags
    // Determines if a > b, b > a, or a == b based on intermediate results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            equal_reg <= 0;
            a_greater_reg <= 0;
            b_greater_reg <= 0;
        end else begin
            equal_reg <= (data_a == data_b);
            a_greater_reg <= (|bit_greater_a) && !(data_a == data_b);
            b_greater_reg <= !(|bit_greater_a) && !(data_a == data_b);
        end
    end

    // Assign outputs from registered values
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_idx <= 0;
            equal <= 0;
            a_greater <= 0;
            b_greater <= 0;
        end else begin
            priority_idx <= highest_diff_idx_reg;
            equal <= equal_reg;
            a_greater <= a_greater_reg;
            b_greater <= b_greater_reg;
        end
    end

endmodule