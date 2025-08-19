//SystemVerilog
module SPI_Master #(
    parameter DATA_WIDTH = 8,
    parameter CPOL = 0,
    parameter CPHA = 0
)(
    input clk, rst_n,
    input start,
    input [DATA_WIDTH-1:0] tx_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg busy,
    output sclk,
    output reg cs,
    output mosi,
    input miso
);

    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    reg current_state, next_state;
    
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH*2)-1:0] bit_counter;
    reg sclk_int;
    reg mosi_reg;
    
    wire sample_edge = (CPHA ^ sclk_int);
    wire shift_edge = ~sample_edge;
    wire transfer_complete = (bit_counter >= (DATA_WIDTH*2));
    wire [DATA_WIDTH-1:0] next_shift_reg = {shift_reg[DATA_WIDTH-2:0], miso};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            sclk_int <= CPOL;
            bit_counter <= 0;
            shift_reg <= 0;
            rx_data <= 0;
            cs <= 1'b1;
            mosi_reg <= 1'b0;
            busy <= 0;
        end else begin
            current_state <= next_state;
            busy <= (current_state != IDLE);
            
            case(current_state)
                IDLE: begin
                    sclk_int <= CPOL;
                    bit_counter <= 0;
                    if (start) begin
                        shift_reg <= tx_data;
                        cs <= 1'b0;
                    end
                end
                ACTIVE: begin
                    if (!transfer_complete) begin
                        sclk_int <= ~sclk_int;
                        
                        if (sample_edge) begin
                            shift_reg <= next_shift_reg;
                            bit_counter <= bit_counter + 1;
                        end 
                        else if (shift_edge) begin
                            mosi_reg <= shift_reg[DATA_WIDTH-1];
                            bit_counter <= bit_counter + 1;
                        end
                    end else begin
                        rx_data <= shift_reg;
                        cs <= 1'b1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: next_state = start ? ACTIVE : IDLE;
            ACTIVE: next_state = transfer_complete ? IDLE : ACTIVE;
            default: next_state = IDLE;
        endcase
    end

    assign sclk = (current_state == ACTIVE) ? sclk_int : CPOL;
    assign mosi = mosi_reg;
endmodule