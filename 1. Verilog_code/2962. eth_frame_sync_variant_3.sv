//SystemVerilog
module eth_frame_sync #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire [IN_WIDTH-1:0]   data_in,
    input  wire                  in_valid,
    output reg  [OUT_WIDTH-1:0]  data_out,
    output reg                   out_valid,
    output reg                   sof,
    output reg                   eof
);
    localparam RATIO = OUT_WIDTH / IN_WIDTH;
    
    // 主数据路径寄存器
    reg [IN_WIDTH*RATIO-1:0] shift_reg;
    reg [3:0] count;
    reg prev_sof;
    
    // 流水线寄存器 - 第一级
    reg [IN_WIDTH-1:0] data_in_pipe;
    reg in_valid_pipe;
    reg [IN_WIDTH*RATIO-1:0] shift_reg_pipe;
    reg [3:0] count_pipe;
    
    // 流水线寄存器 - 第二级
    reg is_sof;
    reg is_eof;
    reg should_output;
    reg [IN_WIDTH*RATIO-1:0] output_data;
    
    // 数据输入流水线 - 第一级
    always @(posedge clk) begin
        if (rst) begin
            data_in_pipe <= 0;
        end else begin
            data_in_pipe <= data_in;
        end
    end
    
    // 有效信号流水线 - 第一级
    always @(posedge clk) begin
        if (rst) begin
            in_valid_pipe <= 0;
        end else begin
            in_valid_pipe <= in_valid;
        end
    end
    
    // 移位寄存器流水线 - 第一级
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_pipe <= 0;
        end else begin
            shift_reg_pipe <= shift_reg;
        end
    end
    
    // 计数器流水线 - 第一级
    always @(posedge clk) begin
        if (rst) begin
            count_pipe <= 0;
        end else begin
            count_pipe <= count;
        end
    end
    
    // SOF检测逻辑 - 第二级
    always @(posedge clk) begin
        if (rst) begin
            is_sof <= 0;
        end else begin
            is_sof <= (in_valid_pipe && data_in_pipe === 8'hD5 && !prev_sof);
        end
    end
    
    // EOF检测逻辑 - 第二级
    always @(posedge clk) begin
        if (rst) begin
            is_eof <= 0;
        end else begin
            is_eof <= (in_valid_pipe && count_pipe === RATIO-1 && 
                      shift_reg_pipe[IN_WIDTH*RATIO-1 -: 8] === 8'hFD);
        end
    end
    
    // 输出控制逻辑 - 第二级
    always @(posedge clk) begin
        if (rst) begin
            should_output <= 0;
            output_data <= 0;
        end else begin
            should_output <= (in_valid_pipe && count_pipe === RATIO-1);
            if (in_valid_pipe && count_pipe === RATIO-1) begin
                output_data <= shift_reg_pipe;
            end
        end
    end
    
    // 移位寄存器更新逻辑
    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= 0;
        end else if (in_valid) begin
            shift_reg <= {shift_reg[IN_WIDTH*(RATIO-1)-1:0], data_in};
        end
    end
    
    // 帧同步计数逻辑
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
        end else if (in_valid) begin
            if (data_in === 8'hD5 && !prev_sof) begin
                count <= 0;
            end else if (count === RATIO-1) begin
                count <= 0;
            end else begin
                count <= count + 1;
            end
        end
    end
    
    // 帧起始标志记录
    always @(posedge clk) begin
        if (rst) begin
            prev_sof <= 0;
        end else if (in_valid) begin
            if (data_in === 8'hD5 && !prev_sof) begin
                prev_sof <= 1;
            end
        end
    end
    
    // 输出数据寄存器
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 0;
        end else if (should_output) begin
            data_out <= output_data;
        end
    end
    
    // 输出有效信号
    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 0;
        end else begin
            out_valid <= should_output;
        end
    end
    
    // 帧起始标志输出
    always @(posedge clk) begin
        if (rst) begin
            sof <= 0;
        end else begin
            sof <= is_sof;
        end
    end
    
    // 帧结束标志输出
    always @(posedge clk) begin
        if (rst) begin
            eof <= 0;
        end else begin
            eof <= is_eof;
        end
    end
    
endmodule