//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
module counter_pulse #(
    parameter CYCLE = 10
) (
    input  wire       clk,    // System clock
    input  wire       rst,    // Synchronous reset
    output reg        pulse   // Output pulse signal
);

    // Local parameters
    localparam CNT_WIDTH = $clog2(CYCLE);
    
    // Counter and control signals
    reg [CNT_WIDTH-1:0] cnt_r;           // Current counter value
    wire                terminal_count;   // Terminal count detection (combinational)
    reg                 pulse_r;          // Internal pulse register
    
    // Terminal count detection logic (combinational)
    assign terminal_count = (cnt_r == CYCLE-2);
    
    // Counter logic with integrated terminal count handling
    always @(posedge clk) begin
        if (rst) begin
            cnt_r <= {CNT_WIDTH{1'b0}};
        end else if (terminal_count) begin
            cnt_r <= {CNT_WIDTH{1'b0}};
        end else begin
            cnt_r <= cnt_r + 1'b1;
        end
    end
    
    // Pulse generation
    always @(posedge clk) begin
        if (rst) begin
            pulse <= 1'b0;
            pulse_r <= 1'b0;
        end else begin
            pulse_r <= terminal_count;
            pulse <= pulse_r;
        end
    end

endmodule