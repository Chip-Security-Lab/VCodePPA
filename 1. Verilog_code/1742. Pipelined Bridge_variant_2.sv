//SystemVerilog
module pipeline_bridge #(parameter DWIDTH=8) (
    input clk, rst_n,
    input [DWIDTH-1:0] in_data_a, in_data_b,
    input in_valid,
    output reg in_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    input out_ready
);
    reg [DWIDTH-1:0] stage1_data, stage2_data;
    reg stage1_valid, stage2_valid;
    wire stage2_ready, stage1_ready;

    // Pre-compute ready signals
    assign stage2_ready = !out_valid || out_ready;
    assign stage1_ready = !stage2_valid || stage2_ready;

    // Borrow logic for the borrow lookahead subtractor
    wire [DWIDTH-1:0] borrow;
    wire [DWIDTH-1:0] diff;

    assign borrow[0] = in_data_a[0] < in_data_b[0];
    assign diff[0] = in_data_a[0] - in_data_b[0];

    genvar i;
    generate
        for (i = 1; i < DWIDTH; i = i + 1) begin : subtractor
            assign borrow[i] = (in_data_a[i] < in_data_b[i] + borrow[i-1]) ? 1 : 0;
            assign diff[i] = in_data_a[i] - in_data_b[i] - borrow[i-1];
        end
    endgenerate

    always @(posedge clk) begin
        if (!rst_n) begin
            stage1_valid <= 0; 
            stage2_valid <= 0; 
            out_valid <= 0;
            in_ready <= 1;
        end else begin
            // Stage 2 to output
            if (stage2_ready) begin
                out_data <= stage2_data;
                out_valid <= stage2_valid;
                stage2_valid <= 0;
            end
            
            // Stage 1 to Stage 2
            if (stage1_ready) begin
                stage2_data <= stage1_data;
                stage2_valid <= stage1_valid;
                stage1_valid <= 0;
            end
            
            // Input to Stage 1
            if (stage1_ready) begin
                if (in_valid && in_ready) begin
                    stage1_data <= diff; // Use the computed difference
                    stage1_valid <= 1;
                end
                in_ready <= stage1_ready;
            end
        end
    end
endmodule