//SystemVerilog
module pulse_div #(parameter DIV_FACTOR = 6) (
    input i_clk, i_rst_n, i_en,
    output o_pulse
);
    localparam CNT_WIDTH = $clog2(DIV_FACTOR);
    
    reg [CNT_WIDTH-1:0] counter;
    reg pulse_r;
    // Pre-compute terminal count comparison value
    wire terminal_count = (counter == DIV_FACTOR-1);
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter <= {CNT_WIDTH{1'b0}};
            pulse_r <= 1'b0;
        end else if (i_en) begin
            // Counter update logic with if-else instead of ternary operator
            if (terminal_count) begin
                counter <= {CNT_WIDTH{1'b0}};
            end else begin
                counter <= counter + 1'b1;
            end
            
            // Pulse generation
            pulse_r <= terminal_count;
        end
    end
    
    // Keep output logic simple
    assign o_pulse = pulse_r & i_en;
endmodule