//SystemVerilog
module eth_pause_frame_gen (
    input wire clk,
    input wire reset,
    input wire generate_pause,
    input wire [15:0] pause_time,
    input wire [47:0] local_mac,
    output reg [7:0] tx_data,
    output reg tx_en,
    output reg frame_complete
);
    // Multicast MAC address for PAUSE frames
    localparam [47:0] PAUSE_ADDR = 48'h010000C28001;
    localparam [15:0] MAC_CONTROL = 16'h8808;
    localparam [15:0] PAUSE_OPCODE = 16'h0001;
    
    // 状态定义
    localparam IDLE = 5'd0, PREAMBLE = 5'd1, SFD = 5'd2;
    localparam DST_ADDR = 5'd3, SRC_ADDR = 5'd4, LENGTH = 5'd5;
    localparam OPCODE = 5'd6, PAUSE_PARAM = 5'd7, PAD = 5'd8, FCS = 5'd9;
    
    // 流水线阶段定义
    localparam STAGE_CONTROL = 2'd0;
    localparam STAGE_PREPARE = 2'd1;
    localparam STAGE_TRANSMIT = 2'd2;
    
    // 阶段1: 控制逻辑
    reg [4:0] state_stage1;
    reg [3:0] counter_stage1;
    reg generate_pause_stage1;
    reg [15:0] pause_time_stage1;
    reg [47:0] local_mac_stage1;
    reg valid_stage1;
    
    // 阶段2: 数据准备
    reg [4:0] state_stage2;
    reg [3:0] counter_stage2;
    reg [7:0] tx_data_stage2;
    reg tx_en_stage2;
    reg frame_complete_stage2;
    reg valid_stage2;
    reg [15:0] pause_time_stage2;
    reg [47:0] local_mac_stage2;
    
    // 阶段3: 数据传输
    reg [4:0] next_state_stage3;
    reg [3:0] next_counter_stage3;
    reg valid_stage3;
    
    // 流水线控制信号
    reg pipeline_flush;
    
    // 阶段1: 控制逻辑 - 状态转换和控制信号计算
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage1 <= IDLE;
            counter_stage1 <= 4'd0;
            generate_pause_stage1 <= 1'b0;
            pause_time_stage1 <= 16'd0;
            local_mac_stage1 <= 48'd0;
            valid_stage1 <= 1'b0;
            pipeline_flush <= 1'b0;
        end else begin
            // 默认保持当前值
            valid_stage1 <= 1'b0;
            pipeline_flush <= 1'b0;
            
            if (state_stage1 == IDLE) begin
                if (generate_pause) begin
                    state_stage1 <= PREAMBLE;
                    counter_stage1 <= 4'd0;
                    generate_pause_stage1 <= 1'b1;
                    pause_time_stage1 <= pause_time;
                    local_mac_stage1 <= local_mac;
                    valid_stage1 <= 1'b1;
                end else begin
                    generate_pause_stage1 <= 1'b0;
                end
            end
            else if (state_stage1 == PREAMBLE) begin
                if (counter_stage1 == 4'd6) begin
                    state_stage1 <= SFD;
                    counter_stage1 <= 4'd0;
                end else
                    counter_stage1 <= counter_stage1 + 1'b1;
                valid_stage1 <= 1'b1;
            end
            else if (state_stage1 == SFD) begin
                state_stage1 <= DST_ADDR;
                counter_stage1 <= 4'd0;
                valid_stage1 <= 1'b1;
            end
            else if (state_stage1 == DST_ADDR) begin
                if (counter_stage1 == 4'd5) begin
                    state_stage1 <= SRC_ADDR;
                    counter_stage1 <= 4'd0;
                end else
                    counter_stage1 <= counter_stage1 + 1'b1;
                valid_stage1 <= 1'b1;
            end
            else if (state_stage1 == SRC_ADDR) begin
                if (counter_stage1 == 4'd5) begin
                    state_stage1 <= LENGTH;
                    counter_stage1 <= 4'd0;
                end else
                    counter_stage1 <= counter_stage1 + 1'b1;
                valid_stage1 <= 1'b1;
            end
            else if (state_stage1 == LENGTH) begin
                if (counter_stage1 == 4'd0) begin
                    counter_stage1 <= counter_stage1 + 1'b1;
                end else begin
                    state_stage1 <= OPCODE;
                    counter_stage1 <= 4'd0;
                end
                valid_stage1 <= 1'b1;
            end
            else if (state_stage1 == OPCODE) begin
                if (counter_stage1 == 4'd0) begin
                    counter_stage1 <= counter_stage1 + 1'b1;
                end else begin
                    state_stage1 <= PAUSE_PARAM;
                    counter_stage1 <= 4'd0;
                end
                valid_stage1 <= 1'b1;
            end
            else if (state_stage1 == PAUSE_PARAM) begin
                if (counter_stage1 == 4'd0) begin
                    counter_stage1 <= counter_stage1 + 1'b1;
                end else begin
                    state_stage1 <= PAD;
                    counter_stage1 <= 4'd0;
                end
                valid_stage1 <= 1'b1;
            end
            else if (state_stage1 == PAD) begin
                if (counter_stage1 == 4'd9) begin
                    state_stage1 <= FCS;
                    counter_stage1 <= 4'd0;
                end else
                    counter_stage1 <= counter_stage1 + 1'b1;
                valid_stage1 <= 1'b1;
            end
            else if (state_stage1 == FCS) begin
                if (counter_stage1 == 4'd3) begin
                    state_stage1 <= IDLE;
                    pipeline_flush <= 1'b1;
                end else
                    counter_stage1 <= counter_stage1 + 1'b1;
                valid_stage1 <= 1'b1;
            end
        end
    end
    
    // 阶段2: 数据准备 - 生成传输数据
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage2 <= IDLE;
            counter_stage2 <= 4'd0;
            tx_data_stage2 <= 8'd0;
            tx_en_stage2 <= 1'b0;
            frame_complete_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            pause_time_stage2 <= 16'd0;
            local_mac_stage2 <= 48'd0;
        end else begin
            if (pipeline_flush) begin
                valid_stage2 <= 1'b0;
                tx_en_stage2 <= 1'b0;
            end else if (valid_stage1) begin
                state_stage2 <= state_stage1;
                counter_stage2 <= counter_stage1;
                pause_time_stage2 <= pause_time_stage1;
                local_mac_stage2 <= local_mac_stage1;
                valid_stage2 <= 1'b1;
                frame_complete_stage2 <= 1'b0;
                
                if (state_stage1 == IDLE) begin
                    tx_en_stage2 <= generate_pause_stage1;
                end
                else if (state_stage1 == PREAMBLE) begin
                    tx_data_stage2 <= 8'h55;
                    tx_en_stage2 <= 1'b1;
                end
                else if (state_stage1 == SFD) begin
                    tx_data_stage2 <= 8'hD5;
                    tx_en_stage2 <= 1'b1;
                end
                else if (state_stage1 == DST_ADDR) begin
                    if (counter_stage1 == 4'd0)
                        tx_data_stage2 <= PAUSE_ADDR[47:40];
                    else if (counter_stage1 == 4'd1)
                        tx_data_stage2 <= PAUSE_ADDR[39:32];
                    else if (counter_stage1 == 4'd2)
                        tx_data_stage2 <= PAUSE_ADDR[31:24];
                    else if (counter_stage1 == 4'd3)
                        tx_data_stage2 <= PAUSE_ADDR[23:16];
                    else if (counter_stage1 == 4'd4)
                        tx_data_stage2 <= PAUSE_ADDR[15:8];
                    else
                        tx_data_stage2 <= PAUSE_ADDR[7:0];
                    tx_en_stage2 <= 1'b1;
                end
                else if (state_stage1 == SRC_ADDR) begin
                    if (counter_stage1 == 4'd0)
                        tx_data_stage2 <= local_mac_stage1[47:40];
                    else if (counter_stage1 == 4'd1)
                        tx_data_stage2 <= local_mac_stage1[39:32];
                    else if (counter_stage1 == 4'd2)
                        tx_data_stage2 <= local_mac_stage1[31:24];
                    else if (counter_stage1 == 4'd3)
                        tx_data_stage2 <= local_mac_stage1[23:16];
                    else if (counter_stage1 == 4'd4)
                        tx_data_stage2 <= local_mac_stage1[15:8];
                    else
                        tx_data_stage2 <= local_mac_stage1[7:0];
                    tx_en_stage2 <= 1'b1;
                end
                else if (state_stage1 == LENGTH) begin
                    if (counter_stage1 == 4'd0) begin
                        tx_data_stage2 <= MAC_CONTROL[15:8];
                    end else begin
                        tx_data_stage2 <= MAC_CONTROL[7:0];
                    end
                    tx_en_stage2 <= 1'b1;
                end
                else if (state_stage1 == OPCODE) begin
                    if (counter_stage1 == 4'd0) begin
                        tx_data_stage2 <= PAUSE_OPCODE[15:8];
                    end else begin
                        tx_data_stage2 <= PAUSE_OPCODE[7:0];
                    end
                    tx_en_stage2 <= 1'b1;
                end
                else if (state_stage1 == PAUSE_PARAM) begin
                    if (counter_stage1 == 4'd0) begin
                        tx_data_stage2 <= pause_time_stage1[15:8];
                    end else begin
                        tx_data_stage2 <= pause_time_stage1[7:0];
                    end
                    tx_en_stage2 <= 1'b1;
                end
                else if (state_stage1 == PAD) begin
                    tx_data_stage2 <= 8'h00;
                    tx_en_stage2 <= 1'b1;
                end
                else if (state_stage1 == FCS) begin
                    // Simplified FCS - in a real design this would be calculated
                    tx_data_stage2 <= 8'hAA;
                    tx_en_stage2 <= 1'b1;
                    if (counter_stage1 == 4'd3) begin
                        frame_complete_stage2 <= 1'b1;
                    end
                end
            end
        end
    end
    
    // 阶段3: 数据传输 - 输出和处理下一个状态
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_data <= 8'd0;
            tx_en <= 1'b0;
            frame_complete <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            if (pipeline_flush) begin
                valid_stage3 <= 1'b0;
                tx_en <= 1'b0;
                frame_complete <= 1'b0;
            end else if (valid_stage2) begin
                // 传递数据到输出
                tx_data <= tx_data_stage2;
                tx_en <= tx_en_stage2;
                frame_complete <= frame_complete_stage2;
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 1'b0;
                tx_en <= 1'b0;
            end
        end
    end

endmodule