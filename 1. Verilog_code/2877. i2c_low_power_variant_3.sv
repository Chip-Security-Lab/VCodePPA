//SystemVerilog
module i2c_low_power #(
    parameter AUTO_CLKGATE = 1  // Automatic clock gating
)(
    input clk_main,
    input rst_n,
    input enable,
    inout sda,
    inout scl,
    output reg clk_gated
);
// Unique feature: Dynamic clock gating
reg clk_enable_reg;
wire gated_clk = clk_main & clk_enable_reg;

// State definition
parameter IDLE = 2'b00;
parameter ACTIVE = 2'b01;
parameter TRANSFER = 2'b10;
reg [1:0] state;

// FIFO count
reg [3:0] fifo_count;
wire [3:0] fifo_next;

// Optimized FIFO counter logic
// Use range comparison instead of complex CLA
wire fifo_increment = enable && (fifo_count < 4'hF);
wire fifo_decrement = !enable && (fifo_count > 4'h0);
assign fifo_next = fifo_increment ? (fifo_count + 4'h1) :
                   fifo_decrement ? (fifo_count - 4'h1) : fifo_count;

// Optimized clock enable condition
wire clk_needs_enable = (state != IDLE) || (|fifo_count);

always @(posedge clk_main or negedge rst_n) begin
    if (!rst_n) begin
        clk_enable_reg <= 0;
        state <= IDLE;
        fifo_count <= 4'h0;
        clk_gated <= 0;
    end else begin
        // Simplified clock gating logic
        clk_enable_reg <= clk_needs_enable;
        clk_gated <= gated_clk;
        
        // Optimized state machine
        case (state)
            IDLE:    state <= enable ? ACTIVE : IDLE;
            ACTIVE:  state <= enable ? ACTIVE : IDLE;
            default: state <= IDLE;
        endcase
        
        // Simplified FIFO count update
        fifo_count <= fifo_next;
    end
end

// Using clock gating unit (synthesis directive)
// synopsys translate_off
initial $display("Using clock gating technique");
// synopsys translate_on
endmodule