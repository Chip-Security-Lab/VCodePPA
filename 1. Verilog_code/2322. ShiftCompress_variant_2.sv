//SystemVerilog
module ShiftCompress #(N=4) (
    input [7:0] din,
    output reg [7:0] dout
);
    reg [7:0] shift_reg [0:N-1];
    wire [7:0] partial_sum [0:1];
    wire [7:0] conditional_result;
    
    // Initialize first register with input data
    always @(*) begin
        shift_reg[0] = din;
    end
    
    // Compute partial sums for conditional operations
    assign partial_sum[0] = shift_reg[0];
    assign partial_sum[1] = {shift_reg[0][6:0], 1'b0}; // Shifted version
    
    // Compute conditional result for first stage
    assign conditional_result = shift_reg[0][7] ? partial_sum[1] : partial_sum[0];
    
    // Handle shift operations for remaining registers
    genvar i;
    generate
        for(i=1; i<N; i=i+1) begin : shift_stage
            // For first stage, use the conditional_result wire
            if (i == 1) begin
                always @(*) begin
                    shift_reg[i] = conditional_result;
                end
            end
            // For subsequent stages, perform shift operation based on previous stage
            else begin
                wire [7:0] stage_partial_sum [0:1];
                wire [7:0] stage_conditional_result;
                
                assign stage_partial_sum[0] = shift_reg[i-1];
                assign stage_partial_sum[1] = {shift_reg[i-1][6:0], 1'b0}; // Shifted version
                assign stage_conditional_result = shift_reg[i-1][7] ? stage_partial_sum[1] : stage_partial_sum[0];
                
                always @(*) begin
                    shift_reg[i] = stage_conditional_result;
                end
            end
        end
    endgenerate
    
    // XOR compression stage
    integer j;
    always @(*) begin
        dout = 8'b0;
        for(j=0; j<N; j=j+1)
            dout = dout ^ shift_reg[j];
    end
endmodule