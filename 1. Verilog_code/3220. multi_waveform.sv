module multi_waveform(
    input clk,
    input rst_n,
    input [1:0] wave_sel,
    output reg [7:0] wave_out
);
    reg [7:0] counter;
    reg direction;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'd0;
            direction <= 1'b0;
            wave_out <= 8'd0;
        end else begin
            counter <= counter + 8'd1;
            
            case (wave_sel)
                2'b00: // Square wave
                    wave_out <= (counter < 8'd128) ? 8'd255 : 8'd0;
                2'b01: // Sawtooth wave
                    wave_out <= counter;
                2'b10: begin // Triangle wave
                    if (!direction) begin
                        if (counter == 8'd255) direction <= 1'b1;
                        wave_out <= counter;
                    end else begin
                        if (counter == 8'd0) direction <= 1'b0;
                        wave_out <= 8'd255 - counter;
                    end
                end
                2'b11: // Staircase wave
                    wave_out <= {counter[7:2], 2'b00};
            endcase
        end
    end
endmodule