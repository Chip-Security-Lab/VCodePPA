//SystemVerilog
module pipeline_regfile #(
    parameter DW = 64,
    parameter AW = 3,
    parameter DEPTH = 8
)(
    input clk,
    input rst,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    input valid_in,
    output reg valid_out,
    output [DW-1:0] dout
);
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [DW-1:0] stage1_data, stage2_data, stage3_data, stage4_data, stage5_data;
    reg stage1_valid, stage2_valid, stage3_valid, stage4_valid, stage5_valid;
    reg [AW-1:0] stage1_addr, stage2_addr, stage3_addr, stage4_addr;
    reg stage1_wr_en, stage2_wr_en, stage3_wr_en;
    
    // Stage 1: Register inputs with optimized reset
    always @(posedge clk) begin
        if (rst) begin
            stage1_valid <= 1'b0;
            stage1_addr <= {AW{1'b0}};
            stage1_wr_en <= 1'b0;
            stage1_data <= {DW{1'b0}};
        end else begin
            stage1_valid <= valid_in;
            stage1_addr <= addr;
            stage1_wr_en <= wr_en;
            stage1_data <= din;
        end
    end

    // Stage 2: Write operation with optimized comparison
    always @(posedge clk) begin
        if (rst) begin
            stage2_valid <= 1'b0;
            stage2_addr <= {AW{1'b0}};
            stage2_wr_en <= 1'b0;
            stage2_data <= {DW{1'b0}};
        end else begin
            stage2_valid <= stage1_valid;
            stage2_addr <= stage1_addr;
            stage2_wr_en <= stage1_wr_en;
            stage2_data <= stage1_data;
            
            if (stage1_wr_en & stage1_valid) begin
                mem[stage1_addr] <= stage1_data;
            end
        end
    end

    // Stage 3: Memory read with optimized hazard detection
    always @(posedge clk) begin
        if (rst) begin
            stage3_valid <= 1'b0;
            stage3_addr <= {AW{1'b0}};
            stage3_wr_en <= 1'b0;
            stage3_data <= {DW{1'b0}};
        end else begin
            stage3_valid <= stage2_valid;
            stage3_addr <= stage2_addr;
            stage3_wr_en <= stage2_wr_en;
            
            if (stage2_wr_en & stage2_valid) begin
                stage3_data <= stage2_data;
            end else begin
                stage3_data <= mem[stage2_addr];
            end
        end
    end

    // Stage 4: Data forwarding with optimized pipeline
    always @(posedge clk) begin
        if (rst) begin
            stage4_valid <= 1'b0;
            stage4_data <= {DW{1'b0}};
        end else begin
            stage4_valid <= stage3_valid;
            stage4_data <= stage3_data;
        end
    end

    // Stage 5: Final pipeline stage
    always @(posedge clk) begin
        if (rst) begin
            stage5_valid <= 1'b0;
            stage5_data <= {DW{1'b0}};
        end else begin
            stage5_valid <= stage4_valid;
            stage5_data <= stage4_data;
        end
    end

    // Output stage
    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= stage5_valid;
        end
    end

    assign dout = stage5_data;

    // Memory initialization
    initial begin
        for (integer i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = {DW{1'b0}};
        end
    end
endmodule