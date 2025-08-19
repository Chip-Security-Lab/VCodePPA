module pause_frame_gen #(
    parameter QUANTUM = 16'hFFFF,
    parameter THRESHOLD = 16'h00FF
)(
    input clk,
    input rst,
    input pause_req,
    input [15:0] rx_pause,
    output reg [7:0] tx_data,
    output reg tx_valid,
    output reg tx_enable
);
    // Replace typedef enum with localparam
    localparam IDLE = 4'h0;
    localparam PREAMBLE = 4'h1; 
    localparam SFD = 4'h2;
    localparam MAC_HEADER = 4'h3;
    localparam ETH_TYPE = 4'h4;
    localparam OPCODE = 4'h5;
    localparam QUANTUM_VAL = 4'h6;
    localparam FCS = 4'h7;
    localparam HOLD = 4'h8;
    
    reg [3:0] state;
    reg [3:0] byte_cnt;
    reg [31:0] crc;
    reg [31:0] next_crc;
    reg [15:0] pause_timer;
    reg [63:0] mac_header;

    // Precomputed MAC header (DA+SA)
    wire [95:0] PAUSE_MAC = {
        8'h01, 8'h80, 8'hC2, 8'h00, 8'h00, 8'h01,  // Dest MAC
        8'h00, 8'h11, 8'h22, 8'h33, 8'h44, 8'h55   // Src MAC
    };

    // CRC32 Calculation - unroll the for loop
    always @(*) begin
        next_crc = crc;
        next_crc = (next_crc << 1) ^ ((next_crc[31] ^ tx_data[7]) ? 32'h04C11DB7 : 32'h0);
        next_crc = (next_crc << 1) ^ ((next_crc[31] ^ tx_data[6]) ? 32'h04C11DB7 : 32'h0);
        next_crc = (next_crc << 1) ^ ((next_crc[31] ^ tx_data[5]) ? 32'h04C11DB7 : 32'h0);
        next_crc = (next_crc << 1) ^ ((next_crc[31] ^ tx_data[4]) ? 32'h04C11DB7 : 32'h0);
        next_crc = (next_crc << 1) ^ ((next_crc[31] ^ tx_data[3]) ? 32'h04C11DB7 : 32'h0);
        next_crc = (next_crc << 1) ^ ((next_crc[31] ^ tx_data[2]) ? 32'h04C11DB7 : 32'h0);
        next_crc = (next_crc << 1) ^ ((next_crc[31] ^ tx_data[1]) ? 32'h04C11DB7 : 32'h0);
        next_crc = (next_crc << 1) ^ ((next_crc[31] ^ tx_data[0]) ? 32'h04C11DB7 : 32'h0);
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            tx_data <= 0;
            tx_valid <= 0;
            tx_enable <= 0;
            byte_cnt <= 0;
            crc <= 32'hFFFFFFFF;
            pause_timer <= 0;
        end else begin
            case(state)
                IDLE: begin
                    tx_valid <= 0;
                    if (pause_req || (rx_pause > THRESHOLD)) begin
                        state <= PREAMBLE;
                        tx_enable <= 1;
                        crc <= 32'hFFFFFFFF;
                        byte_cnt <= 0;
                    end
                end

                PREAMBLE: begin
                    tx_data <= (byte_cnt < 7) ? 8'h55 : 8'hD5;
                    tx_valid <= 1;
                    crc <= (byte_cnt == 7) ? next_crc : crc;
                    if (byte_cnt == 7) begin
                        state <= MAC_HEADER;
                        byte_cnt <= 0;
                    end else begin
                        byte_cnt <= byte_cnt + 1;
                    end
                end

                MAC_HEADER: begin
                    tx_data <= PAUSE_MAC[8*byte_cnt +: 8];
                    tx_valid <= 1;
                    crc <= next_crc;
                    if (byte_cnt == 11) begin
                        state <= ETH_TYPE;
                        byte_cnt <= 0;
                    end else begin
                        byte_cnt <= byte_cnt + 1;
                    end
                end

                ETH_TYPE: begin
                    tx_data <= (byte_cnt == 0) ? 8'h88 : 8'h08;
                    tx_valid <= 1;
                    crc <= next_crc;
                    byte_cnt <= byte_cnt + 1;
                    if (byte_cnt == 1) state <= OPCODE;
                end

                OPCODE: begin
                    tx_data <= (byte_cnt == 0) ? 8'h00 : 8'h01;  // Pause Opcode
                    tx_valid <= 1;
                    crc <= next_crc;
                    byte_cnt <= byte_cnt + 1;
                    if (byte_cnt == 1) state <= QUANTUM_VAL;
                end

                QUANTUM_VAL: begin
                    tx_data <= (byte_cnt[0]) ? QUANTUM[15:8] : QUANTUM[7:0];
                    tx_valid <= 1;
                    crc <= next_crc;
                    byte_cnt <= byte_cnt + 1;
                    if (byte_cnt == 1) state <= FCS;
                end

                FCS: begin
                    tx_data <= ~crc[31:24];
                    tx_valid <= 1;
                    crc <= {crc[23:0], 8'hFF};
                    if (byte_cnt == 3) begin
                        state <= HOLD;
                        byte_cnt <= 0;
                    end else begin
                        byte_cnt <= byte_cnt + 1;
                    end
                end

                HOLD: begin
                    tx_valid <= 0;
                    tx_enable <= 0;
                    if (pause_timer == 16'hFFFF) begin
                        state <= IDLE;
                        pause_timer <= 0;
                    end else begin
                        pause_timer <= pause_timer + 1;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule