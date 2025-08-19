//SystemVerilog
module pipeline_bridge #(parameter DWIDTH=8) (
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
    
    // Pre-compute control signals to reduce combinational logic depth
    wire stage2_ready = !stage2_valid || !out_valid || out_ready;
    wire stage1_ready = !stage1_valid || stage2_ready;
    
    // Optimize subtractor implementation with balanced logic
    wire [DWIDTH:0] stage1_ext = {1'b0, stage1_data};
    wire [DWIDTH:0] stage2_ext = {1'b0, stage2_data};
    wire [DWIDTH:0] diff = stage1_ext - stage2_ext;
    wire [DWIDTH-1:0] sum_result = diff[DWIDTH-1:0];
    wire borrow_out = diff[DWIDTH];

    always @(posedge clk) begin
        if (!rst_n) begin
            stage1_valid <= 0;
            stage2_valid <= 0;
            out_valid <= 0;
            in_ready <= 1;
        end else begin
            // Stage 2 to output - simplified condition
            if (!out_valid || out_ready) begin
                out_data <= sum_result;
                out_valid <= stage2_valid;
                stage2_valid <= 0;
            end
            
            // Stage 1 to Stage 2 - using pre-computed signal
            if (stage2_ready) begin
                stage2_data <= stage1_data;
                stage2_valid <= stage1_valid;
                stage1_valid <= 0;
            end
            
            // Input to Stage 1 - using pre-computed signal
            if (stage1_ready) begin
                if (in_valid && in_ready) begin
                    stage1_data <= in_data;
                    stage1_valid <= 1;
                end
                in_ready <= stage1_ready;
            end
        end
    end
endmodule