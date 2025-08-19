//SystemVerilog
module shadow_reg_fsm #(parameter DW=4) (
    input clk, rst, trigger,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] shadow;
    reg state;
    
    // 使用单比特状态编码以减少寄存器使用并简化状态转换逻辑
    localparam IDLE = 1'b0;
    localparam LOAD = 1'b1;
    
    // 增加了触发器条件的高效编码
    // 预计算下一个状态以减少关键路径延迟
    wire next_state = (state == IDLE) ? (trigger ? LOAD : IDLE) : IDLE;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
            shadow <= {DW{1'b0}};
            data_out <= {DW{1'b0}};
        end
        else begin
            state <= next_state;
            
            // 使用条件赋值替代case语句，减少多路复用器深度
            // 通过并行条件处理提高性能
            if(state == IDLE && trigger) begin
                shadow <= data_in;
            end
            
            if(state == LOAD) begin
                data_out <= shadow;
            end
        end
    end
endmodule