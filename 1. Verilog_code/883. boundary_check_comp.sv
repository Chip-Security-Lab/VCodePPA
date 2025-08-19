module boundary_check_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] upper_bound, lower_bound,
    output reg [$clog2(WIDTH)-1:0] priority_pos,
    output reg in_bounds, valid
);
    reg [WIDTH-1:0] masked_data;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_pos <= 0;
            in_bounds <= 0;
            valid <= 0;
        end else begin
            // Check if data is within bounds
            in_bounds <= (data >= lower_bound) && (data <= upper_bound);
            
            // Mask data if outside bounds
            masked_data <= in_bounds ? data : 0;
            
            // Determine highest priority bit
            valid <= |masked_data;
            priority_pos <= 0;
            for (integer i = WIDTH-1; i >= 0; i = i - 1)
                if (masked_data[i]) priority_pos <= i[$clog2(WIDTH)-1:0];
        end
    end
endmodule