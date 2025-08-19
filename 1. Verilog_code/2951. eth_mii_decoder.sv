module eth_mii_decoder (
    input wire rx_clk,
    input wire rst_n,
    input wire rx_dv,
    input wire rx_er,
    input wire [3:0] rxd,
    output reg [7:0] data_out,
    output reg data_valid,
    output reg error,
    output reg sfd_detected,
    output reg carrier_sense
);
    localparam IDLE = 2'b00, PREAMBLE = 2'b01, SFD = 2'b10, DATA = 2'b11;
    reg [1:0] state;
    reg [3:0] prev_rxd;
    
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            data_out <= 8'h00;
            data_valid <= 1'b0;
            error <= 1'b0;
            sfd_detected <= 1'b0;
            carrier_sense <= 1'b0;
            prev_rxd <= 4'h0;
        end else begin
            prev_rxd <= rxd;
            error <= rx_er;
            carrier_sense <= rx_dv;
            data_valid <= 1'b0;
            sfd_detected <= 1'b0;
            
            if (rx_dv) begin
                case (state)
                    IDLE: begin
                        if (rxd == 4'h5)
                            state <= PREAMBLE;
                    end
                    
                    PREAMBLE: begin
                        if (rxd == 4'h5)
                            state <= PREAMBLE;
                        else if (rxd == 4'hD)
                            state <= SFD;
                        else
                            state <= IDLE;
                    end
                    
                    SFD: begin
                        if (rxd == 4'h5 && prev_rxd == 4'hD) begin
                            sfd_detected <= 1'b1;
                            state <= DATA;
                            data_out[3:0] <= rxd;
                        end else
                            state <= IDLE;
                    end
                    
                    DATA: begin
                        data_out[7:4] <= rxd;
                        data_out[3:0] <= prev_rxd;
                        data_valid <= 1'b1;
                    end
                endcase
            end else begin
                state <= IDLE;
            end
        end
    end
endmodule