//SystemVerilog
module ICMU_PipelineFSM #(
    parameter STAGES = 3,
    parameter DW = 32
)(
    input clk,
    input rst_async,
    input int_req,
    output reg [DW-1:0] ctx_out,
    output reg ctx_valid
);
    // 使用参数定义状态，便于后续扩展
    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] SAVE_PIPE = 2'b01;
    localparam [1:0] RESTORE_PIPE = 2'b10;
    
    reg [1:0] pipe_states [0:STAGES-1];
    reg [DW-1:0] pipeline [0:STAGES-1];
    
    // 优化复位逻辑和状态更新
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            integer i;
            for (i = 0; i < STAGES; i=i+1) begin
                pipe_states[i] <= IDLE;
                pipeline[i] <= {DW{1'b0}}; // 明确初始化pipeline数据
            end
            ctx_valid <= 1'b0;
            ctx_out <= {DW{1'b0}};
        end else begin
            // 优化管道逻辑：自顶向下传播数据
            integer j;
            for (j = STAGES-1; j > 0; j=j-1) begin
                pipe_states[j] <= pipe_states[j-1];
                pipeline[j] <= pipeline[j-1];
            end
            
            // 根据int_req直接选择状态，避免比较逻辑
            pipe_states[0] <= int_req ? SAVE_PIPE : RESTORE_PIPE;
            pipeline[0] <= {DW{1'b1}}; // 数据填充
            
            // 优化比较逻辑：使用位比较而非状态比较
            ctx_valid <= (pipe_states[STAGES-1] == SAVE_PIPE) ? 1'b1 : 1'b0;
            
            // 直接连接输出，避免不必要的逻辑
            ctx_out <= pipeline[STAGES-1];
        end
    end
endmodule