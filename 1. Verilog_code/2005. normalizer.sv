module normalizer #(
    parameter W = 32
)(
    input [W-1:0] in,
    output [W-1:0] out,
    output [5:0] shift
);
    // Improved leading zero counter implementation
    reg [5:0] lzc;
    integer i;
    
    always @(*) begin
        lzc = 6'd0;
        
        // Priority encoder style implementation
        for (i = W-1; i >= 0; i = i - 1) begin
            if (in[i]) begin
                lzc = W - 1 - i;
                // Using normal exit condition instead of i = -1
                break;
            end
        end
        
        // Handle the case when no 1 is found
        if (i < 0 && in == 0)
            lzc = W;
    end
    
    assign shift = lzc;
    assign out = (lzc == W) ? in : (in << lzc);
endmodule