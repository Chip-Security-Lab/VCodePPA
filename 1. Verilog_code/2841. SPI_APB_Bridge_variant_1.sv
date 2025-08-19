//SystemVerilog
module SPI_APB_Bridge #(
    parameter APB_ADDR_WIDTH = 16,
    parameter APB_DATA_WIDTH = 32
)(
    input                       PCLK,
    input                       PRESETn,
    output reg                  PSEL,
    output reg                  PENABLE,
    output reg                  PWRITE,
    output reg [APB_ADDR_WIDTH-1:0] PADDR,
    output reg [APB_DATA_WIDTH-1:0] PWDATA,
    input      [APB_DATA_WIDTH-1:0] PRDATA,
    input                       PREADY,
    input                       sclk,
    input                       cs_n,
    input                       mosi,
    output reg                  miso
);

    reg [7:0]   spi_shift_reg;
    reg [2:0]   apb_state;
    reg [4:0]   bit_counter;
    reg [APB_DATA_WIDTH-1:0] data_buffer;

    localparam [2:0] IDLE = 3'd0, CMD = 3'd1, ADDR = 3'd2, DATA = 3'd3;

    always @(posedge PCLK or negedge PRESETn) begin
        if(!PRESETn) begin
            apb_state      <= IDLE;
            PSEL           <= 1'b0;
            PENABLE        <= 1'b0;
            PWRITE         <= 1'b0;
            PADDR          <= {APB_ADDR_WIDTH{1'b0}};
            PWDATA         <= {APB_DATA_WIDTH{1'b0}};
            spi_shift_reg  <= 8'h00;
            bit_counter    <= 5'd0;
            data_buffer    <= {APB_DATA_WIDTH{1'b0}};
        end else begin
            if(cs_n) begin
                spi_shift_reg <= 8'h00;
                bit_counter   <= 5'd0;
            end else if(sclk) begin
                spi_shift_reg <= {spi_shift_reg[6:0], mosi};
                if(bit_counter < 5'd31)
                    bit_counter <= bit_counter + 1'b1;
            end

            case(apb_state)
                IDLE: begin
                    PSEL    <= 1'b0;
                    PENABLE <= 1'b0;
                    if(bit_counter == 5'd7) begin
                        PWRITE    <= spi_shift_reg[7];
                        apb_state <= CMD;
                    end
                end
                CMD: begin
                    if(bit_counter == 5'd15) begin
                        PADDR     <= {spi_shift_reg, PRDATA[7:0]};
                        apb_state <= ADDR;
                    end
                end
                ADDR: begin
                    if(bit_counter == 5'd23) begin
                        PWDATA    <= {spi_shift_reg, PRDATA[23:0]};
                        PSEL      <= 1'b1;
                        apb_state <= DATA;
                    end
                end
                DATA: begin
                    if(PREADY) begin
                        PENABLE     <= 1'b1;
                        data_buffer <= PRDATA;
                        apb_state   <= IDLE;
                    end
                end
                default: apb_state <= IDLE;
            endcase
        end
    end

    reg sclk_prev;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            miso       <= 1'bz;
            sclk_prev  <= 1'b0;
        end else begin
            sclk_prev <= sclk;
            if(cs_n) begin
                miso <= 1'bz;
            end else if(sclk_prev & ~sclk) begin
                if(bit_counter >= 5'd0 && bit_counter <= 5'd7)
                    miso <= data_buffer[31 - bit_counter];
                else
                    miso <= 1'bz;
            end
        end
    end

endmodule