//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module CascadeShift #(parameter STAGES=3, WIDTH=8) (
    input clk, cascade_en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    // Moved registers to optimize timing paths
    reg [WIDTH-1:0] stage [0:STAGES-2];
    
    always @(posedge clk) begin
        if (cascade_en) begin
            // Pull-back register technique
            // Last register moved to output
            if (STAGES > 1) begin
                dout <= stage[STAGES-2];
            end
            else begin
                dout <= din;
            end
            
            // First register receives input
            if (STAGES > 1) begin
                stage[0] <= din;
                
                // Intermediate stages
                for(integer i=1; i<STAGES-1; i=i+1)
                    stage[i] <= stage[i-1];
            end
        end
    end
endmodule