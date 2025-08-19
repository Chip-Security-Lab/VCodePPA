//SystemVerilog
module pulse_div #(parameter DIV_FACTOR = 6) (
    input i_clk, i_rst_n, i_en,
    output o_pulse
);
    localparam CNT_WIDTH = $clog2(DIV_FACTOR);
    
    // Signal declarations
    reg [CNT_WIDTH-1:0] counter;
    reg pulse_r;
    reg pulse_out;
    
    wire terminal_count;
    wire [CNT_WIDTH-1:0] counter_next;
    wire [CNT_WIDTH-1:0] counter_zero = {CNT_WIDTH{1'b0}};
    wire [CNT_WIDTH-1:0] counter_incr = counter + 1'b1;
    wire pulse_next;
    
    // Pre-compute terminal count condition to reduce critical path
    assign terminal_count = (counter == DIV_FACTOR-1);
    
    // Counter next value using explicit multiplexer structure
    assign counter_next = terminal_count ? counter_zero : counter_incr;
    
    // Pulse generation logic
    assign pulse_next = pulse_r & i_en;
    
    // Counter management always block
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter <= counter_zero;
        end else if (i_en) begin
            counter <= counter_next;
        end
    end
    
    // Terminal count detection and pulse generation always block
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            pulse_r <= 1'b0;
        end else if (i_en) begin
            pulse_r <= terminal_count;
        end
    end
    
    // Output pulse registration always block
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            pulse_out <= 1'b0;
        else
            pulse_out <= pulse_next;
    end
    
    // Output assignment
    assign o_pulse = pulse_out;
endmodule