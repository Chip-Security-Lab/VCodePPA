//SystemVerilog
module sync_rst_div #(parameter DIV=8) (
    input clk, async_rst,
    output reg clk_out
);
    reg [2:0] sync_rst_reg;
    reg [3:0] cnt;
    reg [3:0] half_div_value;
    
    // Lookup table for DIV/2 calculation
    always @(*) begin
        case(DIV)
            4'd2:  half_div_value = 4'd1;
            4'd4:  half_div_value = 4'd2;
            4'd6:  half_div_value = 4'd3;
            4'd8:  half_div_value = 4'd4;
            4'd10: half_div_value = 4'd5;
            4'd12: half_div_value = 4'd6;
            4'd14: half_div_value = 4'd7;
            4'd16: half_div_value = 4'd8;
            default: half_div_value = 4'd4; // Default for DIV=8
        endcase
    end

    always @(posedge clk, posedge async_rst) begin
        if(async_rst)
            sync_rst_reg <= 3'b111;
        else
            sync_rst_reg <= {sync_rst_reg[1:0], 1'b0};
    end

    reg [1:0] counter_state;
    always @(*) begin
        if(sync_rst_reg[2])
            counter_state = 2'b00; // Reset state
        else if(cnt == half_div_value - 1'b1)
            counter_state = 2'b01; // Terminal count state
        else
            counter_state = 2'b10; // Counting state
    end

    always @(posedge clk) begin
        case(counter_state)
            2'b00: begin // Reset state
                cnt <= 4'b0000;
                clk_out <= 1'b0;
            end
            2'b01: begin // Terminal count state
                cnt <= 4'b0000;
                clk_out <= ~clk_out;
            end
            2'b10: begin // Counting state
                cnt <= cnt + 1'b1;
            end
            default: begin
                cnt <= cnt;
                clk_out <= clk_out;
            end
        endcase
    end
endmodule