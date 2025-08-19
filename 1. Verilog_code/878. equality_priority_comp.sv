module equality_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_a, data_b,
    output reg [$clog2(WIDTH)-1:0] priority_idx,
    output reg equal, a_greater, b_greater
);
    reg [WIDTH-1:0] comp_result;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_idx <= 0;
            equal <= 0;
            a_greater <= 0;
            b_greater <= 0;
        end else begin
            // Generate bit-by-bit comparison
            for (integer i = 0; i < WIDTH; i = i + 1)
                comp_result[i] <= (data_a[i] > data_b[i]);
                
            // Find highest priority difference
            priority_idx <= 0;
            for (integer j = WIDTH-1; j >= 0; j = j - 1)
                if (data_a[j] != data_b[j]) 
                    priority_idx <= j[$clog2(WIDTH)-1:0];
            
            // Set comparison flags
            equal <= (data_a == data_b);
            a_greater <= |comp_result && !equal;
            b_greater <= !(|comp_result) && !equal;
        end
    end
endmodule