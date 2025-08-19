//SystemVerilog
// IEEE 1364-2005
module CascadeShift #(parameter STAGES=2, WIDTH=8) (
    input clk, cascade_en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    // Changed from array to individual registers for better timing control
    reg [WIDTH-1:0] stage [0:STAGES-2];
    
    always @(posedge clk) begin
        if (cascade_en) begin
            // Retimed pipeline registers - pushing registers backward through logic
            for (int i = 0; i < STAGES-1; i = i + 1) begin
                if (i == 0)
                    stage[i] <= din;
                else
                    stage[i] <= stage[i-1];
            end
            
            // Output register - moved from assignment to sequential block
            dout <= (STAGES > 1) ? stage[STAGES-2] : din;
        end
    end
endmodule