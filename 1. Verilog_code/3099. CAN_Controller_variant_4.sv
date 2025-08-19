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
    
    localparam IDLE = 3'b000, SOF = 3'b001, ID_FIELD = 3'b010, 
             CTRL_FIELD = 3'b011, DATA_FIELD = 3'b100, 
             CRC_FIELD = 3'b101, ACK = 3'b110, EOF = 3'b111;
    reg [2:0] current_state, next_state;
    
    reg [15:0] bit_counter;
    reg [6:0] stuff_counter;
    reg [14:0] crc;
    reg [63:0] shift_reg;
    reg dominant_bit;
    reg sample_point;
    reg bit_count_enable;
    reg tx_active;
    
    wire bit_time_reached;
    wire [15:0] bit_time_minus_1;
    wire [15:0] bit_counter_next;
    wire sample_point_next;
    
    assign bit_time_minus_1 = BIT_TIME - 1;
    assign bit_time_reached = (bit_counter == bit_time_minus_1);
    assign bit_counter_next = bit_time_reached ? 16'd0 : bit_counter + 16'd1;
    assign sample_point_next = bit_time_reached & tx_active;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 16'd0;
            sample_point <= 1'b0;
            bit_count_enable <= 1'b0;
        end else if (tx_active) begin
            bit_counter <= bit_counter_next;
            sample_point <= sample_point_next;
        end else begin
            bit_counter <= 16'd0;
            sample_point <= 1'b0;
        end
    end

    wire [15:0] id_field_time;
    wire [15:0] ctrl_field_time;
    wire [15:0] data_field_time;
    wire [15:0] crc_field_time;
    wire [15:0] eof_time;
    
    assign id_field_time = BIT_TIME * 11;
    assign ctrl_field_time = BIT_TIME * 4;
    assign data_field_time = BIT_TIME * 64;
    assign crc_field_time = BIT_TIME * 15;
    assign eof_time = BIT_TIME * 7;
    
    wire stuff_counter_full;
    assign stuff_counter_full = (stuff_counter == 5);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            tx_ready <= 1'b1;
            stuff_counter <= 7'd0;
            crc <= 15'd0;
            shift_reg <= 64'd0;
            dominant_bit <= 1'b1;
            tx_active <= 1'b0;
            rx_data <= 64'd0;
            rx_valid <= 1'b0;
        end else begin
            current_state <= next_state;
            rx_valid <= 1'b0;
            
            case(current_state)
                IDLE: begin
                    tx_ready <= 1'b1;
                    if (tx_req) begin
                        shift_reg <= tx_data;
                        tx_active <= 1'b1;
                        tx_ready <= 1'b0;
                    end
                end
                SOF: begin
                    if (sample_point) begin
                        dominant_bit <= 1'b0;
                        stuff_counter <= 7'd1;
                    end
                end
                ID_FIELD: begin
                    if (sample_point) begin
                        dominant_bit <= shift_reg[63];
                        shift_reg <= {shift_reg[62:0], 1'b0};
                        
                        if (dominant_bit == shift_reg[63]) begin
                            stuff_counter <= stuff_counter + 7'd1;
                            if (stuff_counter_full) begin
                                dominant_bit <= ~dominant_bit;
                                stuff_counter <= 7'd0;
                            end
                        end else begin
                            stuff_counter <= 7'd1;
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
                    if (sample_point && rx_line == 1'b0) begin
                        // ACK received
                    end
                end
                EOF: begin
                    if (sample_point) begin
                        dominant_bit <= 1'b1;
                        if (bit_counter >= eof_time) begin
                            tx_active <= 1'b0;
                            tx_ready <= 1'b1;
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
            ID_FIELD: if (bit_counter >= id_field_time) next_state = CTRL_FIELD;
            CTRL_FIELD: if (bit_counter >= ctrl_field_time) next_state = DATA_FIELD;
            DATA_FIELD: if (bit_counter >= data_field_time) next_state = CRC_FIELD;
            CRC_FIELD: if (bit_counter >= crc_field_time) next_state = ACK;
            ACK: if (sample_point) next_state = EOF;
            EOF: if (bit_counter >= eof_time) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule