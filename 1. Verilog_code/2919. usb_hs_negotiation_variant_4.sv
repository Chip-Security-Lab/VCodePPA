//SystemVerilog
module usb_hs_negotiation(
    input wire clk,
    input wire rst_n,
    input wire chirp_start,
    input wire dp_in,
    input wire dm_in,
    output reg dp_out,
    output reg dm_out,
    output reg dp_oe,
    output reg dm_oe,
    output reg hs_detected,
    output reg [6:0] chirp_state,
    output reg [1:0] speed_status
);
    // Chirp state machine states (one-cold encoding)
    localparam IDLE      = 7'b1111110;  // Only bit 0 is cold (0)
    localparam K_CHIRP   = 7'b1111101;  // Only bit 1 is cold (0)
    localparam J_DETECT  = 7'b1111011;  // Only bit 2 is cold (0)
    localparam K_DETECT  = 7'b1110111;  // Only bit 3 is cold (0)
    localparam HANDSHAKE = 7'b1101111;  // Only bit 4 is cold (0)
    localparam COMPLETE  = 7'b1011111;  // Only bit 5 is cold (0)
    localparam RESERVED  = 7'b0111111;  // Only bit 6 is cold (0)
    
    // Speed status values
    localparam FULLSPEED = 2'd0;
    localparam HIGHSPEED = 2'd1;
    
    reg [15:0] chirp_counter;
    reg [2:0] kj_count;
    
    // 状态转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            chirp_state <= IDLE;
        end else begin
            case (chirp_state)
                IDLE: begin
                    if (chirp_start) begin
                        chirp_state <= K_CHIRP;
                    end
                end
                K_CHIRP: begin
                    if (chirp_counter >= 16'd7500) begin  // ~156.25µs for K chirp
                        chirp_state <= J_DETECT;
                    end
                end
                J_DETECT: begin
                    // 状态转换逻辑
                end
                K_DETECT: begin
                    // 状态转换逻辑
                end
                HANDSHAKE: begin
                    // 状态转换逻辑
                end
                COMPLETE: begin
                    // 状态转换逻辑
                end
                default: begin
                    chirp_state <= IDLE;
                end
            endcase
        end
    end
    
    // 速度状态逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            speed_status <= FULLSPEED;
        end else begin
            if (chirp_state == COMPLETE && hs_detected) begin
                speed_status <= HIGHSPEED;
            end else if (chirp_state == IDLE) begin
                speed_status <= FULLSPEED;
            end
        end
    end
    
    // HS检测逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hs_detected <= 1'b0;
        end else begin
            // 这里实现高速检测逻辑
            if (chirp_state == HANDSHAKE && kj_count >= 3'd3) begin
                hs_detected <= 1'b1;
            end else if (chirp_state == IDLE) begin
                hs_detected <= 1'b0;
            end
        end
    end
    
    // 数据输出控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_out <= 1'b1;  // J state (fullspeed idle)
            dm_out <= 1'b0;
        end else begin
            case (chirp_state)
                IDLE: begin
                    dp_out <= 1'b1;  // J state (fullspeed idle)
                    dm_out <= 1'b0;
                end
                K_CHIRP: begin
                    dp_out <= 1'b0;  // K state chirp
                    dm_out <= 1'b1;
                end
                default: begin
                    // 其他状态的输出控制
                end
            endcase
        end
    end
    
    // 数据方向控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_oe <= 1'b0;
            dm_oe <= 1'b0;
        end else begin
            case (chirp_state)
                IDLE: begin
                    if (chirp_start) begin
                        dp_oe <= 1'b1;
                        dm_oe <= 1'b1;
                    end
                end
                K_CHIRP: begin
                    dp_oe <= 1'b1;
                    dm_oe <= 1'b1;
                    if (chirp_counter >= 16'd7500) begin
                        dp_oe <= 1'b0;
                        dm_oe <= 1'b0;
                    end
                end
                default: begin
                    // 其他状态的方向控制
                end
            endcase
        end
    end
    
    // 计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            chirp_counter <= 16'd0;
            kj_count <= 3'd0;
        end else begin
            case (chirp_state)
                IDLE: begin
                    chirp_counter <= 16'd0;
                    kj_count <= 3'd0;
                end
                K_CHIRP: begin
                    chirp_counter <= chirp_counter + 16'd1;
                    if (chirp_counter >= 16'd7500) begin
                        chirp_counter <= 16'd0;
                    end
                end
                J_DETECT, K_DETECT: begin
                    chirp_counter <= chirp_counter + 16'd1;
                    // KJ转换计数逻辑
                end
                default: begin
                    // 其他状态的计数器逻辑
                end
            endcase
        end
    end
endmodule