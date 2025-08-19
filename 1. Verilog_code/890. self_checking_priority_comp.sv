module self_checking_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_index,
    output reg valid,
    output reg error
);
    reg [$clog2(WIDTH)-1:0] expected_priority;
    reg [WIDTH-1:0] priority_mask;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_index <= 0;
            valid <= 0;
            error <= 0;
            expected_priority <= 0;
            priority_mask <= 0;
        end else begin
            valid <= |data_in;
            
            // Compute expected priority
            expected_priority <= 0;
            for (integer i = WIDTH-1; i >= 0; i = i - 1)
                if (data_in[i]) expected_priority <= i[$clog2(WIDTH)-1:0];
            
            // Generate one-hot priority mask for verification
            priority_mask <= 0;
            priority_mask[expected_priority] <= |data_in;
            
            // Assign output
            priority_index <= expected_priority;
            
            // Self-check: verify one-hot property
            error <= valid && ~(|data_in[expected_priority]);
        end
    end
endmodule