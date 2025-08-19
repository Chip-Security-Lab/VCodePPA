//SystemVerilog
module wave19_beep #(
    parameter BEEP_ON  = 50,
    parameter BEEP_OFF = 50,
    parameter WIDTH    = 8
)(
    input  wire clk,
    input  wire rst,
    output reg  beep_out
);
    reg [WIDTH-1:0] counter_reg;
    reg [WIDTH-1:0] counter_buf1;
    reg [WIDTH-1:0] counter_buf2;
    reg             beep_state_reg;
    reg             beep_state_buf;
    wire [WIDTH-1:0] period_wire;
    wire             period_reached_wire;

    assign period_wire = (beep_state_buf) ? BEEP_OFF : BEEP_ON;
    assign period_reached_wire = ~( |(counter_buf2 ^ period_wire) );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg     <= {WIDTH{1'b0}};
            counter_buf1    <= {WIDTH{1'b0}};
            counter_buf2    <= {WIDTH{1'b0}};
            beep_state_reg  <= 1'b0;
            beep_state_buf  <= 1'b0;
            beep_out        <= 1'b0;
        end else begin
            // Main logic
            if (period_reached_wire) begin
                beep_state_reg <= ~beep_state_buf;
                counter_reg    <= {WIDTH{1'b0}};
                beep_out       <= beep_state_buf;
            end else begin
                counter_reg <= counter_buf2 + 1'b1;
            end

            // Fanout buffering for 'counter'
            counter_buf1 <= counter_reg;
            counter_buf2 <= counter_buf1;

            // Fanout buffering for 'beep_state'
            beep_state_buf <= beep_state_reg;
        end
    end
endmodule