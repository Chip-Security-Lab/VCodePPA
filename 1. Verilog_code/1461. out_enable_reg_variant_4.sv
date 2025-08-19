//SystemVerilog
module out_enable_reg(
    input clk, rst,
    input [15:0] data_in,
    input load, out_en,
    output [15:0] data_out
);
    // Pipeline stage 1: Input registration
    reg [15:0] stage1_data;
    reg stage1_load;
    reg stage1_out_en;
    reg stage1_valid;

    // Pipeline stage 2: Processing stage
    reg [15:0] stage2_data;
    reg stage2_out_en;
    reg stage2_valid;

    // Pipeline stage 3: Output stage
    reg [15:0] stage3_data;
    reg stage3_out_en;
    reg stage3_valid;

    // Stage 1: Input registration
    always @(posedge clk) begin
        if (rst) begin
            stage1_data <= 16'h0;
            stage1_load <= 1'b0;
            stage1_out_en <= 1'b0;
            stage1_valid <= 1'b0;
        end else begin
            stage1_data <= data_in;
            stage1_load <= load;
            stage1_out_en <= out_en;
            stage1_valid <= 1'b1;
        end
    end

    // Stage 2: Processing stage
    always @(posedge clk) begin
        if (rst) begin
            stage2_data <= 16'h0;
            stage2_out_en <= 1'b0;
            stage2_valid <= 1'b0;
        end else if (stage1_valid) begin
            stage2_data <= stage1_load ? stage1_data : stage2_data;
            stage2_out_en <= stage1_out_en;
            stage2_valid <= stage1_valid;
        end
    end

    // Stage 3: Output stage
    always @(posedge clk) begin
        if (rst) begin
            stage3_data <= 16'h0;
            stage3_out_en <= 1'b0;
            stage3_valid <= 1'b0;
        end else if (stage2_valid) begin
            stage3_data <= stage2_data;
            stage3_out_en <= stage2_out_en;
            stage3_valid <= stage2_valid;
        end
    end

    // Output assignment with tri-state capability
    assign data_out = (stage3_valid && stage3_out_en) ? stage3_data : 16'hZ;
endmodule