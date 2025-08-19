module enabled_comp_with_valid #(parameter WIDTH = 4)(
    input clock, reset, enable,
    input [WIDTH-1:0] in_values [0:WIDTH-1],
    output reg [$clog2(WIDTH)-1:0] highest_idx,
    output reg valid_result
);
    integer j;
    reg [WIDTH-1:0] max_value;
    
    always @(posedge clock) begin
        if (reset) begin
            highest_idx <= 0;
            valid_result <= 0;
            max_value <= 0;
        end else if (enable) begin
            max_value <= in_values[0];
            highest_idx <= 0;
            
            for (j = 1; j < WIDTH; j = j + 1)
                if (in_values[j] > max_value) begin
                    max_value <= in_values[j];
                    highest_idx <= j[$clog2(WIDTH)-1:0];
                end
            
            valid_result <= 1;
        end else begin
            valid_result <= 0;
        end
    end
endmodule