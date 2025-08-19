//SystemVerilog
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
    wire stage1_ready, stage2_ready;
    
    // Stage 1 ready signal
    assign stage1_ready = !stage1_valid || stage2_ready;
    
    // Stage 2 ready signal
    assign stage2_ready = !stage2_valid || !out_valid || out_ready;
    
    // Input ready logic
    always @(posedge clk) begin
        if (!rst_n) begin
            in_ready <= 1;
        end else begin
            in_ready <= stage1_ready;
        end
    end
    
    // Stage 1 data and valid
    always @(posedge clk) begin
        if (!rst_n) begin
            stage1_valid <= 0;
            stage1_data <= 0;
        end else if (stage1_ready) begin
            if (in_valid && in_ready) begin
                stage1_data <= in_data;
                stage1_valid <= 1;
            end else if (stage1_valid && stage2_ready) begin
                stage1_valid <= 0;
            end
        end
    end
    
    // Stage 2 data and valid
    always @(posedge clk) begin
        if (!rst_n) begin
            stage2_valid <= 0;
            stage2_data <= 0;
        end else if (stage2_ready) begin
            stage2_data <= stage1_data;
            stage2_valid <= stage1_valid;
        end
    end
    
    // Output data and valid
    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid <= 0;
            out_data <= 0;
        end else if (!out_valid || out_ready) begin
            out_data <= stage2_data;
            out_valid <= stage2_valid;
        end
    end
endmodule