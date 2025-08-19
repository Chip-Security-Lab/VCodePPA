//SystemVerilog
module active_low_reset_comp #(parameter WIDTH = 4)(
    input clock, reset_n, enable,
    input [WIDTH-1:0][WIDTH-1:0] values, // Multiple values to compare
    output reg [$clog2(WIDTH)-1:0] highest_idx,
    output reg valid_result
);
    integer j;
    reg [WIDTH-1:0] current_max_val;
    reg [$clog2(WIDTH)-1:0] current_max_idx;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            highest_idx <= 0;
            valid_result <= 0;
        end else if (enable) begin
            current_max_val <= values[0];
            current_max_idx <= 0;

            // Use direct comparison which is optimized by synthesis tools
            for (j = 1; j < WIDTH; j = j + 1) begin
                if (values[j] > current_max_val) begin
                    current_max_val <= values[j];
                    current_max_idx <= j[$clog2(WIDTH)-1:0];
                end
            end
            highest_idx <= current_max_idx;
            valid_result <= 1;
        end
    end
endmodule