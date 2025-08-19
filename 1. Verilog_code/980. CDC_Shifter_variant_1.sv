//SystemVerilog
module CDC_Shifter #(parameter WIDTH=8) (
    input wire src_clk,
    input wire dst_clk,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

// Source and destination domain pipeline/synchronizer registers
reg [WIDTH-1:0] src_reg_stage1;
reg [WIDTH-1:0] src_reg_stage2;
reg [WIDTH-1:0] dst_reg_stage1;
reg [WIDTH-1:0] dst_reg_stage2;
reg [WIDTH-1:0] dst_reg_stage3;

// Combined always block for both clock domains
always @(posedge src_clk or posedge dst_clk) begin
    if (src_clk) begin
        src_reg_stage1 <= data_in;
        src_reg_stage2 <= src_reg_stage1;
    end
    if (dst_clk) begin
        dst_reg_stage1 <= src_reg_stage2;
        dst_reg_stage2 <= dst_reg_stage1;
        dst_reg_stage3 <= dst_reg_stage2;
    end
end

assign data_out = dst_reg_stage3;

endmodule