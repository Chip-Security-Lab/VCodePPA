module serial_display_codec (
    input clk, rst_n,
    input [23:0] rgb_in,
    input start_tx,
    output reg serial_data,
    output reg serial_clk,
    output reg tx_active,
    output reg tx_done
);
    reg [4:0] bit_counter;
    reg [15:0] shift_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 5'd0;
            shift_reg <= 16'd0;
            serial_data <= 1'b0;
            serial_clk <= 1'b0;
            tx_active <= 1'b0;
            tx_done <= 1'b0;
        end else begin
            if (start_tx && !tx_active && !tx_done) begin
                // RGB888 to RGB565 conversion on transmission start
                shift_reg <= {rgb_in[23:19], rgb_in[15:10], rgb_in[7:3]};
                bit_counter <= 5'd0;
                tx_active <= 1'b1;
                tx_done <= 1'b0;
            end else if (tx_active) begin
                // Generate serial clock (toggle)
                serial_clk <= ~serial_clk;
                
                // On falling edge, update data bit
                if (serial_clk) begin
                    serial_data <= shift_reg[15];
                    shift_reg <= {shift_reg[14:0], 1'b0};
                    
                    // Increment bit counter
                    if (bit_counter == 5'd15) begin
                        tx_active <= 1'b0;
                        tx_done <= 1'b1;
                    end else begin
                        bit_counter <= bit_counter + 5'd1;
                    end
                end
            end else if (tx_done && !start_tx) begin
                // Reset done signal when start_tx is deasserted
                tx_done <= 1'b0;
            end
        end
    end
endmodule