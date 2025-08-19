//SystemVerilog
module RangeDetector_Timeout #(
    parameter WIDTH = 8,
    parameter TIMEOUT = 10
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg timeout
);

reg [$clog2(TIMEOUT):0] counter;
wire [WIDTH-1:0] threshold_comp;
wire [WIDTH-1:0] sum;
wire [WIDTH:0] carry;
wire data_gt_threshold;

// 计算阈值的补码
assign threshold_comp = ~threshold + 1'b1;

// 补码加法器
assign carry[0] = 1'b0;
genvar i;
generate
    for(i = 0; i < WIDTH; i = i + 1) begin: ADD_GEN
        assign sum[i] = data_in[i] ^ threshold_comp[i] ^ carry[i];
        assign carry[i+1] = (data_in[i] & threshold_comp[i]) | 
                          ((data_in[i] | threshold_comp[i]) & carry[i]);
    end
endgenerate

// 比较结果
assign data_gt_threshold = ~carry[WIDTH];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 0;
        timeout <= 0;
    end
    else if(data_gt_threshold && counter < TIMEOUT) begin
        counter <= counter + 1;
        timeout <= (counter + 1'b1 == TIMEOUT);
    end
    else if(data_gt_threshold && counter == TIMEOUT) begin
        counter <= TIMEOUT;
        timeout <= 1'b1;
    end
    else if(!data_gt_threshold) begin
        counter <= 0;
        timeout <= 1'b0;
    end
end

endmodule