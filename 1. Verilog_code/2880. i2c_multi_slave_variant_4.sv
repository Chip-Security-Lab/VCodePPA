//SystemVerilog
module i2c_multi_slave #(
    parameter ADDR_COUNT = 4,
    parameter ADDR_WIDTH = 7
)(
    input clk,
    input rst_sync_n,
    inout sda,
    inout scl,
    output reg [7:0] data_out [0:ADDR_COUNT-1],
    input [7:0] addr_mask [0:ADDR_COUNT-1]
);
    // Unique feature: Four address matching engines
    reg [ADDR_WIDTH-1:0] recv_addr;
    reg addr_valid [0:ADDR_COUNT-1];
    reg [7:0] shift_reg;
    reg data_valid;
    reg [3:0] bit_counter;
    reg scl_prev, scl_prev2;
    reg start_detected, start_detected_pipe;
    reg stop_detected, stop_detected_pipe;
    reg sda_prev, sda_prev2;
    
    // Pipeline registers for critical paths
    reg [7:0] shift_reg_pipe;
    reg [3:0] bit_counter_pipe;
    reg scl_edge_pipe;
    reg data_valid_pipe;
    reg [ADDR_WIDTH-1:0] addr_match_temp [0:ADDR_COUNT-1];
    reg [ADDR_WIDTH-1:0] addr_mask_pipe [0:ADDR_COUNT-1];
    
    // 初始化所有寄存器
    integer j;
    initial begin
        recv_addr = 0;
        data_valid = 0;
        data_valid_pipe = 0;
        shift_reg = 0;
        shift_reg_pipe = 0;
        bit_counter = 0;
        bit_counter_pipe = 0;
        scl_prev = 1;
        scl_prev2 = 1;
        sda_prev = 1;
        sda_prev2 = 1;
        start_detected = 0;
        start_detected_pipe = 0;
        stop_detected = 0;
        stop_detected_pipe = 0;
        scl_edge_pipe = 0;
        for (j=0; j<ADDR_COUNT; j=j+1) begin
            addr_valid[j] = 0;
            data_out[j] = 0;
            addr_match_temp[j] = 0;
            addr_mask_pipe[j] = 0;
        end
    end

    // 双级缓存输入信号以防止亚稳态
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            sda_prev <= 1;
            sda_prev2 <= 1;
            scl_prev <= 1;
            scl_prev2 <= 1;
        end else begin
            sda_prev2 <= sda;
            sda_prev <= sda_prev2;
            scl_prev2 <= scl;
            scl_prev <= scl_prev2;
        end
    end

    // 开始和停止条件检测 - 阶段1
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            start_detected <= 0;
            stop_detected <= 0;
        end else begin
            // 开始条件：SCL高电平时SDA从高变低
            if (scl_prev && !sda_prev && sda_prev2)
                start_detected <= 1'b1;
            else
                start_detected <= 1'b0;
                
            // 停止条件：SCL高电平时SDA从低变高
            if (scl_prev && sda_prev && !sda_prev2)
                stop_detected <= 1'b1;
            else
                stop_detected <= 1'b0;
        end
    end

    // 开始和停止条件流水线 - 阶段2
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            start_detected_pipe <= 0;
            stop_detected_pipe <= 0;
            scl_edge_pipe <= 0;
        end else begin
            start_detected_pipe <= start_detected;
            stop_detected_pipe <= stop_detected;
            scl_edge_pipe <= scl_prev && !scl_prev2; // SCL上升沿检测
        end
    end

    // 位计数器模块 - 分为两个阶段
    // 阶段1 - 检测条件和提前准备
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            bit_counter <= 4'd0;
        end else if (start_detected_pipe) begin
            bit_counter <= 4'd0;
        end else if (stop_detected_pipe) begin
            bit_counter <= 4'd0;
        end else if (scl_edge_pipe) begin
            // SCL上升沿，增加计数
            bit_counter <= (bit_counter == 4'd8) ? 4'd1 : (bit_counter + 4'd1);
        end
    end

    // 阶段2 - 位计数器流水线
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            bit_counter_pipe <= 4'd0;
        end else begin
            bit_counter_pipe <= bit_counter;
        end
    end

    // 数据接收模块 - 阶段1
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            shift_reg <= 8'h00;
        end else if (start_detected_pipe) begin
            shift_reg <= 8'h00;
        end else if (scl_edge_pipe) begin
            // SCL上升沿时移入数据
            shift_reg <= {shift_reg[6:0], sda_prev};
        end
    end

    // 数据接收流水线 - 阶段2
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            shift_reg_pipe <= 8'h00;
        end else begin
            shift_reg_pipe <= shift_reg;
        end
    end

    // 地址捕获模块 - 使用流水线结果
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            recv_addr <= {ADDR_WIDTH{1'b0}};
        end else if (bit_counter_pipe == 4'd8 && scl_edge_pipe) begin
            recv_addr <= shift_reg[ADDR_WIDTH-1:0];
        end
    end

    // 数据有效标志模块
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            data_valid <= 1'b0;
        end else if (start_detected_pipe) begin
            data_valid <= 1'b0;
        end else if (bit_counter_pipe == 4'd8 && scl_edge_pipe) begin
            data_valid <= 1'b1;
        end else begin
            data_valid <= 1'b0;
        end
    end

    // 数据有效标志流水线 - 阶段2
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            data_valid_pipe <= 1'b0;
        end else begin
            data_valid_pipe <= data_valid;
        end
    end

    // 地址匹配输入流水线 - 分为两个阶段
    // 阶段1 - 缓存匹配地址
    always @(posedge clk) begin
        for (j=0; j<ADDR_COUNT; j=j+1) begin
            addr_mask_pipe[j] <= addr_mask[j][ADDR_WIDTH-1:0];
        end
    end

    // 地址匹配逻辑 - 阶段1：准备匹配结果
    genvar i;
    generate
        for (i=0; i<ADDR_COUNT; i=i+1) begin : addr_match_prep
            always @(posedge clk or negedge rst_sync_n) begin
                if (!rst_sync_n)
                    addr_match_temp[i] <= 0;
                else if (bit_counter_pipe == 4'd8 && scl_edge_pipe)
                    addr_match_temp[i] <= shift_reg[ADDR_WIDTH-1:0] & addr_mask_pipe[i];
            end
        end
    endgenerate

    // 地址匹配逻辑 - 阶段2：完成匹配计算
    generate
        for (i=0; i<ADDR_COUNT; i=i+1) begin : addr_filter
            always @(posedge clk or negedge rst_sync_n) begin
                if (!rst_sync_n)
                    addr_valid[i] <= 0;
                else if (bit_counter_pipe == 4'd8 && scl_edge_pipe)
                    addr_valid[i] <= (shift_reg[ADDR_WIDTH-1:0] == addr_mask_pipe[i]) || 
                                   (addr_match_temp[i] == addr_mask_pipe[i]);
            end
        end
    endgenerate

    // 数据输出模块
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            for (j=0; j<ADDR_COUNT; j=j+1)
                data_out[j] <= 8'h00;
        end else begin
            for (j=0; j<ADDR_COUNT; j=j+1) begin
                if (addr_valid[j] && data_valid_pipe) begin
                    data_out[j] <= shift_reg_pipe;
                end
            end
        end
    end
endmodule