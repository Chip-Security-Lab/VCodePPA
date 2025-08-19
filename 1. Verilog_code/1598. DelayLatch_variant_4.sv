//SystemVerilog
module DelayLatch #(parameter DW=8, DEPTH=3) (
    input clk, rst_n,
    input valid_in,
    input [DW-1:0] din,
    output valid_out,
    output [DW-1:0] dout
);

// Pipeline registers for data and valid signals
reg [DW-1:0] data_stage [0:DEPTH-1];
reg [DEPTH:0] valid_stage;

// Pipeline control signals
reg flush;

// Stage 0: Input stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage[0] <= 1'b0;
        data_stage[0] <= {DW{1'b0}};
        flush <= 1'b0;
    end else begin
        valid_stage[0] <= valid_in;
        if (valid_in) begin
            data_stage[0] <= din;
        end
    end
end

// Pipeline stages 1 to DEPTH-1
genvar i;
generate
    for (i = 1; i < DEPTH; i = i + 1) begin : pipeline_stages
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                valid_stage[i] <= 1'b0;
                data_stage[i] <= {DW{1'b0}};
            end else begin
                valid_stage[i] <= valid_stage[i-1];
                if (valid_stage[i-1]) begin
                    data_stage[i] <= data_stage[i-1];
                end
            end
        end
    end
endgenerate

// Final output stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage[DEPTH] <= 1'b0;
    end else begin
        valid_stage[DEPTH] <= valid_stage[DEPTH-1];
    end
end

// Output assignments
assign valid_out = valid_stage[DEPTH];
assign dout = data_stage[DEPTH-1];

endmodule