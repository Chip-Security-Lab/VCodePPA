//SystemVerilog
module DoubleBuffer #(parameter W=12) (
    input wire clk,
    input wire rst_n,
    input wire load,
    input wire [W-1:0] data_in,
    output wire [W-1:0] data_out
);

reg [W-1:0] data_stage1, data_stage2;
reg valid_stage1, valid_stage2;

// Combined pipeline stages with optimized control logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {data_stage1, data_stage2} <= {2*W{1'b0}};
        {valid_stage1, valid_stage2} <= 2'b00;
    end else begin
        data_stage1 <= data_in;
        valid_stage1 <= load;
        if (valid_stage1) begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
end

assign data_out = data_stage2;

endmodule