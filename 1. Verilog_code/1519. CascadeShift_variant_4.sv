//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module CascadeShift #(parameter STAGES=3, WIDTH=8) (
    input clk, cascade_en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    // Input processing stage with pipelined structure
    wire [WIDTH-1:0] din_processed_part1;
    reg [WIDTH-1:0] din_processed;
    
    // Split the potentially complex input processing into two pipeline stages
    assign din_processed_part1 = din;
    
    always @(posedge clk) begin
        // Register the intermediate result to break long combinational path
        din_processed <= din_processed_part1;
    end
    
    // Cascade shift registers with optimized pipeline structure
    reg [WIDTH-1:0] stage [0:STAGES-2];
    integer i;
    
    always @(posedge clk) begin
        if (cascade_en) begin
            // First stage register now uses the pipelined input processing result
            stage[0] <= din_processed;
            
            // Middle stages with parallelized processing
            for(i=1; i<STAGES-1; i=i+1)
                stage[i] <= stage[i-1];
            
            // Final stage to output register
            dout <= (STAGES > 1) ? stage[STAGES-2] : din_processed;
        end
    end
endmodule