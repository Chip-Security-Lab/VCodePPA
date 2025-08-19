//SystemVerilog
module CAN_Controller #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 500_000
)(
    input clk, rst_n,
    input tx_req,
    input [63:0] tx_data,
    output reg tx_ready,
    input rx_line,
    output reg [63:0] rx_data,
    output reg rx_valid
);
    localparam BIT_TIME = CLK_FREQ / BAUD_RATE;
    
    localparam IDLE = 4'b0000, SOF = 4'b0001, ID_FIELD = 4'b0010, 
             CTRL_FIELD = 4'b0011, DATA_FIELD = 4'b0100, 
             CRC_FIELD = 4'b0101, ACK = 4'b0110, EOF = 4'b0111;
    reg [3:0] current_state, next_state;
    
    reg [15:0] bit_counter;
    reg [6:0] stuff_counter;
    reg [14:0] crc;
    reg [63:0] shift_reg;
    reg dominant_bit;
    reg sample_point;
    reg bit_count_enable;
    reg tx_active;
    
    wire bit_time_end = (bit_counter == BIT_TIME-1);
    wire [15:0] bit_time_11 = BIT_TIME * 11;
    wire [15:0] bit_time_4 = BIT_TIME * 4;
    wire [15:0] bit_time_64 = BIT_TIME * 64;
    wire [15:0] bit_time_15 = BIT_TIME * 15;
    wire [15:0] bit_time_7 = BIT_TIME * 7;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
            sample_point <= 0;
            bit_count_enable <= 0;
        end else if (tx_active) begin
            bit_counter <= bit_time_end ? 0 : bit_counter + 1;
            sample_point <= bit_time_end;
        end else begin
            bit_counter <= 0;
            sample_point <= 0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            tx_ready <= 1;
            stuff_counter <= 0;
            crc <= 0;
            shift_reg <= 0;
            dominant_bit <= 1;
            tx_active <= 0;
            rx_data <= 0;
            rx_valid <= 0;
        end else begin
            current_state <= next_state;
            rx_valid <= 0;
            
            case(current_state)
                IDLE: begin
                    tx_ready <= 1;
                    if (tx_req) begin
                        shift_reg <= tx_data;
                        tx_active <= 1;
                        tx_ready <= 0;
                    end
                end
                SOF: begin
                    if (sample_point) begin
                        dominant_bit <= 0;
                        stuff_counter <= 1;
                    end
                end
                ID_FIELD: begin
                    if (sample_point) begin
                        dominant_bit <= shift_reg[63];
                        shift_reg <= {shift_reg[62:0], 1'b0};
                        
                        if (dominant_bit == shift_reg[63]) begin
                            stuff_counter <= (stuff_counter == 5) ? 0 : stuff_counter + 1;
                            dominant_bit <= (stuff_counter == 5) ? ~dominant_bit : dominant_bit;
                        end else begin
                            stuff_counter <= 1;
                        end
                    end
                end
                DATA_FIELD, CTRL_FIELD: begin
                    if (sample_point) begin
                        dominant_bit <= shift_reg[63];
                        shift_reg <= {shift_reg[62:0], 1'b0};
                    end
                end
                CRC_FIELD: begin
                    if (sample_point) begin
                        dominant_bit <= crc[14];
                        crc <= {crc[13:0], 1'b0};
                    end
                end
                ACK: begin
                    if (sample_point) begin
                        if (rx_line == 0) begin
                        end
                    end
                end
                EOF: begin
                    if (sample_point) begin
                        dominant_bit <= 1;
                        if (bit_counter >= bit_time_7) begin
                            tx_active <= 0;
                            tx_ready <= 1;
                        end
                    end
                end
                default: ;
            endcase
        end
    end

    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: if (tx_req && tx_ready) next_state = SOF;
            SOF: if (sample_point) next_state = ID_FIELD;
            ID_FIELD: if (bit_counter >= bit_time_11) next_state = CTRL_FIELD;
            CTRL_FIELD: if (bit_counter >= bit_time_4) next_state = DATA_FIELD;
            DATA_FIELD: if (bit_counter >= bit_time_64) next_state = CRC_FIELD;
            CRC_FIELD: if (bit_counter >= bit_time_15) next_state = ACK;
            ACK: if (sample_point) next_state = EOF;
            EOF: if (bit_counter >= bit_time_7) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule