module pipeline_bridge #(parameter DWIDTH=32) (
    input clk, rst_n,
    input [DWIDTH-1:0] in_data,
    input in_valid,
    output reg in_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    input out_ready
);
    reg [DWIDTH-1:0] stage1_data, stage2_data;
    reg stage1_valid, stage2_valid;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            stage1_valid <= 0; stage2_valid <= 0; out_valid <= 0;
            in_ready <= 1;
        end else begin
            // Stage 2 to output
            if (!out_valid || out_ready) begin
                out_data <= stage2_data;
                out_valid <= stage2_valid;
                stage2_valid <= 0;
            end
            
            // Stage 1 to Stage 2
            if (!stage2_valid || !out_valid || out_ready) begin
                stage2_data <= stage1_data;
                stage2_valid <= stage1_valid;
                stage1_valid <= 0;
            end
            
            // Input to Stage 1
            if (!stage1_valid || (!stage2_valid || !out_valid || out_ready)) begin
                if (in_valid && in_ready) begin
                    stage1_data <= in_data;
                    stage1_valid <= 1;
                end
                in_ready <= !stage1_valid || (!stage2_valid || !out_valid || out_ready);
            end
        end
    end
endmodule