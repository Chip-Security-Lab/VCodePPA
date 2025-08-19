module eth_traffic_shaper #(
    parameter RATE_MBPS = 1000,
    parameter BURST_BYTES = 16384
)(
    input clk,
    input rst_n,
    input [7:0] data_in,
    input in_valid,
    output reg [7:0] data_out,
    output reg out_valid,
    output reg credit_overflow
);
    localparam TOKEN_INC = RATE_MBPS * 1000 / 8;  // Bytes per us
    reg [31:0] token_counter;
    reg [31:0] byte_counter;
    reg [1:0] shaper_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_counter <= BURST_BYTES;
            byte_counter <= 0;
            shaper_state <= 0;
            credit_overflow <= 0;
        end else begin
            // Update tokens every microsecond
            if (byte_counter >= 125000) begin  // 1 us @ 125MHz
                token_counter <= (token_counter + TOKEN_INC > BURST_BYTES) ? 
                                BURST_BYTES : token_counter + TOKEN_INC;
                byte_counter <= 0;
            end else begin
                byte_counter <= byte_counter + 1;
            end

            case(shaper_state)
                0: if (in_valid) shaper_state <= 1;
                1: begin
                    if (token_counter > 0) begin
                        data_out <= data_in;
                        out_valid <= 1;
                        token_counter <= token_counter - 1;
                        shaper_state <= 2;
                    end
                end
                2: begin
                    out_valid <= 0;
                    shaper_state <= 0;
                end
            endcase
            
            credit_overflow <= (token_counter == BURST_BYTES);
        end
    end
endmodule
