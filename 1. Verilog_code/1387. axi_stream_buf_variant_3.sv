//SystemVerilog
module axi_stream_buf #(parameter DW=64) (
    input clk, rst_n,
    input tvalid_in, tready_out,
    output tvalid_out, tready_in,
    input [DW-1:0] tdata_in,
    output [DW-1:0] tdata_out
);
    // Stage 1 registers
    reg [DW-1:0] stage1_data;
    reg stage1_valid;
    
    // Stage 2 registers
    reg [DW-1:0] stage2_data;
    reg stage2_valid;
    
    // Ready signals for each stage
    wire stage1_ready;
    wire stage2_ready;
    
    // Connect output ports
    assign tdata_out = stage2_data;
    assign tvalid_out = stage2_valid;
    
    // Ready signal propagation (backward)
    assign stage2_ready = tready_out || !stage2_valid;
    assign stage1_ready = stage2_ready || !stage1_valid;
    assign tready_in = stage1_ready;
    
    // Stage 1 pipeline logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= {DW{1'b0}};
            stage1_valid <= 1'b0;
        end
        else begin
            if (tvalid_in && stage1_ready) begin
                stage1_data <= tdata_in;
                stage1_valid <= 1'b1;
            end
            else if (stage1_valid && stage2_ready) begin
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // Stage 2 pipeline logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= {DW{1'b0}};
            stage2_valid <= 1'b0;
        end
        else begin
            if (stage1_valid && stage2_ready) begin
                stage2_data <= stage1_data;
                stage2_valid <= 1'b1;
            end
            else if (stage2_valid && tready_out) begin
                stage2_valid <= 1'b0;
            end
        end
    end
endmodule