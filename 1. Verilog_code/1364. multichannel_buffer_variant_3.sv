//SystemVerilog
module multichannel_buffer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  channel_select,
    input  wire [7:0]  data_in,
    input  wire        data_valid,
    output wire        data_ready,
    output reg  [7:0]  data_out,
    output reg         data_out_valid
);
    // 通道存储器
    reg [7:0] channel_memory [0:15];
    
    // 数据流水线寄存器
    reg [3:0] selected_channel_r;     // 寄存通道选择信号
    reg [3:0] write_channel_r;        // 记录写入的通道
    reg       write_stage_valid_r;    // 写入阶段有效标志
    reg       read_stage_valid_r;     // 读取阶段有效标志
    
    // 握手控制信号
    reg       processing_data_r;      // 数据处理状态指示
    
    // 握手逻辑 - 当不在处理数据时表示可以接收新数据
    assign data_ready = !processing_data_r;
    
    // ========== 通道选择逻辑 ==========
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_channel_r <= 4'b0;
        end else begin
            selected_channel_r <= channel_select;
        end
    end
    
    // ========== 数据处理状态控制 ==========
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing_data_r <= 1'b0;
        end else if (data_valid && data_ready) begin
            processing_data_r <= 1'b1;
        end else begin
            processing_data_r <= 1'b0;
        end
    end
    
    // ========== 写通道捕获逻辑 ==========
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_channel_r <= 4'b0;
            write_stage_valid_r <= 1'b0;
        end else begin
            write_stage_valid_r <= 1'b0;
            
            if (data_valid && data_ready) begin
                write_channel_r <= channel_select;
                write_stage_valid_r <= 1'b1;
            end
        end
    end
    
    // ========== 存储器初始化逻辑 ==========
    integer i;
    always @(negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 16; i = i + 1)
                channel_memory[i] <= 8'b0;
        end
    end
    
    // ========== 内存写入逻辑 ==========
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_stage_valid_r <= 1'b0;
        end else begin
            read_stage_valid_r <= 1'b0;
            
            if (write_stage_valid_r) begin
                channel_memory[write_channel_r] <= data_in;
                read_stage_valid_r <= 1'b1;
            end
        end
    end
    
    // ========== 输出产生逻辑 ==========
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
            data_out_valid <= 1'b0;
        end else if (read_stage_valid_r) begin
            // 当写入完成后，输出写入的通道数据
            data_out <= channel_memory[write_channel_r];
            data_out_valid <= 1'b1;
        end else begin
            // 无写入操作时，输出当前选择的通道数据
            data_out <= channel_memory[selected_channel_r];
            data_out_valid <= 1'b0;
        end
    end
endmodule