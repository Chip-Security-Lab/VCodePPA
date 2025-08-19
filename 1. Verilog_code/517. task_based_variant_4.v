module task_based(
    input [3:0] in,
    output reg [1:0] out
);
    reg [3:0] sum_stage2;
    
    always @(*) begin
        // Optimized computation using simplified boolean expressions
        sum_stage2 = (in[0] ? in : 4'b0) + 
                    ((in[1] ? in : 4'b0) << 1) + 
                    ((in[2] ? in : 4'b0) << 2) + 
                    ((in[3] ? in : 4'b0) << 3);
        
        // Optimized output assignment
        out = {sum_stage2[3], sum_stage2[2] ^ sum_stage2[1] ^ sum_stage2[0]};
    end
endmodule