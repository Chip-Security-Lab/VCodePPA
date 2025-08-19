//SystemVerilog
module equality_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_a, data_b,
    output reg [$clog2(WIDTH)-1:0] priority_idx,
    output reg equal, a_greater, b_greater
);

    reg [WIDTH-1:0] data_a_r;
    reg [WIDTH-1:0] data_b_r;

    reg [WIDTH-1:0] diff;
    reg [$clog2(WIDTH)-1:0] temp_priority_idx;
    reg any_diff;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_r <= 0;
            data_b_r <= 0;
        end else begin
            data_a_r <= data_a;
            data_b_r <= data_b;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            equal <= 0;
            a_greater <= 0;
            b_greater <= 0;
            priority_idx <= 0;
        end else begin
            equal <= (data_a_r == data_b_r);
            a_greater <= (data_a_r > data_b_r);
            b_greater <= (data_a_r < data_b_r);

            // Calculate bit-wise difference
            diff = data_a_r ^ data_b_r;

            // Find the most significant bit of the difference and check if any difference exists
            temp_priority_idx = 0;
            any_diff = 0;
            for (integer i = 0; i < WIDTH; i = i + 1) begin
                 if (diff[i]) begin
                    temp_priority_idx = i[$clog2(WIDTH)-1:0];
                    any_diff = 1;
                 end
            end

            // If there is a difference, update priority_idx
            if (any_diff) begin
                priority_idx <= temp_priority_idx;
            end else begin
                priority_idx <= 0; // Or some default value when equal
            end
        end
    end
endmodule