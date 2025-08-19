//SystemVerilog
module active_low_reset_comp #(parameter WIDTH = 4)(
    input clock, reset_n, enable,
    input [WIDTH-1:0][WIDTH-1:0] values, // Multiple values to compare
    output reg [$clog2(WIDTH)-1:0] highest_idx,
    output reg valid_result
);
    reg [WIDTH-1:0] current_max_val;
    reg [$clog2(WIDTH)-1:0] current_max_idx;
    integer i;

    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            highest_idx <= 0;
            valid_result <= 0;
        end else if (enable) begin
            current_max_val = values[0];
            current_max_idx = 0;

            for (i = 1; i < WIDTH; i = i + 1) begin
                if (values[i] > current_max_val) begin
                    current_max_val = values[i];
                    current_max_idx = i;
                end
            end
            highest_idx <= current_max_idx[$clog2(WIDTH)-1:0];
            valid_result <= 1;
        end
        // else if (!enable) outputs hold previous values
    end
endmodule