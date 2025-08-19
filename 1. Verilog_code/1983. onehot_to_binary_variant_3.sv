//SystemVerilog
module onehot_to_binary #(
    parameter ONE_HOT_WIDTH = 8
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire [ONE_HOT_WIDTH-1:0]     onehot_in,
    output reg  [$clog2(ONE_HOT_WIDTH)-1:0] binary_out
);

// Pipeline stage 1: Register input for timing closure and clear data flow
reg [ONE_HOT_WIDTH-1:0] onehot_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        onehot_stage1 <= {ONE_HOT_WIDTH{1'b0}};
    else
        onehot_stage1 <= onehot_in;
end

// Pipeline stage 2: Combinational one-hot to binary conversion with clear data path
reg [$clog2(ONE_HOT_WIDTH)-1:0] binary_stage2;
integer idx;
always @* begin
    binary_stage2 = {($clog2(ONE_HOT_WIDTH)){1'b0}};
    for (idx = 0; idx < ONE_HOT_WIDTH; idx = idx + 1) begin
        if (onehot_stage1[idx])
            binary_stage2 = idx[$clog2(ONE_HOT_WIDTH)-1:0];
    end
end

// Pipeline stage 3: Register binary output for clear timing and handoff
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        binary_out <= {($clog2(ONE_HOT_WIDTH)){1'b0}};
    else
        binary_out <= binary_stage2;
end

endmodule