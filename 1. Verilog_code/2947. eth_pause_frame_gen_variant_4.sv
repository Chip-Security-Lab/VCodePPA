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
    
    reg [4:0] state, next_state;
    reg [3:0] counter, next_counter;
    reg [7:0] next_tx_data;
    reg next_tx_en;
    reg next_frame_complete;
    
    // 输入寄存器
    reg generate_pause_r;
    reg [15:0] pause_time_r;
    reg [47:0] local_mac_r;
    
    localparam IDLE = 5'd0, PREAMBLE = 5'd1, SFD = 5'd2;
    localparam DST_ADDR = 5'd3, SRC_ADDR = 5'd4, LENGTH = 5'd5;
    localparam OPCODE = 5'd6, PAUSE_PARAM = 5'd7, PAD = 5'd8, FCS = 5'd9;
    
    // 寄存器输入信号
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            generate_pause_r <= 1'b0;
            pause_time_r <= 16'd0;
            local_mac_r <= 48'd0;
        end else begin
            generate_pause_r <= generate_pause;
            pause_time_r <= pause_time;
            local_mac_r <= local_mac;
        end
    end
    
    // 组合逻辑部分 - 计算下一个状态和输出 - 扁平化条件结构
    always @(*) begin
        // 默认赋值
        next_state = state;
        next_counter = counter;
        next_tx_data = tx_data;
        next_tx_en = tx_en;
        next_frame_complete = frame_complete;
        
        // IDLE状态处理
        if (state == IDLE && generate_pause_r) begin
            next_state = PREAMBLE;
            next_counter = 4'd0;
            next_tx_en = 1'b1;
            next_frame_complete = 1'b0;
        end else if (state == IDLE) begin
            next_tx_en = 1'b0;
        end
        
        // PREAMBLE状态处理
        if (state == PREAMBLE) begin
            next_tx_data = 8'h55;
            if (counter == 4'd6) begin
                next_state = SFD;
                next_counter = 4'd0;
            end else begin
                next_counter = counter + 1'b1;
            end
        end
        
        // SFD状态处理
        if (state == SFD) begin
            next_tx_data = 8'hD5;
            next_state = DST_ADDR;
            next_counter = 4'd0;
        end
        
        // DST_ADDR状态处理
        if (state == DST_ADDR && counter == 4'd0) begin
            next_tx_data = PAUSE_ADDR[47:40];
            next_counter = counter + 1'b1;
        end else if (state == DST_ADDR && counter == 4'd1) begin
            next_tx_data = PAUSE_ADDR[39:32];
            next_counter = counter + 1'b1;
        end else if (state == DST_ADDR && counter == 4'd2) begin
            next_tx_data = PAUSE_ADDR[31:24];
            next_counter = counter + 1'b1;
        end else if (state == DST_ADDR && counter == 4'd3) begin
            next_tx_data = PAUSE_ADDR[23:16];
            next_counter = counter + 1'b1;
        end else if (state == DST_ADDR && counter == 4'd4) begin
            next_tx_data = PAUSE_ADDR[15:8];
            next_counter = counter + 1'b1;
        end else if (state == DST_ADDR && counter == 4'd5) begin
            next_tx_data = PAUSE_ADDR[7:0];
            next_state = SRC_ADDR;
            next_counter = 4'd0;
        end
        
        // SRC_ADDR状态处理
        if (state == SRC_ADDR && counter == 4'd0) begin
            next_tx_data = local_mac_r[47:40];
            next_counter = counter + 1'b1;
        end else if (state == SRC_ADDR && counter == 4'd1) begin
            next_tx_data = local_mac_r[39:32];
            next_counter = counter + 1'b1;
        end else if (state == SRC_ADDR && counter == 4'd2) begin
            next_tx_data = local_mac_r[31:24];
            next_counter = counter + 1'b1;
        end else if (state == SRC_ADDR && counter == 4'd3) begin
            next_tx_data = local_mac_r[23:16];
            next_counter = counter + 1'b1;
        end else if (state == SRC_ADDR && counter == 4'd4) begin
            next_tx_data = local_mac_r[15:8];
            next_counter = counter + 1'b1;
        end else if (state == SRC_ADDR && counter == 4'd5) begin
            next_tx_data = local_mac_r[7:0];
            next_state = LENGTH;
            next_counter = 4'd0;
        end
        
        // LENGTH状态处理
        if (state == LENGTH && counter == 4'd0) begin
            next_tx_data = MAC_CONTROL[15:8];
            next_counter = counter + 1'b1;
        end else if (state == LENGTH && counter == 4'd1) begin
            next_tx_data = MAC_CONTROL[7:0];
            next_state = OPCODE;
            next_counter = 4'd0;
        end
        
        // OPCODE状态处理
        if (state == OPCODE && counter == 4'd0) begin
            next_tx_data = PAUSE_OPCODE[15:8];
            next_counter = counter + 1'b1;
        end else if (state == OPCODE && counter == 4'd1) begin
            next_tx_data = PAUSE_OPCODE[7:0];
            next_state = PAUSE_PARAM;
            next_counter = 4'd0;
        end
        
        // PAUSE_PARAM状态处理
        if (state == PAUSE_PARAM && counter == 4'd0) begin
            next_tx_data = pause_time_r[15:8];
            next_counter = counter + 1'b1;
        end else if (state == PAUSE_PARAM && counter == 4'd1) begin
            next_tx_data = pause_time_r[7:0];
            next_state = PAD;
            next_counter = 4'd0;
        end
        
        // PAD状态处理
        if (state == PAD) begin
            next_tx_data = 8'h00;
            if (counter == 4'd9) begin
                next_state = FCS;
                next_counter = 4'd0;
            end else begin
                next_counter = counter + 1'b1;
            end
        end
        
        // FCS状态处理
        if (state == FCS) begin
            next_tx_data = 8'hAA;
            if (counter == 4'd3) begin
                next_state = IDLE;
                next_frame_complete = 1'b1;
                next_tx_en = 1'b0;
            end else begin
                next_counter = counter + 1'b1;
            end
        end
    end
    
    // 状态寄存器和输出寄存器更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            counter <= 4'd0;
            tx_en <= 1'b0;
            tx_data <= 8'd0;
            frame_complete <= 1'b0;
        end else begin
            state <= next_state;
            counter <= next_counter;
            tx_en <= next_tx_en;
            tx_data <= next_tx_data;
            frame_complete <= next_frame_complete;
        end
    end
endmodule