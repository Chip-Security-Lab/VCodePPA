//SystemVerilog
module MuxOneHot #(parameter W=4, N=8) (
    input [N-1:0] hot_sel,
    input [N-1:0][W-1:0] channels,
    output [W-1:0] selected
);

    // Intermediate signals for conditional sum approach
    reg [W-1:0] sum [N-1:0];
    reg [W-1:0] result;
    
    // Generate conditional sums for each channel
    always @(*) begin
        for (integer i = 0; i < N; i = i + 1) begin
            sum[i] = (hot_sel[i]) ? channels[i] : {W{1'b0}};
        end
    end
    
    // Sum reduction using conditional addition
    always @(*) begin
        result = sum[0];
        for (integer i = 1; i < N; i = i + 1) begin
            result = result + sum[i];
        end
    end
    
    // Output assignment
    assign selected = result;
endmodule