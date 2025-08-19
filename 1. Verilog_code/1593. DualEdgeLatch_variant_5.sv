//SystemVerilog
module DualEdgeLatch #(
    parameter DW = 16,
    parameter PIPELINE_STAGES = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [DW-1:0] din,
    output reg [DW-1:0] dout
);

// Pipeline registers
reg [DW-1:0] pipeline_reg [PIPELINE_STAGES-1:0];

// Input stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pipeline_reg[0] <= {DW{1'b0}};
    end else begin
        pipeline_reg[0] <= din;
    end
end

// Pipeline stages
genvar i;
generate
    for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin : pipeline_gen
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                pipeline_reg[i] <= {DW{1'b0}};
            end else begin
                pipeline_reg[i] <= pipeline_reg[i-1];
            end
        end
    end
endgenerate

// Output stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= {DW{1'b0}};
    end else begin
        dout <= pipeline_reg[PIPELINE_STAGES-1];
    end
end

endmodule