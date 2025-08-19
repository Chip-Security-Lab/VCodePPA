//SystemVerilog
//===========================================================================
// Shadow Buffer Top Module - IEEE 1364-2005 Verilog standard
// 实现带握手机制的高效流水线数据缓冲功能
//===========================================================================
module shadow_buffer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] data_in,
    input  wire        valid_in,
    output wire        ready_in,
    output wire        valid_out,
    input  wire        ready_out,
    output wire [31:0] data_out
);

    // 数据通路信号定义
    wire        stage1_valid;
    wire        stage1_ready;
    wire [31:0] stage1_data;
    
    wire        stage2_valid;
    wire        stage2_ready;
    wire [31:0] stage2_data;
    
    // 流水线控制信号
    wire        pipe_advance_s1;
    wire        pipe_advance_s2;
    
    // 第一阶段：输入缓冲
    input_stage input_buffer (
        .clk          (clk),
        .rst_n        (rst_n),
        .data_in      (data_in),
        .valid_in     (valid_in),
        .ready_in     (ready_in),
        .valid_out    (stage1_valid),
        .ready_out    (stage1_ready),
        .data_out     (stage1_data),
        .pipe_advance (pipe_advance_s1)
    );
    
    // 第二阶段：影子寄存器
    shadow_stage shadow_buffer (
        .clk          (clk),
        .rst_n        (rst_n),
        .data_in      (stage1_data),
        .valid_in     (stage1_valid),
        .ready_in     (stage1_ready),
        .valid_out    (stage2_valid),
        .ready_out    (stage2_ready),
        .data_out     (stage2_data),
        .pipe_advance (pipe_advance_s2)
    );
    
    // 第三阶段：输出缓冲
    output_stage output_buffer (
        .clk          (clk),
        .rst_n        (rst_n),
        .data_in      (stage2_data),
        .valid_in     (stage2_valid),
        .ready_in     (stage2_ready),
        .valid_out    (valid_out),
        .ready_out    (ready_out),
        .data_out     (data_out)
    );

endmodule

//===========================================================================
// 输入阶段模块 - 处理输入握手和初始数据缓存
//===========================================================================
module input_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] data_in,
    input  wire        valid_in,
    output wire        ready_in,
    output reg         valid_out,
    input  wire        ready_out,
    output reg  [31:0] data_out,
    output wire        pipe_advance
);

    // 流水线阶段信号
    reg  input_buffer_full;
    reg  [31:0] input_buffer_data;
    
    // 数据流控制信号
    assign pipe_advance = valid_out && ready_out;
    assign ready_in = !input_buffer_full || pipe_advance;
    
    // 数据缓存控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_buffer_full <= 1'b0;
            input_buffer_data <= 32'h0;
        end else begin
            if (valid_in && ready_in && !pipe_advance) begin
                // 捕获新数据且未能前进到下一阶段
                input_buffer_full <= 1'b1;
                input_buffer_data <= data_in;
            end else if (!valid_in && pipe_advance) begin
                // 数据前进到下一阶段但没有新数据
                input_buffer_full <= 1'b0;
            end else if (valid_in && pipe_advance) begin
                // 同时接收新数据并前进
                input_buffer_data <= data_in;
            end
        end
    end
    
    // 输出控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out <= 32'h0;
        end else begin
            if (valid_in && ready_in) begin
                // 直接传递数据到下一阶段
                valid_out <= 1'b1;
                data_out <= data_in;
            end else if (input_buffer_full && !valid_out) begin
                // 从缓存传递数据
                valid_out <= 1'b1;
                data_out <= input_buffer_data;
            end else if (pipe_advance && !valid_in) begin
                // 数据已前进且无新数据
                valid_out <= 1'b0;
            end
        end
    end

endmodule

//===========================================================================
// 影子寄存器阶段 - 处理中间数据缓存
//===========================================================================
module shadow_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] data_in,
    input  wire        valid_in,
    output wire        ready_in,
    output reg         valid_out,
    input  wire        ready_out,
    output reg  [31:0] data_out,
    output wire        pipe_advance
);

    // 影子寄存器状态
    reg  shadow_valid;
    reg  [31:0] shadow_data;
    
    // 数据流控制
    assign pipe_advance = valid_out && ready_out;
    assign ready_in = !shadow_valid || pipe_advance;
    
    // 影子寄存器控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_valid <= 1'b0;
            shadow_data <= 32'h0;
        end else begin
            if (valid_in && ready_in && !pipe_advance) begin
                // 捕获数据到影子寄存器
                shadow_valid <= 1'b1;
                shadow_data <= data_in;
            end else if (!valid_in && pipe_advance && shadow_valid) begin
                // 影子数据前进，无新数据
                shadow_valid <= 1'b0;
            end else if (valid_in && pipe_advance) begin
                // 同时接收新数据并前进
                shadow_data <= data_in;
            end
        end
    end
    
    // 输出控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out <= 32'h0;
        end else begin
            if (valid_in && ready_in && !valid_out) begin
                // 直接传递数据
                valid_out <= 1'b1;
                data_out <= data_in;
            end else if (shadow_valid && !valid_out) begin
                // 从影子寄存器传递
                valid_out <= 1'b1;
                data_out <= shadow_data;
            end else if (pipe_advance && !(valid_in && ready_in) && !shadow_valid) begin
                // 数据已前进，无更多数据
                valid_out <= 1'b0;
            end
        end
    end

endmodule

//===========================================================================
// 输出阶段模块 - 处理最终数据输出和握手
//===========================================================================
module output_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] data_in,
    input  wire        valid_in,
    output wire        ready_in,
    output reg         valid_out,
    input  wire        ready_out,
    output reg  [31:0] data_out
);

    // 输出阶段信号
    reg  output_pending;
    reg  [31:0] pending_data;
    wire output_consumed;
    
    // 数据流控制
    assign output_consumed = valid_out && ready_out;
    assign ready_in = !output_pending || output_consumed;
    
    // 输出寄存器数据路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_pending <= 1'b0;
            pending_data <= 32'h0;
            valid_out <= 1'b0;
            data_out <= 32'h0;
        end else begin
            // 更新输出状态
            if (valid_in && ready_in) begin
                if (!valid_out || output_consumed) begin
                    // 直接更新输出
                    valid_out <= 1'b1;
                    data_out <= data_in;
                    output_pending <= 1'b0;
                end else begin
                    // 存储到待处理缓冲区
                    output_pending <= 1'b1;
                    pending_data <= data_in;
                end
            end else if (output_consumed) begin
                if (output_pending) begin
                    // 从待处理缓冲区移动到输出
                    valid_out <= 1'b1;
                    data_out <= pending_data;
                    output_pending <= 1'b0;
                end else begin
                    // 无更多数据
                    valid_out <= 1'b0;
                end
            end
        end
    end

endmodule