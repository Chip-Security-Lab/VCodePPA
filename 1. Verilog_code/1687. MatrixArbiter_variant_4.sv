//SystemVerilog
module MatrixArbiter #(parameter N=4) (
    input clk, rst,
    input [N-1:0] req,
    output [N-1:0] grant
);

// 流水线寄存器定义
reg [N-1:0] priority_matrix_stage1 [0:N-1];
reg [N-1:0] priority_matrix_stage2 [0:N-1];
reg [N-1:0] matrix_shifted_stage1 [0:N-1];
reg [N-1:0] matrix_shifted_stage2 [0:N-1];
reg [1:0] counter_stage1;
reg [1:0] counter_stage2;
reg [N-1:0] grant_stage1;
reg [N-1:0] grant_stage2;

// 组合逻辑 - 矩阵移位阶段1
always @(*) begin
    integer i;
    for(i=N-1; i>0; i=i-1)
        matrix_shifted_stage1[i] = priority_matrix_stage1[i-1];
    matrix_shifted_stage1[0] = req;
end

// 组合逻辑 - 矩阵移位阶段2
always @(*) begin
    integer i;
    for(i=N-1; i>0; i=i-1)
        matrix_shifted_stage2[i] = priority_matrix_stage2[i-1];
    matrix_shifted_stage2[0] = req;
end

// 时序逻辑 - 阶段1
always @(posedge clk) begin
    if(rst) begin
        integer i;
        for(i=0; i<N; i=i+1) begin
            priority_matrix_stage1[i] <= 0;
            priority_matrix_stage2[i] <= 0;
        end
        counter_stage1 <= 0;
        counter_stage2 <= 0;
        grant_stage1 <= 0;
        grant_stage2 <= 0;
    end else begin
        integer i;
        for(i=0; i<N; i=i+1)
            priority_matrix_stage1[i] <= matrix_shifted_stage1[i];
        counter_stage1 <= counter_stage1 + 1;
        grant_stage1 <= req & priority_matrix_stage1[counter_stage1];
    end
end

// 时序逻辑 - 阶段2
always @(posedge clk) begin
    if(!rst) begin
        integer i;
        for(i=0; i<N; i=i+1)
            priority_matrix_stage2[i] <= priority_matrix_stage1[i];
        counter_stage2 <= counter_stage1;
        grant_stage2 <= grant_stage1;
    end
end

// 输出赋值
assign grant = grant_stage2;

endmodule