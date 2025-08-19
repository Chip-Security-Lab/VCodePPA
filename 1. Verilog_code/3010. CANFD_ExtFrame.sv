module CANFD_ExtFrame #(
    parameter DATA_WIDTH = 64,    // Max CAN FD data length
    parameter ID_WIDTH = 29       // Extended frame ID width
)(
    input wire clk,
    input wire rst_n,
    input wire can_rx,
    output reg can_tx,
    input wire [ID_WIDTH-1:0] ext_id,
    input wire [DATA_WIDTH-1:0] tx_payload,
    input wire tx_fd_enable,       // FD mode enable
    output reg [DATA_WIDTH-1:0] rx_payload,
    output reg [ID_WIDTH-1:0] rx_id,
    output reg rx_ext,             // Extended frame flag
    output reg rx_fd,              // FD frame flag
    input wire tx_start,
    output reg tx_done
);
    // Frame structure definitions
    localparam SOF = 1'b0;
    localparam EOF = 1'b1;
    
    // State definitions
    localparam IDLE = 3'd0;
    localparam SEND_SOF = 3'd1;
    localparam SEND_ID = 3'd2;
    localparam SEND_FD_FLAG = 3'd3;
    localparam SEND_DLC = 3'd4;
    localparam SEND_DATA = 3'd5;
    localparam SEND_CRC = 3'd6;
    localparam SEND_EOF = 3'd7;

    reg [2:0] tx_state;
    reg [7:0] bit_cnt;
    reg [ID_WIDTH-1:0] tx_id_reg;
    reg [DATA_WIDTH-1:0] tx_data_reg;
    reg [3:0] dlc;
    reg crc_enable;

    // Transmit state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= IDLE;
            can_tx <= 1'b1;
            tx_done <= 0;
            bit_cnt <= 0;
            tx_id_reg <= 0;
            tx_data_reg <= 0;
            dlc <= 0;
            crc_enable <= 0;
        end else begin
            case(tx_state)
                IDLE: if (tx_start) begin
                    tx_id_reg <= ext_id;
                    tx_data_reg <= tx_payload;
                    dlc <= (DATA_WIDTH+7)/8; // Calculate DLC
                    tx_state <= SEND_SOF;
                    tx_done <= 1'b0;
                end
                
                SEND_SOF: begin
                    can_tx <= SOF;
                    tx_state <= SEND_ID;
                    bit_cnt <= ID_WIDTH-1;
                end
                
                SEND_ID: begin
                    can_tx <= tx_id_reg[bit_cnt];
                    if (bit_cnt == 0) begin
                        tx_state <= SEND_FD_FLAG;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
                
                SEND_FD_FLAG: begin
                    can_tx <= tx_fd_enable;  // FD mode flag bit
                    tx_state <= SEND_DLC;
                    bit_cnt <= 3; // Set for DLC bits
                end
                
                SEND_DLC: begin
                    can_tx <= dlc[bit_cnt];
                    if (bit_cnt == 0) begin
                        tx_state <= SEND_DATA;
                        bit_cnt <= DATA_WIDTH-1;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
                
                SEND_DATA: begin
                    can_tx <= tx_data_reg[bit_cnt];
                    if (bit_cnt == 0) begin
                        tx_state <= SEND_CRC;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
                
                SEND_CRC: begin
                    // CRC generation logic (simplified)
                    can_tx <= ^tx_data_reg;  
                    tx_state <= SEND_EOF;
                end
                
                SEND_EOF: begin
                    can_tx <= EOF;
                    tx_done <= 1'b1;
                    tx_state <= IDLE;
                end
                
                default: begin
                    tx_state <= IDLE;
                end
            endcase
        end
    end

    // Receive logic (simplified for core structure)
    reg [ID_WIDTH-1:0] rx_id_reg;
    reg [DATA_WIDTH-1:0] rx_data_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_id_reg <= 0;
            rx_data_reg <= 0;
            rx_ext <= 0;
            rx_fd <= 0;
            rx_payload <= 0;
            rx_id <= 0;
        end else begin
            if (can_rx == SOF) begin
                rx_id_reg <= 0;
                rx_data_reg <= 0;
                rx_ext <= 1'b1;  // Identify extended frame
            end else if (rx_id_reg < ID_WIDTH) begin
                rx_id_reg <= {rx_id_reg[ID_WIDTH-2:0], can_rx};
            end else begin
                rx_data_reg <= {rx_data_reg[DATA_WIDTH-2:0], can_rx};
            end
            
            // Update outputs
            rx_payload <= rx_data_reg;
            rx_id <= rx_id_reg;
        end
    end
endmodule