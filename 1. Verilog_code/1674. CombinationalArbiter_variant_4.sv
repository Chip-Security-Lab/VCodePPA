//SystemVerilog
module CombinationalArbiter #(parameter N=4) (
    input [N-1:0] req,
    output [N-1:0] grant
);

    // Conditional sum subtractor implementation
    wire [N-1:0] req_neg;
    wire [N-1:0] sum_0, sum_1;
    wire [N-1:0] carry_0, carry_1;
    wire [N-1:0] final_sum;
    
    // Generate negative of request
    assign req_neg = ~req;
    
    // Generate conditional sums and carries
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : sub_loop
            // Sum and carry for carry-in = 0
            assign sum_0[i] = req[i] ^ req_neg[i];
            assign carry_0[i] = req[i] & req_neg[i];
            
            // Sum and carry for carry-in = 1
            assign sum_1[i] = req[i] ^ ~req_neg[i];
            assign carry_1[i] = req[i] | req_neg[i];
        end
    endgenerate
    
    // Select final sum based on carry chain
    assign final_sum[0] = sum_0[0];
    assign final_sum[1] = carry_0[0] ? sum_1[1] : sum_0[1];
    assign final_sum[2] = (carry_0[0] & carry_1[1]) ? sum_1[2] : 
                         (carry_0[0] | carry_0[1]) ? sum_1[2] : sum_0[2];
    assign final_sum[3] = (carry_0[0] & carry_1[1] & carry_1[2]) ? sum_1[3] :
                         ((carry_0[0] & carry_1[1]) | (carry_0[0] & carry_0[1]) | carry_0[2]) ? sum_1[3] : sum_0[3];
    
    // Compute grant signals
    assign grant = req & (req ^ final_sum);

endmodule