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

    // Pipeline stage 1: Address register
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg valid_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {ADDR_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
        end
    end

    // Pipeline stage 2: Decoder logic
    reg [OUT_WIDTH-1:0] sel_out_stage2;
    reg valid_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_out_stage2 <= {OUT_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            sel_out_stage2 <= 1'b1 << addr_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Pipeline stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_out <= {OUT_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            sel_out <= sel_out_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule