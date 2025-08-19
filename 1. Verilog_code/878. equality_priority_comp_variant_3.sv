//SystemVerilog
module equality_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_a, data_b,
    output reg [$clog2(WIDTH)-1:0] priority_idx,
    output reg equal, a_greater, b_greater
);

    reg [WIDTH-1:0] data_a_reg, data_b_reg;
    reg [WIDTH-1:0] diff_bits;
    reg [$clog2(WIDTH)-1:0] priority_idx_comb;
    reg equal_comb, a_greater_comb, b_greater_comb;


    // Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_reg <= 0;
            data_b_reg <= 0;
        end else begin
            data_a_reg <= data_a;
            data_b_reg <= data_b;
        end
    end

    // Combinational logic for difference and comparison flags
    always @(*) begin
        diff_bits = data_a_reg ^ data_b_reg; // Find bits that are different

        // Determine highest priority difference using a priority encoder like structure
        priority_idx_comb = 0; // Default
        for (integer j = WIDTH-1; j >= 0; j = j - 1) begin
            if (diff_bits[j]) begin
                priority_idx_comb = j[$clog2(WIDTH)-1:0];
            end
        end

        // Determine comparison flags
        equal_comb = (diff_bits == 0);
        a_greater_comb = 0;
        b_greater_comb = 0;

        if (!equal_comb) begin
            if (data_a_reg[priority_idx_comb] > data_b_reg[priority_idx_comb]) begin
                a_greater_comb = 1;
            end else begin
                b_greater_comb = 1;
            end
        end
    end

    // Sequential logic for outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_idx <= 0;
            equal <= 0;
            a_greater <= 0;
            b_greater <= 0;
        end else begin
            priority_idx <= priority_idx_comb;
            equal <= equal_comb;
            a_greater <= a_greater_comb;
            b_greater <= b_greater_comb;
        end
    end

endmodule