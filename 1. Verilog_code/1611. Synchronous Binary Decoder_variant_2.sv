//SystemVerilog
module sync_binary_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg valid_out,
    output reg [OUT_WIDTH-1:0] sel_out
);

    // Pipeline registers
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg valid_stage1;
    
    reg [ADDR_WIDTH-1:0] addr_stage2;
    reg valid_stage2;
    
    reg [OUT_WIDTH-1:0] sel_stage3;
    reg valid_stage3;
    
    reg [OUT_WIDTH-1:0] sel_stage4;
    reg valid_stage4;

    // Stage 1: Address register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {ADDR_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2: Address register and initial decode preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= {ADDR_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Decode operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_stage3 <= {OUT_WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            sel_stage3 <= 1'b1 << addr_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_stage4 <= {OUT_WIDTH{1'b0}};
            valid_stage4 <= 1'b0;
        end else begin
            sel_stage4 <= sel_stage3;
            valid_stage4 <= valid_stage3;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_out <= {OUT_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            sel_out <= sel_stage4;
            valid_out <= valid_stage4;
        end
    end

endmodule