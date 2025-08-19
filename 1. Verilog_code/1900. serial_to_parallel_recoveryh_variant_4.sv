//SystemVerilog
module serial_to_parallel_recovery #(
    parameter WIDTH = 8
)(
    input wire bit_clk,
    input wire reset,
    input wire serial_in,
    input wire frame_sync,
    output reg [WIDTH-1:0] parallel_out,
    output reg data_valid
);
    // 主移位寄存器和流水线寄存器
    reg [WIDTH-1:0] shift_reg;
    reg [WIDTH-1:0] shift_reg_pipe;
    reg [3:0] bit_count;
    reg [3:0] bit_count_pipe;
    
    // 优化控制状态定义
    localparam RESET_STATE = 2'b00;
    localparam SYNC_STATE  = 2'b01;
    localparam WORK_STATE  = 2'b10;
    
    reg [1:0] ctrl_state;
    reg [1:0] ctrl_state_pipe;
    
    // 关键路径切割 - 将比较逻辑分离到流水线
    wire last_bit_compare;
    reg last_bit_pipe;
    
    // 第一级流水线 - 比较逻辑
    assign last_bit_compare = (bit_count == WIDTH-1);
    
    // 流水线寄存器 - 切割关键路径
    always @(posedge bit_clk) begin
        bit_count_pipe <= bit_count;
        shift_reg_pipe <= shift_reg;
        ctrl_state_pipe <= ctrl_state;
        last_bit_pipe <= last_bit_compare;
    end
    
    // 第一级 - 状态和移位处理
    always @(posedge bit_clk or posedge reset) begin
        if (reset) begin
            // 复位状态处理
            ctrl_state <= RESET_STATE;
            shift_reg <= {WIDTH{1'b0}};
            bit_count <= 4'b0;
        end 
        else if (frame_sync) begin
            // 帧同步状态处理
            ctrl_state <= SYNC_STATE;
            shift_reg <= {WIDTH{1'b0}};
            bit_count <= 4'b0;
        end
        else begin
            // 正常工作状态处理
            ctrl_state <= WORK_STATE;
            
            // 移位寄存器操作
            shift_reg <= {shift_reg[WIDTH-2:0], serial_in};
            
            // 位计数器控制
            if (last_bit_pipe) begin
                bit_count <= 4'b0;
            end 
            else begin
                bit_count <= bit_count + 1'b1;
            end
        end
    end
    
    // 第二级 - 输出处理，使用流水线寄存器
    always @(posedge bit_clk or posedge reset) begin
        if (reset) begin
            parallel_out <= {WIDTH{1'b0}};
            data_valid <= 1'b0;
        end
        else if (frame_sync) begin
            data_valid <= 1'b0;
        end
        else if (ctrl_state_pipe == WORK_STATE && last_bit_pipe) begin
            // 当接收到完整字时
            parallel_out <= shift_reg_pipe;
            data_valid <= 1'b1;
        end 
        else begin
            data_valid <= 1'b0;
        end
    end
endmodule