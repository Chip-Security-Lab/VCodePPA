module pipeline_buffer (
    input wire clk,
    input wire [15:0] data_in,
    input wire valid_in,
    output reg [15:0] data_out,
    output reg valid_out
);
    reg [15:0] stage1, stage2;
    reg valid1, valid2;
    
    always @(posedge clk) begin
        // Stage 1
        stage1 <= data_in;
        valid1 <= valid_in;
        
        // Stage 2
        stage2 <= stage1;
        valid2 <= valid1;
        
        // Output stage
        data_out <= stage2;
        valid_out <= valid2;
    end
endmodule