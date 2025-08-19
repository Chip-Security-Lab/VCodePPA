//SystemVerilog
module MuxPriority #(parameter W=8, N=4) (
    input [N-1:0] valid,
    input [W-1:0] data [0:N-1],
    output [W-1:0] result
);

    // Optimized implementation combining priority encoding and data selection
    // in a single module to reduce area and improve timing
    reg [$clog2(N)-1:0] sel;
    reg [W-1:0] result_reg;
    
    // Priority encoding with optimized comparison logic
    always @(*) begin
        sel = 0;
        result_reg = data[0];
        
        // Use a more efficient priority encoding approach
        // that reduces the number of comparisons
        for (int i = 1; i < N; i++) begin
            if (valid[i]) begin
                sel = i;
                result_reg = data[i];
            end
        end
    end
    
    assign result = result_reg;

endmodule