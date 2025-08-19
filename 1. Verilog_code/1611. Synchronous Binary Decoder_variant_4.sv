//SystemVerilog
module sync_binary_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [OUT_WIDTH-1:0] sel_out
);

    // Pipeline registers
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [ADDR_WIDTH-1:0] addr_stage2;
    reg [OUT_WIDTH-1:0] sel_out_stage1;
    reg [OUT_WIDTH-1:0] sel_out_stage2;
    
    // Stage 1: Address register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {ADDR_WIDTH{1'b0}};
        end else begin
            addr_stage1 <= addr;
        end
    end
    
    // Stage 2: Address register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= {ADDR_WIDTH{1'b0}};
        end else begin
            addr_stage2 <= addr_stage1;
        end
    end
    
    // Stage 2: Partial decode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_out_stage1 <= {OUT_WIDTH{1'b0}};
        end else begin
            sel_out_stage1 <= 1'b1 << addr_stage1[ADDR_WIDTH-2:0];
        end
    end
    
    // Stage 3: Final decode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_out_stage2 <= {OUT_WIDTH{1'b0}};
        end else begin
            sel_out_stage2 <= sel_out_stage1 << addr_stage2[ADDR_WIDTH-1];
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_out <= {OUT_WIDTH{1'b0}};
        end else begin
            sel_out <= sel_out_stage2;
        end
    end

endmodule