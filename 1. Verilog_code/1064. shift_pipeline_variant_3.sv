//SystemVerilog
module shift_pipeline #(parameter WIDTH=8, STAGES=3) (
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

// 优化目标：高效实现多级左移流水线，避免冗余比较链
localparam integer PIPELINE_DEPTH = (STAGES < 1) ? 1 : STAGES;
localparam integer FINE_PIPELINE_DEPTH = PIPELINE_DEPTH * 2;

// 使用单一寄存器数组存储流水线各级数据
reg [WIDTH-1:0] pipeline_data [0:FINE_PIPELINE_DEPTH];
reg             pipeline_valid [0:FINE_PIPELINE_DEPTH];

integer idx;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (idx = 0; idx <= FINE_PIPELINE_DEPTH; idx = idx + 1) begin
            pipeline_data[idx] <= {WIDTH{1'b0}};
            pipeline_valid[idx] <= 1'b0;
        end
    end else begin
        // 输入级
        pipeline_data[0] <= din;
        pipeline_valid[0] <= 1'b1;
        // 优化流水线移位：直接左移等价于stage编号，避免重复比较链
        for (idx = 1; idx <= FINE_PIPELINE_DEPTH; idx = idx + 1) begin
            // 通过范围判断优化移位操作
            if (idx <= WIDTH) begin
                pipeline_data[idx] <= pipeline_data[idx-1] << 1;
            end else begin
                pipeline_data[idx] <= {WIDTH{1'b0}};
            end
            pipeline_valid[idx] <= pipeline_valid[idx-1];
        end
    end
end

assign dout = pipeline_data[FINE_PIPELINE_DEPTH];

endmodule