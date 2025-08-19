module DynamicWeightArbiter #(parameter DW=8) (
    input clk, rst,
    input [4*DW-1:0] dyn_weights, // 扁平化数组
    input [3:0] req,
    output reg [3:0] grant
);
reg [DW-1:0] acc_weights [0:3];
wire [DW-1:0] weight_array [0:3];
integer i;

// Extract individual weights
genvar g;
generate
    for (g = 0; g < 4; g = g + 1) begin: weight_extract
        assign weight_array[g] = dyn_weights[g*DW +: DW];
    end
endgenerate

always @(posedge clk) begin
    if(rst) begin
        for(i=0; i<4; i=i+1) 
            acc_weights[i] <= 0;
    end else begin
        for(i=0; i<4; i=i+1) 
            acc_weights[i] <= acc_weights[i] + weight_array[i];
            
        // Determine grant based on accumulated weights
        if (acc_weights[0] > acc_weights[1] && acc_weights[0] > acc_weights[2] && acc_weights[0] > acc_weights[3])
            grant <= 4'b0001 & req;
        else if (acc_weights[1] > acc_weights[0] && acc_weights[1] > acc_weights[2] && acc_weights[1] > acc_weights[3])
            grant <= 4'b0010 & req;
        else if (acc_weights[2] > acc_weights[0] && acc_weights[2] > acc_weights[1] && acc_weights[2] > acc_weights[3])
            grant <= 4'b0100 & req;
        else
            grant <= 4'b1000 & req;
    end
end
endmodule