//SystemVerilog
module normalizer #(parameter WIDTH=16)(
    input wire [WIDTH-1:0] in_data,
    output reg [WIDTH-1:0] normalized_data,
    output reg [$clog2(WIDTH)-1:0] shift_count
);

    integer idx;
    reg leading_one_detected;
    reg [$clog2(WIDTH)-1:0] leading_one_index;
    reg [$clog2(WIDTH)-1:0] width_m1;
    reg [$clog2(WIDTH)-1:0] neg_leading_one_index;
    reg [$clog2(WIDTH)-1:0] shift_count_sum;

    always @* begin
        leading_one_detected = 1'b0;
        leading_one_index = {($clog2(WIDTH)){1'b0}};
        width_m1 = WIDTH[$clog2(WIDTH)-1:0] - 1'b1;

        idx = WIDTH-1;
        while (idx >= 0) begin
            if (!leading_one_detected && in_data[idx]) begin
                leading_one_detected = 1'b1;
                leading_one_index = idx[$clog2(WIDTH)-1:0];
            end
            idx = idx - 1;
        end

        // 8-bit two's complement negation of leading_one_index
        neg_leading_one_index = (~leading_one_index) + {{($clog2(WIDTH)-1){1'b0}}, 1'b1};

        // Compute shift_count using two's complement addition for subtraction
        shift_count_sum = width_m1 + neg_leading_one_index;
        shift_count = shift_count_sum;

        normalized_data = in_data << shift_count;
    end

endmodule