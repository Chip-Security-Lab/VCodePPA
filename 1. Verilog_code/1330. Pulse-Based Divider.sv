module pulse_div #(parameter DIV_FACTOR = 6) (
    input i_clk, i_rst_n, i_en,
    output o_pulse
);
    localparam CNT_WIDTH = $clog2(DIV_FACTOR);
    reg [CNT_WIDTH-1:0] counter;
    reg pulse_r;
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter <= {CNT_WIDTH{1'b0}};
            pulse_r <= 1'b0;
        end else if (i_en) begin
            if (counter == DIV_FACTOR-1) begin
                counter <= {CNT_WIDTH{1'b0}};
                pulse_r <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                pulse_r <= 1'b0;
            end
        end
    end
    
    assign o_pulse = pulse_r & i_en;
endmodule