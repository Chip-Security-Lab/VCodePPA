//SystemVerilog
module s2p_buffer (
    input  wire        clk,
    input  wire        serial_in,
    input  wire        valid,
    input  wire        clear,
    output reg  [7:0]  parallel_out,
    output reg         ready
);
    // 内部状态和控制信号
    reg [2:0]  bit_counter;          // 位计数器，追踪已接收的位数
    reg        data_capture_active;   // 数据捕获活动标志
    reg        serial_data_reg;       // 输入数据寄存
    reg        valid_reg;             // 输入有效信号寄存

    // 流水线阶段1: 输入信号捕获
    always @(posedge clk) begin
        if (clear) begin
            serial_data_reg <= 1'b0;
            valid_reg <= 1'b0;
        end
        else begin
            serial_data_reg <= serial_in;
            valid_reg <= valid;
        end
    end

    // 流水线阶段2: 状态控制逻辑
    reg state_update;
    reg counter_reset;
    reg counter_increment;
    
    always @(posedge clk) begin
        if (clear) begin
            state_update <= 1'b0;
            counter_reset <= 1'b0;
            counter_increment <= 1'b0;
        end
        else begin
            // 控制信号生成
            state_update <= valid_reg && ready;
            counter_reset <= (bit_counter == 3'b111) && valid_reg && ready;
            counter_increment <= valid_reg && ready && (bit_counter != 3'b111);
        end
    end
    
    // 流水线阶段3: 计数器管理
    always @(posedge clk) begin
        if (clear) begin
            bit_counter <= 3'b0;
            data_capture_active <= 1'b0;
        end
        else begin
            if (counter_reset) begin
                bit_counter <= 3'b0;
                data_capture_active <= 1'b0;
            end
            else if (counter_increment) begin
                bit_counter <= bit_counter + 1'b1;
                data_capture_active <= 1'b1;
            end
        end
    end

    // 流水线阶段4: 数据路径 - 并行输出生成
    always @(posedge clk) begin
        if (clear) begin
            parallel_out <= 8'b0;
        end
        else if (state_update) begin
            // 串行到并行转换的移位寄存器
            parallel_out <= {parallel_out[6:0], serial_data_reg};
        end
    end

    // 流水线阶段5: 握手控制逻辑
    always @(posedge clk) begin
        if (clear) begin
            ready <= 1'b1;  // 初始状态为准备好接收数据
        end
        else begin
            if (counter_reset) begin
                // 8位接收完成后，撤销ready信号直到数据被消费
                ready <= 1'b0;
            end
            else if (!valid_reg && !ready) begin
                // 传输完成后重置ready信号
                ready <= 1'b1;
            end
        end
    end
endmodule