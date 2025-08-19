//SystemVerilog
module enabled_comp_with_valid #(parameter WIDTH = 4)(
    input clock, reset, enable,
    input [WIDTH-1:0] in_values [0:WIDTH-1],
    output reg [$clog2(WIDTH)-1:0] highest_idx,
    output reg valid_result
);
    reg [WIDTH-1:0] max_value;
    reg [WIDTH-1:0] temp_value;
    reg [$clog2(WIDTH)-1:0] temp_idx;
    
    // Buffer registers for high fanout signals
    reg [WIDTH-1:0] in_values_buf [0:WIDTH-1];
    reg [WIDTH-1:0] temp_value_buf;
    reg [$clog2(WIDTH)-1:0] temp_idx_buf;
    reg [WIDTH-1:0] i_buf;
    
    // Conditional sum signals
    reg [WIDTH-1:0] sum_value;
    reg [$clog2(WIDTH)-1:0] sum_idx;
    reg [WIDTH-1:0] carry_value;
    reg [$clog2(WIDTH)-1:0] carry_idx;
    
    always @(posedge clock) begin
        if (reset) begin
            highest_idx <= 0;
            valid_result <= 0;
            max_value <= 0;
            temp_value_buf <= 0;
            temp_idx_buf <= 0;
            i_buf <= 0;
            sum_value <= 0;
            sum_idx <= 0;
            carry_value <= 0;
            carry_idx <= 0;
        end else if (enable) begin
            // Buffer input values
            for (int j = 0; j < WIDTH; j = j + 1) begin
                in_values_buf[j] <= in_values[j];
            end
            
            // Initialize sum and carry
            sum_value <= in_values_buf[0];
            sum_idx <= 0;
            carry_value <= 0;
            carry_idx <= 0;
            
            // Conditional sum comparison
            for (int i = 1; i < WIDTH; i = i + 1) begin
                i_buf <= i;
                // Calculate sum and carry
                if (in_values_buf[i_buf] > sum_value) begin
                    carry_value <= in_values_buf[i_buf];
                    carry_idx <= i_buf[$clog2(WIDTH)-1:0];
                end else begin
                    carry_value <= sum_value;
                    carry_idx <= sum_idx;
                end
                // Update sum
                sum_value <= carry_value;
                sum_idx <= carry_idx;
            end
            
            // Final stage
            max_value <= sum_value;
            highest_idx <= sum_idx;
            valid_result <= 1;
        end else begin
            valid_result <= 0;
        end
    end
endmodule