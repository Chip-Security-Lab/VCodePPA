module active_low_reset_comp #(parameter WIDTH = 4)(
    input clock, reset_n, enable,
    input [WIDTH-1:0][WIDTH-1:0] values, // Multiple values to compare
    output reg [$clog2(WIDTH)-1:0] highest_idx,
    output reg valid_result
);
    integer j;
    reg [WIDTH-1:0] temp_val;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            highest_idx <= 0;
            valid_result <= 0;
        end else if (enable) begin
            temp_val = values[0];
            highest_idx <= 0;
            
            for (j = 1; j < WIDTH; j = j + 1) begin
                if (values[j] > temp_val) begin
                    temp_val = values[j];
                    highest_idx <= j[$clog2(WIDTH)-1:0];
                end
            end
            valid_result <= 1;
        end
    end
endmodule