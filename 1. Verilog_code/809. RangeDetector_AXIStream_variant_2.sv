//SystemVerilog
module RangeDetector_AXIStream #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input tvalid,
    input [WIDTH-1:0] tdata,
    input [WIDTH-1:0] lower,
    input [WIDTH-1:0] upper,
    output tvalid_out,
    output [WIDTH-1:0] tdata_out
);

    wire in_range;
    wire [WIDTH-1:0] tdata_out_wire;
    
    // 优化后的范围检测逻辑
    assign in_range = (tdata >= lower) && (tdata <= upper);
    
    // 输出处理逻辑
    assign tdata_out_wire = in_range ? tdata : {WIDTH{1'b0}};
    
    // 时序逻辑
    reg tvalid_out_reg;
    reg [WIDTH-1:0] tdata_out_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tvalid_out_reg <= 1'b0;
            tdata_out_reg <= {WIDTH{1'b0}};
        end
        else begin
            tvalid_out_reg <= tvalid;
            tdata_out_reg <= tdata_out_wire;
        end
    end
    
    assign tvalid_out = tvalid_out_reg;
    assign tdata_out = tdata_out_reg;
    
endmodule