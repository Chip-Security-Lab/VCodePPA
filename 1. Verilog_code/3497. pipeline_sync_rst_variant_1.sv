//SystemVerilog
module pipeline_sync_rst #(parameter WIDTH=8)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout_stage1, dout_stage2
);
    // Stage registers for pipelined data flow
    reg [WIDTH-1:0] stage1_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            stage1_reg <= 0;
            dout_stage1 <= 0;
            dout_stage2 <= 0;
        end else begin
            // Direct registration of input data to first output
            dout_stage1 <= din;
            // Feed registered data to subsequent stages
            stage1_reg <= dout_stage1;
            dout_stage2 <= stage1_reg;
        end
    end
endmodule